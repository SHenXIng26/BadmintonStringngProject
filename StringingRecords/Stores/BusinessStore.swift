import Foundation
import Combine

@MainActor
final class BusinessStore: ObservableObject {
    @Published private(set) var snapshot: BusinessSnapshot
    @Published private(set) var refreshedAt: Date

    private let calendar: Calendar
    private let currencyFormatter: NumberFormatter

    init(
        snapshot: BusinessSnapshot = MockBusinessData.makeSnapshot(),
        calendar: Calendar = .current
    ) {
        self.snapshot = snapshot
        self.refreshedAt = Date()
        self.calendar = calendar
        self.currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "AUD"
        currencyFormatter.maximumFractionDigits = 2
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

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter
    }()
}
