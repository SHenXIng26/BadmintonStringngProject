import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    let onNavigate: (BusinessModule) -> Void

    private let metricColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    private let quickColumns = [
        GridItem(.adaptive(minimum: 132), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    PageHeaderView(
                        title: "经营驾驶舱",
                        subtitle: "集中查看销售、库存、钱流和经营预警。"
                    )

                    Button {
                        businessStore.refreshDashboard()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("刷新经营数据")
                }

                LazyVGrid(columns: metricColumns, spacing: 12) {
                    ForEach(businessStore.dashboardMetrics) { metric in
                        StatisticCardView(metric: metric)
                    }
                }

                SectionCard(title: "快捷入口", subtitle: "进入常用业务操作") {
                    LazyVGrid(columns: quickColumns, spacing: 12) {
                        ForEach(QuickAction.allCases) { action in
                            Button {
                                onNavigate(action.targetModule)
                            } label: {
                                QuickActionButtonLabel(action: action)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                DashboardTablesView()
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct QuickActionButtonLabel: View {
    let action: QuickAction

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: action.systemImage)
                .font(.headline)
                .frame(width: 26)

            Text(action.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .foregroundStyle(.primary)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGroupedBackground))
        )
    }
}

private struct DashboardTablesView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    var body: some View {
        VStack(spacing: 16) {
            SectionCard(title: "本月热销商品", subtitle: "按本月销量排序") {
                if businessStore.hotProductsThisMonth.isEmpty {
                    EmptyStateView(title: "暂无销量", detail: "本月产生销售后会显示热销商品。", systemImage: "chart.bar")
                } else {
                    VStack(spacing: 8) {
                        HotProductHeaderRow()

                        ForEach(businessStore.hotProductsThisMonth) { item in
                            HotProductRow(item: item)
                        }
                    }
                }
            }

            SectionCard(title: "低库存预警", subtitle: "优先补货的商品") {
                if businessStore.lowStockItems.isEmpty {
                    EmptyStateView(title: "库存健康", detail: "当前没有低库存商品。", systemImage: "checkmark.circle")
                } else {
                    ForEach(businessStore.lowStockItems) { item in
                        CompactInfoRow(
                            title: item.product.name,
                            value: "\(item.quantity)",
                            detail: "\(item.product.code) · 安全库存 \(item.lowStockThreshold)",
                            badge: "低库存",
                            badgeColor: .orange
                        )
                    }
                }
            }
        }
    }
}

private struct HotProductHeaderRow: View {
    var body: some View {
        HStack {
            Text("排名")
                .frame(width: 44, alignment: .leading)
            Text("商品")
            Spacer()
            Text("销量 / 金额")
                .frame(width: 110, alignment: .trailing)
        }
        .font(.caption)
        .fontWeight(.bold)
        .foregroundStyle(.secondary)
    }
}

private struct HotProductRow: View {
    @EnvironmentObject private var businessStore: BusinessStore

    let item: HotProduct

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(item.rank)")
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.productName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(item.productCode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(item.quantity)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(businessStore.moneyText(item.salesAmount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 110, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }
}
