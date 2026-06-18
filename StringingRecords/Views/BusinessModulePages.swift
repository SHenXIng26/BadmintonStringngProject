import SwiftUI
import UniformTypeIdentifiers

struct InventoryManagementView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    @State private var activeSheet: InventorySheet?
    @State private var deleteCandidate: StringInventoryItem?
    @State private var alertMessage: String?
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var exportDocument = RecordsExportDocument()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "线材库存", subtitle: "维护每种线材的成本、数量和低库存提醒。")

                SectionCard(title: "库存列表") {
                    if businessStore.snapshot.inventoryItems.isEmpty {
                        EmptyStateView(title: "暂无线材库存", detail: "点击右上角加号新增线材，或从入库记录创建库存。", systemImage: "shippingbox")
                    } else {
                        ForEach(businessStore.snapshot.inventoryItems) { item in
                            StringInventoryItemRowView(
                                item: item,
                                moneyText: businessStore.moneyText,
                                onEdit: { activeSheet = .edit(item) },
                                onDelete: { deleteCandidate = item }
                            )
                        }
                    }
                }

                SectionCard(title: "低库存提醒", subtitle: "库存数量小于或等于提醒数量") {
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
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        prepareInventoryExport()
                    } label: {
                        Label("Export inventory JSON", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        isImporting = true
                    } label: {
                        Label("Import inventory JSON", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("库存导入导出")

                Button {
                    activeSheet = .new
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("新增线材")
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "string-inventory"
        ) { result in
            if case .failure(let error) = result {
                alertMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            importInventory(from: result)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                StringInventoryItemFormView(item: nil) { draft in
                    try businessStore.addInventoryItem(from: draft)
                }
            case .edit(let item):
                StringInventoryItemFormView(item: item) { draft in
                    try businessStore.updateInventoryItem(id: item.id, with: draft)
                }
            }
        }
        .confirmationDialog(
            "删除线材？",
            isPresented: deleteConfirmationBinding,
            presenting: deleteCandidate
        ) { item in
            Button("删除 \(item.displayName)", role: .destructive) {
                do {
                    try businessStore.deleteInventoryItem(id: item.id)
                    deleteCandidate = nil
                } catch {
                    alertMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {
                deleteCandidate = nil
            }
        } message: { item in
            Text("这会删除 \(item.displayName) 的库存资料，不会删除穿线记录。")
        }
        .alert("线材库存", isPresented: alertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding {
            deleteCandidate != nil
        } set: { isPresented in
            if !isPresented {
                deleteCandidate = nil
            }
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding {
            alertMessage != nil
        } set: { isPresented in
            if !isPresented {
                alertMessage = nil
            }
        }
    }

    private func prepareInventoryExport() {
        do {
            exportDocument = RecordsExportDocument(data: try businessStore.inventoryJSONData())
            isExporting = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func importInventory(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let canAccess = url.startAccessingSecurityScopedResource()
            defer {
                if canAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let count = try businessStore.importInventoryData(data)
            alertMessage = "Imported \(count) inventory items."
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

struct StockInRecordsView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    @State private var isPresentingForm = false
    @State private var deleteCandidate: StringStockInRecord?
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "入库记录", subtitle: "记录买线 / 入库支出，并自动增加库存数量。")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    StatisticCardView(metric: DashboardMetric(
                        title: "本月进货支出",
                        value: businessStore.moneyText(businessStore.stockInExpenseThisMonth),
                        detail: "本月入库记录总成本",
                        systemImage: "tray.and.arrow.down",
                        color: .purple
                    ))

                    StatisticCardView(metric: DashboardMetric(
                        title: "本月入库次数",
                        value: "\(businessStore.stockInRecordsThisMonth.count)",
                        detail: "当前月份记录数",
                        systemImage: "calendar",
                        color: .blue
                    ))
                }

                SectionCard(title: "本月入库记录", subtitle: "总成本 = 数量 x 每包成本") {
                    if businessStore.stockInRecordsThisMonth.isEmpty {
                        EmptyStateView(title: "暂无本月入库", detail: "点击右上角加号记录买线或补货。", systemImage: "tray.and.arrow.down")
                    } else {
                        ForEach(businessStore.stockInRecordsThisMonth) { record in
                            StockInRecordRowView(
                                record: record,
                                moneyText: businessStore.moneyText,
                                dateText: businessStore.shortDateText,
                                onDelete: { deleteCandidate = record }
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isPresentingForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("新增入库记录")
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            StockInRecordFormView(inventoryItems: businessStore.snapshot.inventoryItems) { draft in
                try businessStore.addStockInRecord(from: draft)
            }
        }
        .confirmationDialog(
            "删除入库记录？",
            isPresented: deleteConfirmationBinding,
            presenting: deleteCandidate
        ) { record in
            Button("删除 \(record.id)", role: .destructive) {
                do {
                    try businessStore.deleteStockInRecord(id: record.id)
                    deleteCandidate = nil
                } catch {
                    alertMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {
                deleteCandidate = nil
            }
        } message: { record in
            Text("删除后会尝试从 \(record.displayName) 库存里扣回 \(record.quantity) 包。")
        }
        .alert("入库记录", isPresented: alertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding {
            deleteCandidate != nil
        } set: { isPresented in
            if !isPresented {
                deleteCandidate = nil
            }
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding {
            alertMessage != nil
        } set: { isPresented in
            if !isPresented {
                alertMessage = nil
            }
        }
    }
}

struct SystemMaintenanceView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    @State private var resetAction: ResetAction?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "系统维护", subtitle: "库存和入库记录可以单独清除，穿线记录不会被一起删除。")

                SectionCard(title: "本地保存") {
                    CompactInfoRow(title: "穿线记录", value: "独立保存", detail: "仍由 RecordStore 保存到 records.json。", badge: "保留", badgeColor: .green)
                    CompactInfoRow(title: "线材库存", value: "已启用", detail: "保存到 string-business-data.json。", badge: "可用", badgeColor: .green)
                    CompactInfoRow(title: "入库记录", value: "已启用", detail: "用于计算本月进货支出。", badge: "可用", badgeColor: .green)
                }

                SectionCard(title: "数据操作") {
                    Button(role: .destructive) {
                        resetAction = .inventory
                    } label: {
                        Label("清空线材库存", systemImage: "shippingbox")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(role: .destructive) {
                        resetAction = .stockInRecords
                    } label: {
                        Label("清空入库记录", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(role: .destructive) {
                        resetAction = .allBusinessData
                    } label: {
                        Label("清空库存和入库记录", systemImage: "trash")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .confirmationDialog(
            resetAction?.title ?? "确认清除？",
            isPresented: resetConfirmationBinding,
            presenting: resetAction
        ) { action in
            Button(action.buttonTitle, role: .destructive) {
                switch action {
                case .inventory:
                    businessStore.clearInventoryItems()
                case .stockInRecords:
                    businessStore.clearStockInRecords()
                case .allBusinessData:
                    businessStore.resetBusinessData()
                }
                resetAction = nil
            }
            Button("Cancel", role: .cancel) {
                resetAction = nil
            }
        } message: { action in
            Text(action.message)
        }
    }

    private var resetConfirmationBinding: Binding<Bool> {
        Binding {
            resetAction != nil
        } set: { isPresented in
            if !isPresented {
                resetAction = nil
            }
        }
    }
}

private enum ResetAction: Identifiable {
    case inventory
    case stockInRecords
    case allBusinessData

    var id: String {
        switch self {
        case .inventory:
            return "inventory"
        case .stockInRecords:
            return "stockInRecords"
        case .allBusinessData:
            return "allBusinessData"
        }
    }

    var title: String {
        switch self {
        case .inventory:
            return "清空线材库存？"
        case .stockInRecords:
            return "清空入库记录？"
        case .allBusinessData:
            return "清空库存和入库记录？"
        }
    }

    var buttonTitle: String {
        switch self {
        case .inventory:
            return "清空线材库存"
        case .stockInRecords:
            return "清空入库记录"
        case .allBusinessData:
            return "全部清空"
        }
    }

    var message: String {
        switch self {
        case .inventory:
            return "这只会清空线材库存，不会删除穿线记录或入库记录。"
        case .stockInRecords:
            return "这只会清空入库记录，不会删除穿线记录或当前库存。"
        case .allBusinessData:
            return "这会清空线材库存和入库记录，不会删除穿线记录。"
        }
    }
}
