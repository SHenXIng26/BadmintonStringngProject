import SwiftUI

struct PurchaseManagementView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "进货管理", subtitle: "采购入库、供应商订单和应付款管理。")

                SectionCard(title: "采购订单", subtitle: "Prototype mock data") {
                    ForEach(businessStore.purchaseOrdersThisMonth) { order in
                        CompactInfoRow(
                            title: order.supplierName,
                            value: businessStore.moneyText(order.totalAmount),
                            detail: "\(order.id) · \(businessStore.shortDateText(order.date)) · \(order.items.count) items",
                            badge: order.status.rawValue,
                            badgeColor: order.payableAmount > 0 ? .orange : .green
                        )
                    }
                }

                SectionCard(title: "待付款", subtitle: "需要后续处理的采购尾款") {
                    let unpaidOrders = businessStore.snapshot.purchaseOrders.filter { $0.payableAmount > 0 }

                    if unpaidOrders.isEmpty {
                        EmptyStateView(title: "暂无应付", detail: "采购订单结清后不会显示在这里。", systemImage: "checkmark.circle")
                    } else {
                        ForEach(unpaidOrders) { order in
                            CompactInfoRow(
                                title: order.supplierName,
                                value: businessStore.moneyText(order.payableAmount),
                                detail: order.id,
                                badge: "应付",
                                badgeColor: .red
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct SalesManagementView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "销售管理", subtitle: "销售出库、拍子和球线售卖。")

                SectionCard(title: "销售订单", subtitle: "今日和本月销售出库 mock data") {
                    ForEach(businessStore.salesOrdersThisMonth) { order in
                        CompactInfoRow(
                            title: order.customerName,
                            value: businessStore.moneyText(order.totalAmount),
                            detail: "\(order.id) · \(businessStore.shortDateText(order.date)) · \(order.items.count) items",
                            badge: order.status.rawValue,
                            badgeColor: order.receivableAmount > 0 ? .orange : .green
                        )
                    }
                }

                SectionCard(title: "应收款", subtitle: "尚未完全收款的销售单") {
                    let unpaidOrders = businessStore.snapshot.salesOrders.filter { $0.receivableAmount > 0 }

                    if unpaidOrders.isEmpty {
                        EmptyStateView(title: "暂无应收", detail: "所有销售订单都已完成收款。", systemImage: "checkmark.circle")
                    } else {
                        ForEach(unpaidOrders) { order in
                            CompactInfoRow(
                                title: order.customerName,
                                value: businessStore.moneyText(order.receivableAmount),
                                detail: order.id,
                                badge: "应收",
                                badgeColor: .red
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct InventoryManagementView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "库存管理", subtitle: "库存状况、低库存预警和库存流水。")

                SectionCard(title: "库存状况") {
                    ForEach(businessStore.snapshot.inventoryItems) { item in
                        CompactInfoRow(
                            title: item.product.name,
                            value: "\(item.quantity)",
                            detail: "\(item.product.code) · \(item.location)",
                            badge: item.isLowStock ? "低库存" : "正常",
                            badgeColor: item.isLowStock ? .orange : .green
                        )
                    }
                }

                SectionCard(title: "库存流水", subtitle: "今日流水数：\(businessStore.todayMovementCount)") {
                    ForEach(businessStore.recentMovements) { movement in
                        CompactInfoRow(
                            title: movement.productName,
                            value: movement.quantityChange > 0 ? "+\(movement.quantityChange)" : "\(movement.quantityChange)",
                            detail: "\(movement.reference) · \(businessStore.shortDateText(movement.date))",
                            badge: movement.type.rawValue,
                            badgeColor: movement.quantityChange > 0 ? .green : .blue
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct CashflowManagementView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "钱流管理", subtitle: "收款登记、付款登记、应收和应付。")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    StatisticCardView(metric: DashboardMetric(title: "应收合计", value: businessStore.moneyText(businessStore.receivableTotal), detail: "Sales receivable", systemImage: "tray", color: .red))
                    StatisticCardView(metric: DashboardMetric(title: "应付合计", value: businessStore.moneyText(businessStore.payableTotal), detail: "Purchase payable", systemImage: "creditcard", color: .orange))
                }

                SectionCard(title: "收付款流水") {
                    ForEach(businessStore.recentMoneyRecords) { record in
                        CompactInfoRow(
                            title: record.counterparty,
                            value: businessStore.moneyText(record.amount),
                            detail: "\(record.relatedOrderID) · \(record.note)",
                            badge: record.direction.rawValue,
                            badgeColor: record.direction == .incoming ? .green : .orange
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct InformationCenterView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "信息中心", subtitle: "商品、供应商、客户和系统提示。")

                SectionCard(title: "商品资料") {
                    ForEach(businessStore.snapshot.products) { product in
                        CompactInfoRow(
                            title: product.name,
                            value: businessStore.moneyText(product.salePrice),
                            detail: "\(product.code) · \(product.brand)",
                            badge: product.category.rawValue,
                            badgeColor: .blue
                        )
                    }
                }

                SectionCard(title: "系统提示") {
                    ForEach(businessStore.snapshot.notices) { notice in
                        CompactInfoRow(title: notice.title, value: "", detail: notice.detail)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct SystemMaintenanceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "系统维护", subtitle: "备份、导入、运营参数和后续系统设置。")

                SectionCard(title: "维护项目") {
                    CompactInfoRow(title: "数据备份", value: "Ready", detail: "穿线记录页目前支持 JSON / CSV 导出。", badge: "可用", badgeColor: .green)
                    CompactInfoRow(title: "数据导入", value: "Ready", detail: "穿线记录页目前支持 JSON 导入。", badge: "可用", badgeColor: .green)
                    CompactInfoRow(title: "库存业务持久化", value: "Next", detail: "Dashboard 业务数据目前是 mock data，下一步可接入本地存储。", badge: "待开发", badgeColor: .orange)
                    CompactInfoRow(title: "低库存阈值设置", value: "Next", detail: "后续可在这里维护每个商品的安全库存。", badge: "待开发", badgeColor: .orange)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}
