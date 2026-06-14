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

    var dashboardMetrics: [DashboardMetric] {
        [
            DashboardMetric(title: "今日销售额", value: moneyText(todaySalesAmount), detail: "今日已完成销售", systemImage: "dollarsign.circle", color: .green),
            DashboardMetric(title: "本月销售额", value: moneyText(monthSalesAmount), detail: "本月累计销售", systemImage: "chart.line.uptrend.xyaxis", color: .blue),
            DashboardMetric(title: "今日销售单数", value: "\(todaySalesCount)", detail: "今日销售出库单", systemImage: "doc.text", color: .orange),
            DashboardMetric(title: "本月销售单数", value: "\(monthSalesCount)", detail: "本月销售出库单", systemImage: "calendar", color: .purple),
            DashboardMetric(title: "应收合计", value: moneyText(receivableTotal), detail: "未完成收款金额", systemImage: "tray", color: .red),
            DashboardMetric(title: "应付合计", value: moneyText(payableTotal), detail: "未完成付款金额", systemImage: "creditcard", color: .pink),
            DashboardMetric(title: "低库存预警数", value: "\(lowStockItems.count)", detail: "需要关注的库存", systemImage: "exclamationmark.triangle", color: .yellow),
            DashboardMetric(title: "今日库存流水数", value: "\(todayMovementCount)", detail: "今日库存变动", systemImage: "arrow.left.arrow.right", color: .teal)
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

    func addPurchaseOrder(from draft: PurchaseOrderDraft) throws {
        if let validationMessage = draft.validationMessage {
            throw BusinessStoreError.validation(validationMessage)
        }

        let order = draft.makeOrder(id: nextPurchaseOrderID())
        snapshot.purchaseOrders.append(order)

        for item in order.items {
            applyInventoryChange(
                productCode: item.productCode,
                productName: item.productName,
                quantityChange: item.quantity,
                unitCost: item.unitPrice,
                reference: order.id,
                type: .purchaseIn,
                createMissingItem: true
            )
        }

        if order.paidAmount > 0 {
            snapshot.moneyRecords.append(
                MoneyRecord(
                    id: nextMoneyRecordID(),
                    date: order.date,
                    direction: .outgoing,
                    counterparty: order.supplierName,
                    amount: order.paidAmount,
                    relatedOrderID: order.id,
                    note: "采购付款"
                )
            )
        }

        sortBusinessData()
        persistSnapshot()
        message = "\(order.id) 已保存。"
    }

    func deletePurchaseOrder(id: String) throws {
        guard let order = snapshot.purchaseOrders.first(where: { $0.id == id }) else {
            throw BusinessStoreError.validation("Purchase order was not found.")
        }

        for item in order.items {
            try ensureInventoryCanDecrease(productCode: item.productCode, quantity: item.quantity)
        }

        for item in order.items {
            applyInventoryChange(
                productCode: item.productCode,
                productName: item.productName,
                quantityChange: -item.quantity,
                unitCost: item.unitPrice,
                reference: "删除 \(order.id)",
                type: .adjustment,
                createMissingItem: false
            )
        }

        snapshot.purchaseOrders.removeAll { $0.id == id }
        snapshot.moneyRecords.removeAll { $0.relatedOrderID == id }
        sortBusinessData()
        persistSnapshot()
        message = "\(id) 已删除。"
    }

    func addSalesOrder(from draft: SalesOrderDraft) throws {
        if let validationMessage = draft.validationMessage {
            throw BusinessStoreError.validation(validationMessage)
        }

        let order = draft.makeOrder(id: nextSalesOrderID())

        for item in order.items {
            try ensureInventoryCanDecrease(productCode: item.productCode, quantity: item.quantity)
        }

        snapshot.salesOrders.append(order)

        for item in order.items {
            applyInventoryChange(
                productCode: item.productCode,
                productName: item.productName,
                quantityChange: -item.quantity,
                unitCost: item.unitPrice,
                reference: order.id,
                type: .salesOut,
                createMissingItem: false
            )
        }

        if order.paidAmount > 0 {
            snapshot.moneyRecords.append(
                MoneyRecord(
                    id: nextMoneyRecordID(),
                    date: order.date,
                    direction: .incoming,
                    counterparty: order.customerName,
                    amount: order.paidAmount,
                    relatedOrderID: order.id,
                    note: "销售收款"
                )
            )
        }

        sortBusinessData()
        persistSnapshot()
        message = "\(order.id) 已保存。"
    }

    func deleteSalesOrder(id: String) throws {
        guard let order = snapshot.salesOrders.first(where: { $0.id == id }) else {
            throw BusinessStoreError.validation("Sales order was not found.")
        }

        for item in order.items {
            applyInventoryChange(
                productCode: item.productCode,
                productName: item.productName,
                quantityChange: item.quantity,
                unitCost: item.unitPrice,
                reference: "删除 \(order.id)",
                type: .adjustment,
                createMissingItem: true
            )
        }

        snapshot.salesOrders.removeAll { $0.id == id }
        snapshot.moneyRecords.removeAll { $0.relatedOrderID == id }
        sortBusinessData()
        persistSnapshot()
        message = "\(id) 已删除。"
    }

    func addMoneyRecord(from draft: MoneyRecordDraft) throws {
        if let validationMessage = draft.validationMessage {
            throw BusinessStoreError.validation(validationMessage)
        }

        let record = draft.makeRecord(id: nextMoneyRecordID())
        try applyPaymentChange(for: record, multiplier: 1)

        snapshot.moneyRecords.append(record)
        sortBusinessData()
        persistSnapshot()
        message = "\(record.id) 已保存。"
    }

    func deleteMoneyRecord(id: String) throws {
        guard let record = snapshot.moneyRecords.first(where: { $0.id == id }) else {
            throw BusinessStoreError.validation("Money record was not found.")
        }

        try applyPaymentChange(for: record, multiplier: -1)
        snapshot.moneyRecords.removeAll { $0.id == id }
        sortBusinessData()
        persistSnapshot()
        message = "\(id) 已删除。"
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
            reference: "初始库存"
        )
        sortInventory()
        persistSnapshot()
        message = "\(item.product.name) 已保存。"
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
                reference: "手动编辑"
            )
        }

        sortInventory()
        persistSnapshot()
        message = "\(item.product.name) 已更新。"
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
            reference: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "手动调整" : note
        )
        sortInventory()
        persistSnapshot()
        message = "库存已调整。"
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
            reference: "删除库存商品"
        )
        persistSnapshot()
        message = "\(item.product.name) 已删除。"
    }

    func resetBusinessData() {
        snapshot = InitialBusinessData.makeSnapshot()
        persistSnapshot()
        message = "业务数据已清空。"
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

    private func applyInventoryChange(
        productCode: String,
        productName: String,
        quantityChange: Int,
        unitCost: Double,
        reference: String,
        type: InventoryMovementType,
        createMissingItem: Bool
    ) {
        if let index = snapshot.inventoryItems.firstIndex(where: { $0.product.code == productCode }) {
            snapshot.inventoryItems[index].quantity += quantityChange
            appendInventoryMovement(
                type: type,
                product: snapshot.inventoryItems[index].product,
                quantityChange: quantityChange,
                reference: reference
            )
            return
        }

        guard createMissingItem else {
            return
        }

        let product = BusinessProduct(
            code: productCode,
            name: productName,
            category: .string,
            brand: "",
            salePrice: unitCost,
            costPrice: unitCost
        )
        let newItem = InventoryItem(
            product: product,
            quantity: max(quantityChange, 0),
            lowStockThreshold: 0,
            location: ""
        )

        upsertProduct(product)
        snapshot.inventoryItems.append(newItem)
        appendInventoryMovement(
            type: type,
            product: product,
            quantityChange: quantityChange,
            reference: reference
        )
    }

    private func ensureInventoryCanDecrease(productCode: String, quantity: Int) throws {
        guard let item = snapshot.inventoryItems.first(where: { $0.product.code == productCode }) else {
            throw BusinessStoreError.validation("Product \(productCode) is not in inventory.")
        }

        if item.quantity < quantity {
            throw BusinessStoreError.validation("Not enough stock for \(item.product.name).")
        }
    }

    private func applyPaymentChange(for record: MoneyRecord, multiplier: Double) throws {
        let relatedOrderID = record.relatedOrderID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !relatedOrderID.isEmpty else {
            return
        }

        switch record.direction {
        case .incoming:
            try updateSalesOrderPayment(id: relatedOrderID, amountChange: record.amount * multiplier)
        case .outgoing:
            try updatePurchaseOrderPayment(id: relatedOrderID, amountChange: record.amount * multiplier)
        }
    }

    private func updateSalesOrderPayment(id: String, amountChange: Double) throws {
        guard let index = snapshot.salesOrders.firstIndex(where: { $0.id == id }) else {
            throw BusinessStoreError.validation("Related sales order \(id) was not found.")
        }

        let order = snapshot.salesOrders[index]
        let newPaidAmount = order.paidAmount + amountChange
        try validatePaymentAmount(newPaidAmount, totalAmount: order.totalAmount)

        snapshot.salesOrders[index] = SalesOrder(
            id: order.id,
            date: order.date,
            customerName: order.customerName,
            items: order.items,
            paidAmount: newPaidAmount,
            status: paymentStatus(totalAmount: order.totalAmount, paidAmount: newPaidAmount)
        )
    }

    private func updatePurchaseOrderPayment(id: String, amountChange: Double) throws {
        guard let index = snapshot.purchaseOrders.firstIndex(where: { $0.id == id }) else {
            throw BusinessStoreError.validation("Related purchase order \(id) was not found.")
        }

        let order = snapshot.purchaseOrders[index]
        let newPaidAmount = order.paidAmount + amountChange
        try validatePaymentAmount(newPaidAmount, totalAmount: order.totalAmount)

        snapshot.purchaseOrders[index] = PurchaseOrder(
            id: order.id,
            date: order.date,
            supplierName: order.supplierName,
            items: order.items,
            paidAmount: newPaidAmount,
            status: paymentStatus(totalAmount: order.totalAmount, paidAmount: newPaidAmount)
        )
    }

    private func validatePaymentAmount(_ paidAmount: Double, totalAmount: Double) throws {
        let tolerance = 0.0001
        if paidAmount < -tolerance {
            throw BusinessStoreError.validation("Paid amount cannot be negative.")
        }

        if paidAmount - totalAmount > tolerance {
            throw BusinessStoreError.validation("Paid amount cannot be greater than order total.")
        }
    }

    private func paymentStatus(totalAmount: Double, paidAmount: Double) -> BusinessOrderStatus {
        paidAmount >= totalAmount ? .paid : .unpaid
    }

    private func nextInventoryMovementID() -> String {
        nextID(prefix: "IM", existingIDs: snapshot.inventoryMovements.map(\.id))
    }

    private func nextPurchaseOrderID() -> String {
        nextID(prefix: "PO", existingIDs: snapshot.purchaseOrders.map(\.id))
    }

    private func nextSalesOrderID() -> String {
        nextID(prefix: "SO", existingIDs: snapshot.salesOrders.map(\.id))
    }

    private func nextMoneyRecordID() -> String {
        nextID(prefix: "MR", existingIDs: snapshot.moneyRecords.map(\.id))
    }

    private func nextID(prefix: String, existingIDs: [String]) -> String {
        let nextNumber = existingIDs
            .compactMap { id in
                Int(id.replacingOccurrences(of: "\(prefix)-", with: ""))
            }
            .max()
            .map { $0 + 1 } ?? 1

        return "\(prefix)-\(String(format: "%04d", nextNumber))"
    }

    private func sortInventory() {
        snapshot.inventoryItems.sort { first, second in
            if first.isLowStock != second.isLowStock {
                return first.isLowStock && !second.isLowStock
            }

            return first.product.code < second.product.code
        }
    }

    private func sortBusinessData() {
        sortInventory()
        snapshot.purchaseOrders.sort { $0.date > $1.date }
        snapshot.salesOrders.sort { $0.date > $1.date }
        snapshot.moneyRecords.sort { $0.date > $1.date }
        snapshot.inventoryMovements.sort { $0.date > $1.date }
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

        return folderURL.appendingPathComponent("warehouse-data.json")
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
