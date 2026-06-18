import Foundation
import Combine

@MainActor
final class BusinessStore: ObservableObject {
    @Published private(set) var snapshot: BusinessSnapshot
    @Published private(set) var refreshedAt: Date
    @Published var message: String?

    private let calendar: Calendar
    private let currencyFormatter: NumberFormatter
    private let fileURL: URL

    init(
        initialSnapshot: BusinessSnapshot = InitialBusinessData.makeSnapshot(),
        fileURL: URL? = nil,
        calendar: Calendar = .current
    ) {
        let resolvedFileURL = fileURL ?? Self.defaultFileURL()

        self.snapshot = Self.loadSnapshot(from: resolvedFileURL) ?? initialSnapshot
        self.refreshedAt = Date()
        self.calendar = calendar
        self.fileURL = resolvedFileURL
        self.currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "AUD"
        currencyFormatter.maximumFractionDigits = 2

        if !FileManager.default.fileExists(atPath: resolvedFileURL.path) {
            persistSnapshot()
        }
    }

    var lowStockItems: [StringInventoryItem] {
        snapshot.inventoryItems
            .filter(\.isLowStock)
            .sorted { first, second in
                if first.quantity != second.quantity {
                    return first.quantity < second.quantity
                }

                return first.name < second.name
            }
    }

    var stockInRecordsThisMonth: [StringStockInRecord] {
        snapshot.stockInRecords
            .filter { isThisMonth($0.date) }
            .sorted { $0.date > $1.date }
    }

    var stockInExpenseThisMonth: Double {
        stockInRecordsThisMonth.reduce(0) { $0 + $1.totalCost }
    }

    var recentStockInRecords: [StringStockInRecord] {
        snapshot.stockInRecords.sorted { $0.date > $1.date }
    }

    func dashboardMetrics(for records: [StringingRecord]) -> [DashboardMetric] {
        let summary = profitSummary(for: records)

        return [
            DashboardMetric(title: "本月穿线收入", value: moneyText(summary.totalRevenue), detail: "本月已收款穿线记录", systemImage: "dollarsign.circle", color: .green),
            DashboardMetric(title: "本月线材成本", value: moneyText(summary.stringUsageCost), detail: "本月已完成穿线记录", systemImage: "scissors", color: .orange),
            DashboardMetric(title: "本月毛利润", value: moneyText(summary.grossProfit), detail: "收入 - 线材成本", systemImage: "chart.line.uptrend.xyaxis", color: .blue),
            DashboardMetric(title: "本月进货支出", value: moneyText(summary.stockInExpense), detail: "本月入库记录合计", systemImage: "tray.and.arrow.down", color: .purple),
            DashboardMetric(title: "本月盈亏", value: moneyText(summary.netCashResult), detail: "毛利润 - 进货支出", systemImage: summary.isProfitable ? "checkmark.seal" : "exclamationmark.triangle", color: summary.isProfitable ? .green : .red),
            DashboardMetric(title: "本月穿线单数", value: "\(summary.completedRecordCount)", detail: "本月记录 \(summary.monthlyRecordCount) 单", systemImage: "list.clipboard", color: .teal),
            DashboardMetric(title: "低库存提醒", value: "\(summary.lowStockCount)", detail: "低于或等于提醒数量", systemImage: "shippingbox", color: .yellow),
            DashboardMetric(title: "未匹配成本", value: "\(summary.unmatchedCostCount)", detail: "库存中找不到同名线材", systemImage: "questionmark.circle", color: .gray)
        ]
    }

    func profitSummary(for records: [StringingRecord]) -> ProfitSummary {
        let monthlyRecords = records.filter { isThisMonth($0.receivedAt) }
        let rows = monthlyRecords.map(makeProfitRecordRow)
        let totalRevenue = rows.reduce(0) { $0 + $1.revenue }
        let stringUsageCost = rows.reduce(0) { $0 + $1.stringCost }
        let grossProfit = totalRevenue - stringUsageCost
        let stockInExpense = stockInExpenseThisMonth

        return ProfitSummary(
            monthTitle: Self.monthTitleFormatter.string(from: refreshedAt),
            totalRevenue: totalRevenue,
            stringUsageCost: stringUsageCost,
            grossProfit: grossProfit,
            stockInExpense: stockInExpense,
            netCashResult: grossProfit - stockInExpense,
            monthlyRecordCount: monthlyRecords.count,
            completedRecordCount: monthlyRecords.filter { $0.workStatus == .completed }.count,
            unmatchedCostCount: rows.filter { !$0.hasMatchedCost }.count,
            lowStockCount: lowStockItems.count
        )
    }

    func profitRows(for records: [StringingRecord]) -> [ProfitRecordRow] {
        records
            .filter { isThisMonth($0.receivedAt) }
            .map(makeProfitRecordRow)
            .sorted { first, second in
                if first.date != second.date {
                    return first.date > second.date
                }

                return first.recordID > second.recordID
            }
    }

    func addInventoryItem(from draft: StringInventoryItemDraft) throws {
        if let validationMessage = draft.validationMessage {
            throw BusinessStoreError.validation(validationMessage)
        }

        guard findInventoryIndex(named: draft.name) == nil else {
            throw BusinessStoreError.validation("库存里已经有同名线材。")
        }

        snapshot.inventoryItems.append(draft.makeItem())
        sortInventory()
        persistSnapshot()
        message = "\(draft.name.businessTrimmed) 已加入库存。"
    }

    func updateInventoryItem(id: UUID, with draft: StringInventoryItemDraft) throws {
        if let validationMessage = draft.validationMessage {
            throw BusinessStoreError.validation(validationMessage)
        }

        guard let index = snapshot.inventoryItems.firstIndex(where: { $0.id == id }) else {
            throw BusinessStoreError.validation("没有找到这条库存。")
        }

        if let duplicateIndex = findInventoryIndex(named: draft.name), duplicateIndex != index {
            throw BusinessStoreError.validation("库存里已经有同名线材。")
        }

        snapshot.inventoryItems[index] = draft.makeItem(id: id)
        sortInventory()
        persistSnapshot()
        message = "\(draft.name.businessTrimmed) 已更新。"
    }

    func deleteInventoryItem(id: UUID) throws {
        guard let item = snapshot.inventoryItems.first(where: { $0.id == id }) else {
            throw BusinessStoreError.validation("没有找到这条库存。")
        }

        snapshot.inventoryItems.removeAll { $0.id == id }
        persistSnapshot()
        message = "\(item.name) 已删除。"
    }

    func addStockInRecord(from draft: StringStockInDraft) throws {
        if let validationMessage = draft.validationMessage {
            throw BusinessStoreError.validation(validationMessage)
        }

        let record = draft.makeRecord(id: nextStockInID())
        snapshot.stockInRecords.append(record)
        applyStockIn(record)
        sortBusinessData()
        persistSnapshot()
        message = "\(record.stringName) 入库 \(record.quantity) 包。"
    }

    func deleteStockInRecord(id: String) throws {
        guard let record = snapshot.stockInRecords.first(where: { $0.id == id }) else {
            throw BusinessStoreError.validation("没有找到这条入库记录。")
        }

        try reverseStockIn(record)
        snapshot.stockInRecords.removeAll { $0.id == id }
        sortBusinessData()
        persistSnapshot()
        message = "\(record.id) 已删除。"
    }

    func deductStringForCompletedRecord(_ record: StringingRecord) throws {
        guard let index = findInventoryIndex(named: record.stringName) else {
            throw BusinessStoreError.validation("库存里找不到 \(record.stringName)，不能标记为 Completed。")
        }

        guard snapshot.inventoryItems[index].quantity > 0 else {
            throw BusinessStoreError.validation("\(snapshot.inventoryItems[index].name) 库存不足，不能标记为 Completed。")
        }

        snapshot.inventoryItems[index].quantity -= 1
        sortInventory()
        persistSnapshot()
        message = "\(snapshot.inventoryItems[index].name) 已扣减 1 包。"
    }

    func restoreStringForPendingRecord(_ record: StringingRecord) throws {
        if let index = findInventoryIndex(named: record.stringName) {
            snapshot.inventoryItems[index].quantity += 1
            sortInventory()
            persistSnapshot()
            message = "\(snapshot.inventoryItems[index].name) 已恢复 1 包。"
            return
        }

        snapshot.inventoryItems.append(
            StringInventoryItem(
                id: UUID(),
                name: record.stringName,
                brand: "",
                costPerPack: 0,
                quantity: 1,
                lowStockThreshold: 0,
                note: "由穿线记录 \(record.id) 状态恢复自动创建"
            )
        )
        sortInventory()
        persistSnapshot()
        message = "\(record.stringName) 已恢复 1 包。"
    }

    func clearInventoryItems() {
        snapshot.inventoryItems = []
        persistSnapshot()
        message = "线材库存已清空。"
    }

    func clearStockInRecords() {
        snapshot.stockInRecords = []
        persistSnapshot()
        message = "入库记录已清空。"
    }

    func resetBusinessData() {
        snapshot = InitialBusinessData.makeSnapshot()
        persistSnapshot()
        message = "库存和入库记录已清空。"
    }

    func refreshDashboard() {
        refreshedAt = Date()
    }

    func moneyText(_ amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? String(format: "$%.2f", amount)
    }

    func shortDateText(_ date: Date) -> String {
        Self.shortDateFormatter.string(from: date)
    }

    private func makeProfitRecordRow(for record: StringingRecord) -> ProfitRecordRow {
        let matchedCost = costPerPack(for: record.stringName)
        let revenue = record.paymentStatus == .paid ? record.price : 0
        let usesStringCost = record.workStatus == .completed
        let stringCost = usesStringCost ? (matchedCost ?? 0) : 0

        return ProfitRecordRow(
            id: record.id,
            recordID: record.id,
            date: record.receivedAt,
            customerName: record.customerName,
            racketModel: record.racketModel,
            stringName: record.stringName,
            revenue: revenue,
            stringCost: stringCost,
            grossProfit: revenue - stringCost,
            hasMatchedCost: !usesStringCost || matchedCost != nil
        )
    }

    private func costPerPack(for stringName: String) -> Double? {
        snapshot.inventoryItems.first { item in
            item.normalizedName == stringName.normalizedInventoryKey
        }?.costPerPack
    }

    private func applyStockIn(_ record: StringStockInRecord) {
        if let index = findInventoryIndex(named: record.stringName) {
            snapshot.inventoryItems[index].quantity += record.quantity
            snapshot.inventoryItems[index].costPerPack = record.costPerPack
            if !record.brand.businessTrimmed.isEmpty {
                snapshot.inventoryItems[index].brand = record.brand.businessTrimmed
            }
            return
        }

        snapshot.inventoryItems.append(
            StringInventoryItem(
                id: UUID(),
                name: record.stringName,
                brand: record.brand,
                costPerPack: record.costPerPack,
                quantity: record.quantity,
                lowStockThreshold: 0,
                note: record.note
            )
        )
    }

    private func reverseStockIn(_ record: StringStockInRecord) throws {
        guard let index = findInventoryIndex(named: record.stringName) else {
            throw BusinessStoreError.validation("库存里找不到这条入库记录对应的线材。")
        }

        let newQuantity = snapshot.inventoryItems[index].quantity - record.quantity
        guard newQuantity >= 0 else {
            throw BusinessStoreError.validation("删除后库存会变成负数，请先调整库存数量。")
        }

        snapshot.inventoryItems[index].quantity = newQuantity
    }

    private func findInventoryIndex(named name: String) -> Int? {
        let key = name.normalizedInventoryKey
        return snapshot.inventoryItems.firstIndex { $0.normalizedName == key }
    }

    private func isThisMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: refreshedAt, toGranularity: .month)
    }

    private func nextStockInID() -> String {
        let nextNumber = snapshot.stockInRecords
            .compactMap { record in
                Int(record.id.replacingOccurrences(of: "SI-", with: ""))
            }
            .max()
            .map { $0 + 1 } ?? 1

        return "SI-\(String(format: "%04d", nextNumber))"
    }

    private func sortInventory() {
        snapshot.inventoryItems.sort { first, second in
            if first.isLowStock != second.isLowStock {
                return first.isLowStock && !second.isLowStock
            }

            return first.name < second.name
        }
    }

    private func sortBusinessData() {
        sortInventory()
        snapshot.stockInRecords.sort { $0.date > $1.date }
    }

    private func persistSnapshot() {
        do {
            let data = try Self.makeJSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            message = "库存数据保存失败。"
        }
    }

    private static func loadSnapshot(from fileURL: URL) -> BusinessSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? makeJSONDecoder().decode(BusinessSnapshot.self, from: data)
    }

    private static func makeJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func defaultFileURL() -> URL {
        let fileManager = FileManager.default
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ??
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let folderURL = baseURL.appendingPathComponent("StringingRecords", isDirectory: true)

        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)

        return folderURL.appendingPathComponent("string-business-data.json")
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter
    }()

    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月"
        return formatter
    }()
}

enum BusinessStoreError: LocalizedError {
    case validation(String)

    var errorDescription: String? {
        switch self {
        case .validation(let message):
            return message
        }
    }
}
