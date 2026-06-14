import SwiftUI

struct PurchaseManagementView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    @State private var isPresentingForm = false
    @State private var deleteCandidate: PurchaseOrder?
    @State private var alertMessage: String?

    private var unpaidOrders: [PurchaseOrder] {
        businessStore.snapshot.purchaseOrders.filter { $0.payableAmount > 0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "进货管理", subtitle: "登记采购入库、供应商订单和应付款。")

                SectionCard(title: "采购订单", subtitle: "保存后会自动增加库存") {
                    if businessStore.snapshot.purchaseOrders.isEmpty {
                        EmptyStateView(title: "暂无采购订单", detail: "点击右上角加号登记第一笔采购入库。", systemImage: "tray.and.arrow.down")
                    } else {
                        ForEach(businessStore.snapshot.purchaseOrders) { order in
                            PurchaseOrderRowView(
                                order: order,
                                moneyText: businessStore.moneyText,
                                dateText: businessStore.shortDateText,
                                onDelete: { deleteCandidate = order }
                            )
                        }
                    }
                }

                SectionCard(title: "待付款", subtitle: "采购订单未结清金额") {
                    if unpaidOrders.isEmpty {
                        EmptyStateView(title: "暂无应付", detail: "采购订单结清后不会显示在这里。", systemImage: "checkmark.circle")
                    } else {
                        ForEach(unpaidOrders) { order in
                            CompactInfoRow(
                                title: order.supplierName,
                                value: businessStore.moneyText(order.payableAmount),
                                detail: "\(order.id) · \(businessStore.shortDateText(order.date))",
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isPresentingForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("新增采购订单")
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            PurchaseOrderFormView(products: businessStore.snapshot.products) { draft in
                try businessStore.addPurchaseOrder(from: draft)
            }
        }
        .confirmationDialog(
            "删除采购订单？",
            isPresented: deleteConfirmationBinding,
            presenting: deleteCandidate
        ) { order in
            Button("删除 \(order.id)", role: .destructive) {
                do {
                    try businessStore.deletePurchaseOrder(id: order.id)
                    deleteCandidate = nil
                } catch {
                    alertMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {
                deleteCandidate = nil
            }
        } message: { order in
            Text("删除后会回退这笔采购造成的库存入库，并移除关联付款流水。")
        }
        .alert("进货管理", isPresented: alertBinding) {
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

struct SalesManagementView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    @State private var isPresentingForm = false
    @State private var deleteCandidate: SalesOrder?
    @State private var alertMessage: String?

    private var receivableOrders: [SalesOrder] {
        businessStore.snapshot.salesOrders.filter { $0.receivableAmount > 0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "销售管理", subtitle: "登记销售出库、穿线服务、球线和球拍售卖。")

                SectionCard(title: "销售订单", subtitle: "保存后会自动扣减库存") {
                    if businessStore.snapshot.salesOrders.isEmpty {
                        EmptyStateView(title: "暂无销售订单", detail: "点击右上角加号登记第一笔销售出库。", systemImage: "cart")
                    } else {
                        ForEach(businessStore.snapshot.salesOrders) { order in
                            SalesOrderRowView(
                                order: order,
                                moneyText: businessStore.moneyText,
                                dateText: businessStore.shortDateText,
                                onDelete: { deleteCandidate = order }
                            )
                        }
                    }
                }

                SectionCard(title: "应收款", subtitle: "销售订单未完成收款金额") {
                    if receivableOrders.isEmpty {
                        EmptyStateView(title: "暂无应收", detail: "所有销售订单都已完成收款。", systemImage: "checkmark.circle")
                    } else {
                        ForEach(receivableOrders) { order in
                            CompactInfoRow(
                                title: order.customerName,
                                value: businessStore.moneyText(order.receivableAmount),
                                detail: "\(order.id) · \(businessStore.shortDateText(order.date))",
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isPresentingForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("新增销售订单")
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            SalesOrderFormView(inventoryItems: businessStore.snapshot.inventoryItems) { draft in
                try businessStore.addSalesOrder(from: draft)
            }
        }
        .confirmationDialog(
            "删除销售订单？",
            isPresented: deleteConfirmationBinding,
            presenting: deleteCandidate
        ) { order in
            Button("删除 \(order.id)", role: .destructive) {
                do {
                    try businessStore.deleteSalesOrder(id: order.id)
                    deleteCandidate = nil
                } catch {
                    alertMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {
                deleteCandidate = nil
            }
        } message: { order in
            Text("删除后会把这笔销售扣减的库存加回，并移除关联收款流水。")
        }
        .alert("销售管理", isPresented: alertBinding) {
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

struct InventoryManagementView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    @State private var activeSheet: InventorySheet?
    @State private var deleteCandidate: InventoryItem?
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "库存管理", subtitle: "维护库存数量、低库存预警和库存流水。")

                SectionCard(title: "库存状况") {
                    if businessStore.snapshot.inventoryItems.isEmpty {
                        EmptyStateView(title: "暂无库存", detail: "点击右上角加号新增第一个库存商品。", systemImage: "shippingbox")
                    } else {
                        ForEach(businessStore.snapshot.inventoryItems) { item in
                            InventoryItemRowView(
                                item: item,
                                moneyText: businessStore.moneyText,
                                onEdit: { activeSheet = .edit(item) },
                                onAdjust: { activeSheet = .adjust(item) },
                                onDelete: { deleteCandidate = item }
                            )
                        }
                    }
                }

                SectionCard(title: "低库存预警", subtitle: "低于或等于安全库存的商品") {
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

                SectionCard(title: "库存流水", subtitle: "今日流水数：\(businessStore.todayMovementCount)") {
                    if businessStore.recentMovements.isEmpty {
                        EmptyStateView(title: "暂无流水", detail: "新增、编辑或调整库存后会生成流水。", systemImage: "arrow.left.arrow.right")
                    } else {
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
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    activeSheet = .new
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("新增库存商品")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                InventoryItemFormView(item: nil) { draft in
                    try businessStore.addInventoryItem(from: draft)
                }
            case .edit(let item):
                InventoryItemFormView(item: item) { draft in
                    try businessStore.updateInventoryItem(productCode: item.product.code, with: draft)
                }
            case .adjust(let item):
                InventoryAdjustmentView(item: item) { quantityChange, note in
                    try businessStore.adjustInventory(
                        productCode: item.product.code,
                        quantityChange: quantityChange,
                        note: note
                    )
                }
            }
        }
        .confirmationDialog(
            "Delete inventory item?",
            isPresented: deleteConfirmationBinding,
            presenting: deleteCandidate
        ) { item in
            Button("Delete \(item.product.name)", role: .destructive) {
                do {
                    try businessStore.deleteInventoryItem(productCode: item.product.code)
                    deleteCandidate = nil
                } catch {
                    alertMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {
                deleteCandidate = nil
            }
        } message: { item in
            Text("This removes \(item.product.name) from inventory and saves the change.")
        }
        .alert("Inventory", isPresented: alertBinding) {
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

struct CashflowManagementView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    @State private var isPresentingForm = false
    @State private var deleteCandidate: MoneyRecord?
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "钱流管理", subtitle: "登记收款、付款，并跟踪应收和应付。")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    StatisticCardView(metric: DashboardMetric(title: "应收合计", value: businessStore.moneyText(businessStore.receivableTotal), detail: "未完成收款金额", systemImage: "tray", color: .red))
                    StatisticCardView(metric: DashboardMetric(title: "应付合计", value: businessStore.moneyText(businessStore.payableTotal), detail: "未完成付款金额", systemImage: "creditcard", color: .orange))
                }

                SectionCard(title: "收付款流水", subtitle: "关联订单号后会同步更新应收或应付") {
                    if businessStore.recentMoneyRecords.isEmpty {
                        EmptyStateView(title: "暂无钱流记录", detail: "点击右上角加号登记收款或付款。", systemImage: "banknote")
                    } else {
                        ForEach(businessStore.recentMoneyRecords) { record in
                            MoneyRecordRowView(
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
                .accessibilityLabel("新增收付款记录")
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            MoneyRecordFormView { draft in
                try businessStore.addMoneyRecord(from: draft)
            }
        }
        .confirmationDialog(
            "删除收付款记录？",
            isPresented: deleteConfirmationBinding,
            presenting: deleteCandidate
        ) { record in
            Button("删除 \(record.id)", role: .destructive) {
                do {
                    try businessStore.deleteMoneyRecord(id: record.id)
                    deleteCandidate = nil
                } catch {
                    alertMessage = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {
                deleteCandidate = nil
            }
        } message: { record in
            Text("如果这笔流水关联了订单，删除后会同步回退订单的已收或已付金额。")
        }
        .alert("钱流管理", isPresented: alertBinding) {
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

struct InformationCenterView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "信息中心", subtitle: "查看已保存的商品、供应商、客户和系统提示。")

                SectionCard(title: "商品资料", subtitle: "商品资料来自库存、采购和销售记录") {
                    if businessStore.snapshot.products.isEmpty {
                        EmptyStateView(title: "暂无商品资料", detail: "新增库存或采购入库后会保存商品资料。", systemImage: "shippingbox")
                    } else {
                        ForEach(businessStore.snapshot.products) { product in
                            CompactInfoRow(
                                title: product.name,
                                value: businessStore.moneyText(product.salePrice),
                                detail: "\(product.code) · \(product.brand.isEmpty ? "未设置品牌" : product.brand)",
                                badge: product.category.rawValue,
                                badgeColor: .blue
                            )
                        }
                    }
                }

                SectionCard(title: "系统提示") {
                    if businessStore.snapshot.notices.isEmpty {
                        EmptyStateView(title: "暂无系统提示", detail: "需要提醒的经营事项会显示在这里。", systemImage: "info.circle")
                    } else {
                        ForEach(businessStore.snapshot.notices) { notice in
                            CompactInfoRow(title: notice.title, value: "", detail: notice.detail)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct SystemMaintenanceView: View {
    @EnvironmentObject private var businessStore: BusinessStore

    @State private var isConfirmingReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeaderView(title: "系统维护", subtitle: "查看本地保存状态和清空业务数据。")

                SectionCard(title: "本地保存") {
                    CompactInfoRow(title: "穿线记录", value: "已启用", detail: "穿线记录支持本地保存、JSON 导入导出和 CSV 导出。", badge: "可用", badgeColor: .green)
                    CompactInfoRow(title: "仓库业务数据", value: "已启用", detail: "采购、销售、库存和钱流保存到 warehouse-data.json。", badge: "可用", badgeColor: .green)
                    CompactInfoRow(title: "库存阈值", value: "已启用", detail: "每个库存商品都可以维护低库存预警数量。", badge: "可用", badgeColor: .green)
                }

                SectionCard(title: "数据操作") {
                    Button(role: .destructive) {
                        isConfirmingReset = true
                    } label: {
                        Label("清空仓库业务数据", systemImage: "trash")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .confirmationDialog("清空仓库业务数据？", isPresented: $isConfirmingReset) {
            Button("清空采购、销售、库存和钱流", role: .destructive) {
                businessStore.resetBusinessData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("这不会删除穿线记录工具里的记录。")
        }
    }
}

private struct PurchaseOrderRowView: View {
    let order: PurchaseOrder
    let moneyText: (Double) -> String
    let dateText: (Date) -> String
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(order.supplierName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(order.id) · \(dateText(order.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(itemSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("已付 \(moneyText(order.paidAmount)) / 合计 \(moneyText(order.totalAmount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 8) {
                Text(moneyText(order.totalAmount))
                    .font(.subheadline)
                    .fontWeight(.bold)

                StatusBadge(text: order.status.rawValue, color: order.payableAmount > 0 ? .orange : .green)

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var itemSummary: String {
        order.items
            .map { "\($0.productName) x\($0.quantity)" }
            .joined(separator: ", ")
    }
}

private struct SalesOrderRowView: View {
    let order: SalesOrder
    let moneyText: (Double) -> String
    let dateText: (Date) -> String
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(order.customerName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(order.id) · \(dateText(order.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(itemSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("已收 \(moneyText(order.paidAmount)) / 合计 \(moneyText(order.totalAmount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 8) {
                Text(moneyText(order.totalAmount))
                    .font(.subheadline)
                    .fontWeight(.bold)

                StatusBadge(text: order.status.rawValue, color: order.receivableAmount > 0 ? .orange : .green)

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var itemSummary: String {
        order.items
            .map { "\($0.productName) x\($0.quantity)" }
            .joined(separator: ", ")
    }
}

private struct MoneyRecordRowView: View {
    let record: MoneyRecord
    let moneyText: (Double) -> String
    let dateText: (Date) -> String
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(record.counterparty)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 8) {
                Text(moneyText(record.amount))
                    .font(.subheadline)
                    .fontWeight(.bold)

                StatusBadge(text: record.direction.rawValue, color: record.direction == .incoming ? .green : .orange)

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var detailText: String {
        var parts = [record.id, dateText(record.date)]

        if !record.relatedOrderID.isEmpty {
            parts.append(record.relatedOrderID)
        }

        if !record.note.isEmpty {
            parts.append(record.note)
        }

        return parts.joined(separator: " · ")
    }
}
