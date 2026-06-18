import SwiftUI

struct StockInRecordFormView: View {
    @Environment(\.dismiss) private var dismiss

    let inventoryItems: [StringInventoryItem]
    let onSave: (StringStockInDraft) throws -> Void

    @State private var draft = StringStockInDraft()
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("入库信息") {
                    DatePicker("入库日期", selection: $draft.date, displayedComponents: .date)

                    ExistingStringMenu(
                        title: "从库存线材填入",
                        items: inventoryItems,
                        onSelect: { item in
                            draft.stringName = item.name
                            draft.brand = item.brand
                            draft.color = item.color
                            draft.costPerPack = item.costPerPack
                        }
                    )

                    TextField("线材名称", text: $draft.stringName)
                        .textInputAutocapitalization(.words)

                    TextField("品牌", text: $draft.brand)
                        .textInputAutocapitalization(.words)

                    TextField("颜色", text: $draft.color)
                        .textInputAutocapitalization(.words)
                }

                Section("数量与成本") {
                    Stepper("入库数量：\(draft.quantity) 包", value: $draft.quantity, in: 1...9999)

                    TextField("每包成本", value: $draft.costPerPack, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)

                    LabeledContent("总成本", value: draft.totalCost.formatted(.currency(code: "AUD")))
                }

                Section("备注") {
                    TextField("可选", text: $draft.note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("新增入库")
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
            .alert("入库记录", isPresented: alertBinding) {
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

struct StockInRecordRowView: View {
    let record: StringStockInRecord
    let moneyText: (Double) -> String
    let dateText: (Date) -> String
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(record.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(record.id) · \(dateText(record.date)) · \(record.brand.isEmpty ? "未设置品牌" : record.brand)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(record.quantity) 包 x \(moneyText(record.costPerPack))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 8) {
                Text(moneyText(record.totalCost))
                    .font(.subheadline)
                    .fontWeight(.bold)

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
}

private struct ExistingStringMenu: View {
    let title: String
    let items: [StringInventoryItem]
    let onSelect: (StringInventoryItem) -> Void

    var body: some View {
        if items.isEmpty {
            Text("暂无库存线材，可手动输入新线材")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Menu(title) {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        Text("\(item.displayName) · \(item.quantity) 包")
                    }
                }
            }
        }
    }
}
