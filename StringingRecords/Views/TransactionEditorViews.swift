import SwiftUI

struct PurchaseOrderFormView: View {
    @Environment(\.dismiss) private var dismiss

    let products: [BusinessProduct]
    let onSave: (PurchaseOrderDraft) throws -> Void

    @State private var draft = PurchaseOrderDraft()
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("采购信息") {
                    DatePicker("日期", selection: $draft.date, displayedComponents: .date)
                    TextField("供应商", text: $draft.supplierName)
                        .textInputAutocapitalization(.words)
                }

                Section("入库商品") {
                    ExistingProductMenu(
                        title: "从已有商品填入",
                        products: products,
                        onSelect: { product in
                            draft.item.productCode = product.code
                            draft.item.productName = product.name
                            draft.item.unitPrice = product.costPrice
                        }
                    )

                    TextField("商品编码", text: $draft.item.productCode)
                        .textInputAutocapitalization(.characters)

                    TextField("商品名称", text: $draft.item.productName)
                        .textInputAutocapitalization(.words)

                    Stepper("数量：\(draft.item.quantity)", value: $draft.item.quantity, in: 1...9999)

                    TextField("采购单价", value: $draft.item.unitPrice, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                }

                Section("付款") {
                    LabeledContent("订单合计", value: moneyPreview(draft.item.lineTotalPreview))

                    TextField("已付款", value: $draft.paidAmount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("采购入库")
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
            .alert("采购入库", isPresented: alertBinding) {
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

struct SalesOrderFormView: View {
    @Environment(\.dismiss) private var dismiss

    let inventoryItems: [InventoryItem]
    let onSave: (SalesOrderDraft) throws -> Void

    @State private var draft = SalesOrderDraft()
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("销售信息") {
                    DatePicker("日期", selection: $draft.date, displayedComponents: .date)
                    TextField("客户", text: $draft.customerName)
                        .textInputAutocapitalization(.words)
                }

                Section("出库商品") {
                    ExistingInventoryMenu(
                        title: "从库存商品填入",
                        items: inventoryItems,
                        onSelect: { item in
                            draft.item.productCode = item.product.code
                            draft.item.productName = item.product.name
                            draft.item.unitPrice = item.product.salePrice
                        }
                    )

                    TextField("商品编码", text: $draft.item.productCode)
                        .textInputAutocapitalization(.characters)

                    TextField("商品名称", text: $draft.item.productName)
                        .textInputAutocapitalization(.words)

                    Stepper("数量：\(draft.item.quantity)", value: $draft.item.quantity, in: 1...9999)

                    TextField("销售单价", value: $draft.item.unitPrice, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                }

                Section("收款") {
                    LabeledContent("订单合计", value: moneyPreview(draft.item.lineTotalPreview))

                    TextField("已收款", value: $draft.paidAmount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("销售出库")
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
            .alert("销售出库", isPresented: alertBinding) {
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

struct MoneyRecordFormView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (MoneyRecordDraft) throws -> Void

    @State private var draft = MoneyRecordDraft()
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("收付款信息") {
                    Picker("类型", selection: $draft.direction) {
                        Text(MoneyDirection.incoming.rawValue).tag(MoneyDirection.incoming)
                        Text(MoneyDirection.outgoing.rawValue).tag(MoneyDirection.outgoing)
                    }
                    .pickerStyle(.segmented)

                    DatePicker("日期", selection: $draft.date, displayedComponents: .date)

                    TextField("对象", text: $draft.counterparty)
                        .textInputAutocapitalization(.words)

                    TextField("金额", value: $draft.amount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                }

                Section("关联与备注") {
                    TextField("关联订单号，可留空", text: $draft.relatedOrderID)
                        .textInputAutocapitalization(.characters)

                    TextField("备注", text: $draft.note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("收付款登记")
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
            .alert("收付款登记", isPresented: alertBinding) {
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

private struct ExistingProductMenu: View {
    let title: String
    let products: [BusinessProduct]
    let onSelect: (BusinessProduct) -> Void

    var body: some View {
        if products.isEmpty {
            Text("暂无可选商品")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Menu(title) {
                ForEach(products) { product in
                    Button {
                        onSelect(product)
                    } label: {
                        Text("\(product.code) · \(product.name)")
                    }
                }
            }
        }
    }
}

private struct ExistingInventoryMenu: View {
    let title: String
    let items: [InventoryItem]
    let onSelect: (InventoryItem) -> Void

    var body: some View {
        if items.isEmpty {
            Text("暂无库存商品")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Menu(title) {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        Text("\(item.product.code) · \(item.product.name) · 库存 \(item.quantity)")
                    }
                }
            }
        }
    }
}

private extension OrderLineItemDraft {
    var lineTotalPreview: Double {
        Double(quantity) * unitPrice
    }
}

private func moneyPreview(_ amount: Double) -> String {
    amount.formatted(.currency(code: "AUD"))
}
