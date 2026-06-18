import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var businessStore: BusinessStore
    @EnvironmentObject private var recordStore: RecordStore

    let onNavigate: (BusinessModule) -> Void

    private let metricColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    private let quickColumns = [
        GridItem(.adaptive(minimum: 132), spacing: 12)
    ]

    private var summary: ProfitSummary {
        businessStore.profitSummary(for: recordStore.records)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    PageHeaderView(
                        title: "经营概览",
                        subtitle: "\(summary.monthTitle) · 穿线收入、线材成本、入库支出和盈亏。"
                    )

                    Button {
                        businessStore.refreshDashboard()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("刷新经营数据")
                }

                NetResultBanner(summary: summary, moneyText: businessStore.moneyText)

                LazyVGrid(columns: metricColumns, spacing: 12) {
                    ForEach(businessStore.dashboardMetrics(for: recordStore.records)) { metric in
                        StatisticCardView(metric: metric)
                    }
                }

                SectionCard(title: "快捷入口", subtitle: "进入常用操作") {
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

                ProfitBreakdownView()
                LowStockDashboardView()
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct NetResultBanner: View {
    let summary: ProfitSummary
    let moneyText: (Double) -> String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: summary.isProfitable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(summary.isProfitable ? .green : .red)

            VStack(alignment: .leading, spacing: 4) {
                Text("本月盈亏")
                    .font(.headline)

                Text("\(summary.isProfitable ? "盈利" : "亏损")：\(moneyText(summary.netCashResult))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((summary.isProfitable ? Color.green : Color.red).opacity(0.12))
        )
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

private struct ProfitBreakdownView: View {
    @EnvironmentObject private var businessStore: BusinessStore
    @EnvironmentObject private var recordStore: RecordStore

    private var rows: [ProfitRecordRow] {
        businessStore.profitRows(for: recordStore.records)
    }

    var body: some View {
        SectionCard(title: "本月穿线利润明细", subtitle: "线材成本按 stringName 匹配线材库存名称") {
            if rows.isEmpty {
                EmptyStateView(title: "暂无本月穿线记录", detail: "穿线记录工具里添加本月记录后，这里会自动计算收入和线材成本。", systemImage: "list.clipboard")
            } else {
                VStack(spacing: 8) {
                    ForEach(rows) { row in
                        ProfitRecordRowView(row: row)
                    }
                }
            }
        }
    }
}

private struct ProfitRecordRowView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    let row: ProfitRecordRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.customerName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(row.recordID) · \(businessStore.shortDateText(row.date)) · \(row.stringName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !row.hasMatchedCost {
                    Text("未匹配线材成本，已按 0 计算")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 4) {
                Text(businessStore.moneyText(row.grossProfit))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(row.grossProfit >= 0 ? Color.primary : Color.red)

                Text("收入 \(businessStore.moneyText(row.revenue))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("线材 \(businessStore.moneyText(row.stringCost))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct LowStockDashboardView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    var body: some View {
        SectionCard(title: "低库存提醒", subtitle: "低于或等于提醒数量的线材") {
            if businessStore.lowStockItems.isEmpty {
                EmptyStateView(title: "库存状态正常", detail: "当前没有触发低库存提醒的线材。", systemImage: "checkmark.circle")
            } else {
                ForEach(businessStore.lowStockItems) { item in
                    CompactInfoRow(
                        title: item.name,
                        value: "\(item.quantity) 包",
                        detail: "\(item.brand.isEmpty ? "未设置品牌" : item.brand) · 提醒 \(item.lowStockThreshold) 包",
                        badge: "低库存",
                        badgeColor: .orange
                    )
                }
            }
        }
    }
}
