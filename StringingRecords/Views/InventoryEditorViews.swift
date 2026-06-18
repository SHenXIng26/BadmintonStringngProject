import SwiftUI

enum InventorySheet: Identifiable {
    case new
    case edit(StringInventoryItem)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let item):
            return "edit-\(item.id.uuidString)"
        }
    }
}

struct StringInventoryItemRowView: View {
    let item: StringInventoryItem
    let moneyText: (Double) -> String
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    StatusBadge(
                        text: item.isLowStock ? "低库存" : "正常",
                        color: item.isLowStock ? .orange : .green
                    )
                }

                Text(item.brand.isEmpty ? "未设置品牌" : item.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("成本 \(moneyText(item.costPerPack)) / 包 · 提醒 \(item.lowStockThreshold) 包")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 8) {
                Text("\(item.quantity) 包")
                    .font(.title3)
                    .fontWeight(.bold)

                Menu {
                    Button(action: onEdit) {
                        Label("编辑线材", systemImage: "pencil")
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

struct StringInventoryItemFormView: View {
    @Environment(\.dismiss) private var dismiss

    let item: StringInventoryItem?
    let onSave: (StringInventoryItemDraft) throws -> Void

    @State private var draft: StringInventoryItemDraft
    @State private var alertMessage: String?

    private var isEditing: Bool {
        item != nil
    }

    init(item: StringInventoryItem?, onSave: @escaping (StringInventoryItemDraft) throws -> Void) {
        self.item = item
        self.onSave = onSave
        _draft = State(initialValue: item.map(StringInventoryItemDraft.init) ?? StringInventoryItemDraft())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("线材资料") {
                    TextField("线材名称，例如 Yonex BG80", text: $draft.name)
                        .textInputAutocapitalization(.words)

                    TextField("品牌，例如 Yonex", text: $draft.brand)
                        .textInputAutocapitalization(.words)

                    TextField("颜色，例如 White", text: $draft.color)
                        .textInputAutocapitalization(.words)
                }

                Section("成本与库存") {
                    TextField("每包成本", value: $draft.costPerPack, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)

                    Stepper("当前库存：\(draft.quantity) 包", value: $draft.quantity, in: 0...9999)
                    Stepper("低库存提醒：\(draft.lowStockThreshold) 包", value: $draft.lowStockThreshold, in: 0...9999)
                }

                Section("备注") {
                    TextField("可选", text: $draft.note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "编辑线材" : "新增线材")
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
            .alert("线材库存", isPresented: alertBinding) {
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
