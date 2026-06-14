import SwiftUI

enum InventorySheet: Identifiable {
    case new
    case edit(InventoryItem)
    case adjust(InventoryItem)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let item):
            return "edit-\(item.product.code)"
        case .adjust(let item):
            return "adjust-\(item.product.code)"
        }
    }
}

struct InventoryItemRowView: View {
    let item: InventoryItem
    let moneyText: (Double) -> String
    let onEdit: () -> Void
    let onAdjust: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.product.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    StatusBadge(
                        text: item.isLowStock ? "低库存" : "正常",
                        color: item.isLowStock ? .orange : .green
                    )
                }

                Text("\(item.product.code) · \(item.product.brand) · \(item.product.category.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("位置：\(item.location.isEmpty ? "未设置" : item.location) · 安全库存：\(item.lowStockThreshold)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("售价 \(moneyText(item.product.salePrice)) · 成本 \(moneyText(item.product.costPrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 8) {
                Text("\(item.quantity)")
                    .font(.title3)
                    .fontWeight(.bold)

                Menu {
                    Button(action: onAdjust) {
                        Label("库存调整", systemImage: "plusminus")
                    }

                    Button(action: onEdit) {
                        Label("编辑商品", systemImage: "pencil")
                    }

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
}

struct InventoryItemFormView: View {
    @Environment(\.dismiss) private var dismiss

    let item: InventoryItem?
    let onSave: (InventoryItemDraft) throws -> Void

    @State private var draft: InventoryItemDraft
    @State private var alertMessage: String?

    private var isEditing: Bool {
        item != nil
    }

    init(item: InventoryItem?, onSave: @escaping (InventoryItemDraft) throws -> Void) {
        self.item = item
        self.onSave = onSave
        _draft = State(initialValue: item.map(InventoryItemDraft.init) ?? InventoryItemDraft())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("商品资料") {
                    TextField("商品编码", text: $draft.code)
                        .textInputAutocapitalization(.characters)
                        .disabled(isEditing)

                    TextField("商品名称", text: $draft.name)
                        .textInputAutocapitalization(.words)

                    Picker("分类", selection: $draft.category) {
                        ForEach(ProductCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    TextField("品牌", text: $draft.brand)
                        .textInputAutocapitalization(.words)
                }

                Section("价格") {
                    TextField("售价", value: $draft.salePrice, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)

                    TextField("成本", value: $draft.costPrice, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                }

                Section("库存") {
                    Stepper("当前库存：\(draft.quantity)", value: $draft.quantity, in: 0...9999)
                    Stepper("低库存预警：\(draft.lowStockThreshold)", value: $draft.lowStockThreshold, in: 0...9999)

                    TextField("库存位置", text: $draft.location)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle(isEditing ? "编辑库存" : "新增库存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Inventory", isPresented: alertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
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

    private func save() {
        do {
            try onSave(draft)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

struct InventoryAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss

    let item: InventoryItem
    let onSave: (Int, String) throws -> Void

    @State private var quantityChange = 0
    @State private var note = ""
    @State private var alertMessage: String?

    private var resultingQuantity: Int {
        item.quantity + quantityChange
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("商品") {
                    LabeledContent("名称", value: item.product.name)
                    LabeledContent("编码", value: item.product.code)
                    LabeledContent("当前库存", value: "\(item.quantity)")
                    LabeledContent("调整后库存", value: "\(resultingQuantity)")
                }

                Section("库存调整") {
                    Stepper("变化数量：\(quantityChange)", value: $quantityChange, in: -999...999)

                    TextField("备注，例如补货、盘点、损耗", text: $note)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle("库存调整")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Inventory", isPresented: alertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
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

    private func save() {
        do {
            try onSave(quantityChange, note)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
