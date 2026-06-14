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
        seedSnapshot: BusinessSnapshot = MockBusinessData.makeSnapshot(),
        fileURL: URL? = nil,
        calendar: Calendar = .current
    ) {
        let resolvedFileURL = fileURL ?? Self.defaultFileURL()

        self.snapshot = Self.loadSnapshot(from: resolvedFileURL) ?? seedSnapshot
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

    var dashboardMetrics: [DashboardMetric] {
        [
            DashboardMetric(title: "今日销售额", value: moneyText(todaySalesAmount), detail: "Today sales", systemImage: "dollarsign.circle", color: .green),
            DashboardMetric(title: "本月销售额", value: moneyText(monthSalesAmount), detail: "This month", systemImage: "chart.line.uptrend.xyaxis", color: .blue),
            DashboardMetric(title: "今日销售单数", value: "\(todaySalesCount)", detail: "Orders today", systemImage: "doc.text", color: .orange),
            DashboardMetric(title: "本月销售单数", value: "\(monthSalesCount)", detail: "Orders this month", systemImage: "calendar", color: .purple),
            DashboardMetric(title: "应收合计", value: moneyText(receivableTotal), detail: "Uncollected", systemImage: "tray", color: .red),
            DashboardMetric(title: "应付合计", value: moneyText(payableTotal), detail: "Unpaid purchase", systemImage: "creditcard", color: .pink),
            DashboardMetric(title: "低库存预警数", value: "\(lowStockItems.count)", detail: "Need reorder", systemImage: "exclamationmark.triangle", color: .yellow),
            DashboardMetric(title: "今日库存流水数", value: "\(todayMovementCount)", detail: "Stock movements", systemImage: "arrow.left.arrow.right", color: .teal)
        ]
    }

    var todaySalesAmount: Double {
        salesOrdersToday.reduce(0) { $0 + $1.totalAmount }
    }

    var monthSalesAmount: Double {
        salesOrdersThisMonth.reduce(0) { $0 + $1.totalAmount }
    }

    var todaySalesCount: Int {
        salesOrdersToday.count
    }

    var monthSalesCount: Int {
        salesOrdersThisMonth.count
    }

    var receivableTotal: Double {
        snapshot.salesOrders.reduce(0) { $0 + $1.receivableAmount }
    }

    var payableTotal: Double {
        snapshot.purchaseOrders.reduce(0) { $0 + $1.payableAmount }
    }

    var lowStockItems: [InventoryItem] {
        snapshot.inventoryItems.filter(\.isLowStock)
    }

    var todayMovementCount: Int {
        snapshot.inventoryMovements.filter { isToday($0.date) }.count
    }

    var hotProductsThisMonth: [HotProduct] {
        let monthlyOrders = salesOrdersThisMonth
        var grouped: [String: (name: String, quantity: Int, amount: Double)] = [:]

        for order in monthlyOrders {
            for item in order.items {
                let current = grouped[item.productCode] ?? (item.productName, 0, 0)
                grouped[item.productCode] = (
                    item.productName,
                    current.quantity + item.quantity,
                    current.amount + item.lineTotal
                )
            }
        }

        return grouped
            .sorted { first, second in
                if first.value.quantity != second.value.quantity {
                    return first.value.quantity > second.value.quantity
                }

                return first.value.amount > second.value.amount
            }
            .prefix(5)
            .enumerated()
            .map { index, entry in
                HotProduct(
                    rank: index + 1,
                    productCode: entry.key,
                    productName: entry.value.name,
                    quantity: entry.value.quantity,
                    salesAmount: entry.value.amount
                )
            }
    }

    var salesOrdersToday: [SalesOrder] {
        snapshot.salesOrders.filter { isToday($0.date) }
    }

    var salesOrdersThisMonth: [SalesOrder] {
        snapshot.salesOrders.filter { isThisMonth($0.date) }
    }

    var purchaseOrdersThisMonth: [PurchaseOrder] {
        snapshot.purchaseOrders.filter { isThisMonth($0.date) }
    }

    var recentMovements: [InventoryMovement] {
        snapshot.inventoryMovements.sorted { $0.date > $1.date }
    }

    var recentMoneyRecords: [MoneyRecord] {
        snapshot.moneyRecords.sorted { $0.date > $1.date }
    }

    func canAddInventoryItem(code: String) -> Bool {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return !snapshot.inventoryItems.contains { $0.product.code == normalizedCode }
    }

    func addInventoryItem(from draft: InventoryItemDraft) throws {
        if let validationMessage = draft.validationMessage {
            throw BusinessStoreError.validation(validationMessage)
        }

        guard canAddInventoryItem(code: draft.code) else {
            throw BusinessStoreError.validation("A product with this code already exists.")
        }

        let item = draft.makeInventoryItem()
        upsertProduct(item.product)
        snapshot.inventoryItems.append(item)
        appendInventoryMovement(
            type: .adjustment,
            product: item.product,
            quantityChange: item.quantity,
            reference: "Initial stock"
        )
        sortInventory()
        persistSnapshot()
        message = "\(item.product.name) saved."
    }

    func updateInventoryItem(productCode: String, with draft: InventoryItemDraft) throws {
        if let validationMessage = draft.validationMessage {
            throw BusinessStoreError.validation(validationMessage)
        }

        guard let index = snapshot.inventoryItems.firstIndex(where: { $0.product.code == productCode }) else {
            throw BusinessStoreError.validation("Inventory item was not found.")
        }

        var fixedDraft = draft
        fixedDraft.code = productCode

        let previousQuantity = snapshot.inventoryItems[index].quantity
        let item = fixedDraft.makeInventoryItem()
        upsertProduct(item.product)
        snapshot.inventoryItems[index] = item

        let quantityChange = item.quantity - previousQuantity
        if quantityChange != 0 {
            appendInventoryMovement(
                type: .adjustment,
                product: item.product,
                quantityChange: quantityChange,
                reference: "Manual edit"
            )
        }

        sortInventory()
        persistSnapshot()
        message = "\(item.product.name) updated."
    }

    func adjustInventory(productCode: String, quantityChange: Int, note: String) throws {
        guard quantityChange != 0 else {
            throw BusinessStoreError.validation("Quantity change cannot be zero.")
        }

        guard let index = snapshot.inventoryItems.firstIndex(where: { $0.product.code == productCode }) else {
            throw BusinessStoreError.validation("Inventory item was not found.")
        }

        let newQuantity = snapshot.inventoryItems[index].quantity + quantityChange
        guard newQuantity >= 0 else {
            throw BusinessStoreError.validation("Stock cannot be negative.")
        }

        snapshot.inventoryItems[index].quantity = newQuantity
        appendInventoryMovement(
            type: .adjustment,
            product: snapshot.inventoryItems[index].product,
            quantityChange: quantityChange,
            reference: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Manual adjustment" : note
        )
        sortInventory()
        persistSnapshot()
        message = "Stock adjusted."
    }

    func deleteInventoryItem(productCode: String) throws {
        guard let item = snapshot.inventoryItems.first(where: { $0.product.code == productCode }) else {
            throw BusinessStoreError.validation("Inventory item was not found.")
        }

        snapshot.inventoryItems.removeAll { $0.product.code == productCode }
        snapshot.products.removeAll { $0.code == productCode }
        appendInventoryMovement(
            type: .adjustment,
            product: item.product,
            quantityChange: -item.quantity,
            reference: "Deleted item"
        )
        persistSnapshot()
        message = "\(item.product.name) deleted."
    }

    func resetBusinessData() {
        snapshot = MockBusinessData.makeSnapshot(referenceDate: refreshedAt)
        persistSnapshot()
        message = "Business data reset."
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

    private func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: refreshedAt)
    }

    private func isThisMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: refreshedAt, toGranularity: .month)
    }

    private func upsertProduct(_ product: BusinessProduct) {
        if let index = snapshot.products.firstIndex(where: { $0.code == product.code }) {
            snapshot.products[index] = product
        } else {
            snapshot.products.append(product)
        }

        snapshot.products.sort { $0.code < $1.code }
    }

    private func appendInventoryMovement(
        type: InventoryMovementType,
        product: BusinessProduct,
        quantityChange: Int,
        reference: String
    ) {
        let movement = InventoryMovement(
            id: nextInventoryMovementID(),
            date: Date(),
            type: type,
            productCode: product.code,
            productName: product.name,
            quantityChange: quantityChange,
            reference: reference
        )

        snapshot.inventoryMovements.append(movement)
        snapshot.inventoryMovements.sort { $0.date > $1.date }
    }

    private func nextInventoryMovementID() -> String {
        let number = snapshot.inventoryMovements.count + 1
        return "IM-\(String(format: "%04d", number))"
    }

    private func sortInventory() {
        snapshot.inventoryItems.sort { first, second in
            if first.isLowStock != second.isLowStock {
                return first.isLowStock && !second.isLowStock
            }

            return first.product.code < second.product.code
        }
    }

    private func persistSnapshot() {
        do {
            let data = try Self.makeJSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            message = "Business data could not be saved."
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

        return folderURL.appendingPathComponent("business-data.json")
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
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
