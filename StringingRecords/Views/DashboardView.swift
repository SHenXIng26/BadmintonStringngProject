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

                NavigationLink(value: DashboardDetailRoute.netResult) {
                    NetResultBanner(summary: summary, moneyText: businessStore.moneyText)
                }
                .buttonStyle(.plain)

                LazyVGrid(columns: metricColumns, spacing: 12) {
                    ForEach(businessStore.dashboardMetrics(for: recordStore.records)) { metric in
                        if let destination = metric.destination {
                            NavigationLink(value: destination) {
                                StatisticCardView(metric: metric, showsDisclosureIndicator: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            StatisticCardView(metric: metric)
                        }
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

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                        title: item.displayName,
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

struct DashboardDetailView: View {
    @EnvironmentObject private var businessStore: BusinessStore
    @EnvironmentObject private var recordStore: RecordStore

    let route: DashboardDetailRoute

    private var summary: ProfitSummary {
        businessStore.profitSummary(for: recordStore.records)
    }

    private var profitRows: [ProfitRecordRow] {
        businessStore.profitRows(for: recordStore.records)
    }

    private var completedRecordIDs: Set<String> {
        Set(businessStore.completedRecordsThisMonth(from: recordStore.records).map(\.id))
    }

    private var completedProfitRows: [ProfitRecordRow] {
        profitRows.filter { completedRecordIDs.contains($0.recordID) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: route.title, subtitle: route.subtitle)

                detailContent
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch route {
        case .paidIncome:
            paidIncomeDetail
        case .stringCost:
            stringCostDetail
        case .grossProfit:
            grossProfitDetail
        case .stockInExpense:
            stockInExpenseDetail
        case .netResult:
            netResultDetail
        case .completedRecords:
            completedRecordsDetail
        case .lowStock:
            lowStockDetail
        case .unmatchedCost:
            unmatchedCostDetail
        }
    }

    private var paidIncomeDetail: some View {
        let records = businessStore.paidRecordsThisMonth(from: recordStore.records)

        return SectionCard(title: "已付款穿线记录", subtitle: "合计 \(businessStore.moneyText(summary.totalRevenue))") {
            if records.isEmpty {
                EmptyStateView(title: "暂无已付款记录", detail: "本月 Payment Status 为 Paid 的记录会显示在这里。", systemImage: "dollarsign.circle")
            } else {
                ForEach(records) { record in
                    StringingRecordDetailRow(record: record, trailingValue: businessStore.moneyText(record.price))
                }
            }
        }
    }

    private var stringCostDetail: some View {
        SectionCard(title: "已完成穿线成本", subtitle: "合计 \(businessStore.moneyText(summary.stringUsageCost))") {
            if completedProfitRows.isEmpty {
                EmptyStateView(title: "暂无已完成记录", detail: "本月 Work Status 为 Completed 的记录会显示在这里。", systemImage: "scissors")
            } else {
                ForEach(completedProfitRows) { row in
                    ProfitCostDetailRow(row: row, moneyText: businessStore.moneyText)
                }
            }
        }
    }

    private var grossProfitDetail: some View {
        SectionCard(title: "本月单笔毛利润", subtitle: "收入只计 Paid，线材成本只计 Completed") {
            if profitRows.isEmpty {
                EmptyStateView(title: "暂无本月记录", detail: "本月穿线记录会显示在这里。", systemImage: "chart.line.uptrend.xyaxis")
            } else {
                ForEach(profitRows) { row in
                    GrossProfitDetailRow(row: row, moneyText: businessStore.moneyText)
                }
            }
        }
    }

    private var stockInExpenseDetail: some View {
        SectionCard(title: "本月入库记录", subtitle: "合计 \(businessStore.moneyText(summary.stockInExpense))") {
            if businessStore.stockInRecordsThisMonth.isEmpty {
                EmptyStateView(title: "暂无本月入库", detail: "本月入库记录会显示在这里。", systemImage: "tray.and.arrow.down")
            } else {
                ForEach(businessStore.stockInRecordsThisMonth) { record in
                    StockInExpenseDetailRow(record: record, businessStore: businessStore)
                }
            }
        }
    }

    private var netResultDetail: some View {
        SectionCard(title: "本月盈亏汇总") {
            CompactInfoRow(title: "本月穿线收入", value: businessStore.moneyText(summary.totalRevenue), detail: "Payment Status = Paid")
            CompactInfoRow(title: "本月线材使用成本", value: businessStore.moneyText(summary.stringUsageCost), detail: "Work Status = Completed")
            CompactInfoRow(title: "本月毛利润", value: businessStore.moneyText(summary.grossProfit), detail: "穿线收入 - 线材成本")
            CompactInfoRow(title: "本月进货支出", value: businessStore.moneyText(summary.stockInExpense), detail: "本月入库总成本")
            CompactInfoRow(
                title: "最终盈亏",
                value: businessStore.moneyText(summary.netCashResult),
                detail: "毛利润 - 进货支出",
                badge: summary.isProfitable ? "盈利" : "亏损",
                badgeColor: summary.isProfitable ? .green : .red
            )
        }
    }

    private var completedRecordsDetail: some View {
        let records = businessStore.completedRecordsThisMonth(from: recordStore.records)

        return SectionCard(title: "本月已完成穿线记录", subtitle: "共 \(records.count) 单") {
            if records.isEmpty {
                EmptyStateView(title: "暂无已完成记录", detail: "本月 Completed 记录会显示在这里。", systemImage: "list.clipboard")
            } else {
                ForEach(records) { record in
                    StringingRecordDetailRow(record: record, trailingValue: record.workStatus.label)
                }
            }
        }
    }

    private var lowStockDetail: some View {
        SectionCard(title: "低库存线材", subtitle: "数量小于或等于提醒数量") {
            if businessStore.lowStockItems.isEmpty {
                EmptyStateView(title: "库存状态正常", detail: "当前没有低库存线材。", systemImage: "checkmark.circle")
            } else {
                ForEach(businessStore.lowStockItems) { item in
                    CompactInfoRow(
                        title: item.displayName,
                        value: "\(item.quantity) 包",
                        detail: "\(item.brand.isEmpty ? "未设置品牌" : item.brand) · 成本 \(businessStore.moneyText(item.costPerPack)) · 提醒 \(item.lowStockThreshold) 包",
                        badge: "低库存",
                        badgeColor: .orange
                    )
                }
            }
        }
    }

    private var unmatchedCostDetail: some View {
        let rows = completedProfitRows.filter { !$0.hasMatchedCost }

        return SectionCard(title: "未匹配线材成本", subtitle: "库存中找不到准确名称和颜色") {
            if rows.isEmpty {
                EmptyStateView(title: "全部已匹配", detail: "本月已完成记录都能匹配线材库存成本。", systemImage: "checkmark.circle")
            } else {
                ForEach(rows) { row in
                    ProfitCostDetailRow(row: row, moneyText: businessStore.moneyText)
                }
            }
        }
    }
}

private struct StringingRecordDetailRow: View {
    let record: StringingRecord
    let trailingValue: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.customerName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(record.racketModel) · \(record.stringName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(record.id) · \(record.receivedDateText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            Text(trailingValue)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.vertical, 8)
    }
}

private struct ProfitCostDetailRow: View {
    let row: ProfitRecordRow
    let moneyText: (Double) -> String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.stringName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(row.recordID) · \(row.customerName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !row.hasMatchedCost {
                    Text("未匹配库存成本")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }

            Spacer(minLength: 10)

            Text(moneyText(row.stringCost))
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.vertical, 8)
    }
}

private struct GrossProfitDetailRow: View {
    let row: ProfitRecordRow
    let moneyText: (Double) -> String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.customerName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(row.recordID) · \(row.stringName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !row.hasMatchedCost {
                    Text("未匹配库存成本")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 3) {
                Text(moneyText(row.grossProfit))
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text("收入 \(moneyText(row.revenue))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("成本 \(moneyText(row.stringCost))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct StockInExpenseDetailRow: View {
    let record: StringStockInRecord
    let businessStore: BusinessStore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(businessStore.shortDateText(record.date)) · \(record.quantity) 包 x \(businessStore.moneyText(record.costPerPack))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            Text(businessStore.moneyText(record.totalCost))
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.vertical, 8)
    }
}

private extension DashboardDetailRoute {
    var title: String {
        switch self {
        case .paidIncome:
            return "本月穿线收入"
        case .stringCost:
            return "本月线材使用成本"
        case .grossProfit:
            return "本月毛利润"
        case .stockInExpense:
            return "本月进货支出"
        case .netResult:
            return "本月盈亏"
        case .completedRecords:
            return "本月穿线单数"
        case .lowStock:
            return "低库存提醒"
        case .unmatchedCost:
            return "未匹配成本"
        }
    }

    var subtitle: String {
        switch self {
        case .paidIncome:
            return "只显示本月 Payment Status 为 Paid 的记录。"
        case .stringCost:
            return "只显示本月 Work Status 为 Completed 的线材成本。"
        case .grossProfit:
            return "查看每一单的收入、线材成本和毛利润。"
        case .stockInExpense:
            return "查看本月线材入库数量、颜色和成本。"
        case .netResult:
            return "汇总本月收入、成本、进货支出和最终盈亏。"
        case .completedRecords:
            return "显示本月所有 Completed 穿线记录。"
        case .lowStock:
            return "只显示已经触发低库存提醒的线材。"
        case .unmatchedCost:
            return "检查无法匹配到具体库存线材的已完成记录。"
        }
    }
}
