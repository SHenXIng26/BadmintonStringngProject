import SwiftUI

struct RecordFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: RecordStore
    @EnvironmentObject private var businessStore: BusinessStore

    let record: StringingRecord?

    @State private var draft: RecordDraft
    @State private var validationMessage: String?
    @State private var pendingStatusChange: RecordFormStatusChange?

    init(record: StringingRecord?) {
        self.record = record
        _draft = State(initialValue: record.map(RecordDraft.init) ?? RecordDraft())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer") {
                    TextField("Customer name", text: $draft.customerName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)

                    TextField("Racket model", text: $draft.racketModel)
                        .textInputAutocapitalization(.words)
                }

                Section("Stringing") {
                    if inventoryStrings.isEmpty {
                        Text("No strings in inventory. Please add inventory first.")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    } else {
                        Picker("String name", selection: $draft.stringName) {
                            ForEach(inventoryStrings, id: \.self) { stringName in
                                Text(stringName).tag(stringName)
                            }
                        }
                        .pickerStyle(.menu)

                        if !draft.stringName.isEmpty && !inventoryStrings.contains(draft.stringName) {
                            Text("Current string is not in inventory. Please choose one from inventory.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    TextField("Tension, e.g. 26 lbs", text: $draft.tension)
                        .textInputAutocapitalization(.never)

                    TextField("Price", value: $draft.price, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)

                    DatePicker("Received date", selection: $draft.receivedAt, displayedComponents: .date)
                }

                Section("Status") {
                    Picker("Work", selection: workStatusBinding) {
                        ForEach(WorkStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }

                    Picker("Payment", selection: paymentStatusBinding) {
                        ForEach(PaymentStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }

                    Picker("Pickup", selection: pickupStatusBinding) {
                        ForEach(PickupStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $draft.notes)
                        .frame(minHeight: 96)
                }
            }
            .navigationTitle(record == nil ? "New Record" : "Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecord()
                    }
                    .fontWeight(.bold)
                    .disabled(isSaveDisabled)
                }
            }
            .alert("Check Record", isPresented: validationAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage ?? "")
            }
            .alert(
                "确认更改状态",
                isPresented: statusConfirmationBinding,
                presenting: pendingStatusChange
            ) { change in
                Button("取消", role: .cancel) {
                    pendingStatusChange = nil
                }

                Button("确认") {
                    applyStatusChange(change)
                }
            } message: { change in
                Text("确定要将状态从 \(change.fromLabel) 更改为 \(change.toLabel) 吗？")
            }
        }
        .onAppear {
            ensureInventoryStringSelection()
        }
    }

    private var inventoryStrings: [String] {
        businessStore.snapshot.inventoryItems
            .map(\.name)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted()
    }

    private var isSaveDisabled: Bool {
        inventoryStrings.isEmpty || !inventoryStrings.contains(draft.stringName)
    }

    private var workStatusBinding: Binding<WorkStatus> {
        Binding {
            draft.workStatus
        } set: { newStatus in
            guard newStatus != draft.workStatus else {
                return
            }

            pendingStatusChange = .work(from: draft.workStatus, to: newStatus)
        }
    }

    private var paymentStatusBinding: Binding<PaymentStatus> {
        Binding {
            draft.paymentStatus
        } set: { newStatus in
            guard newStatus != draft.paymentStatus else {
                return
            }

            pendingStatusChange = .payment(from: draft.paymentStatus, to: newStatus)
        }
    }

    private var pickupStatusBinding: Binding<PickupStatus> {
        Binding {
            draft.pickupStatus
        } set: { newStatus in
            guard newStatus != draft.pickupStatus else {
                return
            }

            pendingStatusChange = .pickup(from: draft.pickupStatus, to: newStatus)
        }
    }

    private var validationAlertBinding: Binding<Bool> {
        Binding {
            validationMessage != nil
        } set: { isPresented in
            if !isPresented {
                validationMessage = nil
            }
        }
    }

    private var statusConfirmationBinding: Binding<Bool> {
        Binding {
            pendingStatusChange != nil
        } set: { isPresented in
            if !isPresented {
                pendingStatusChange = nil
            }
        }
    }

    private func saveRecord() {
        ensureInventoryStringSelection()

        if inventoryStrings.isEmpty {
            validationMessage = "No strings in inventory. Please add inventory first."
            return
        }

        if !inventoryStrings.contains(draft.stringName) {
            validationMessage = "Please choose a string from inventory."
            return
        }

        if let validationMessage = draft.validationMessage {
            self.validationMessage = validationMessage
            return
        }

        do {
            if let record {
                try store.updateRecord(id: record.id, with: draft, businessStore: businessStore)
            } else {
                try store.addRecord(from: draft, businessStore: businessStore)
            }

            dismiss()
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    private func applyStatusChange(_ change: RecordFormStatusChange) {
        switch change {
        case .work(_, let newStatus):
            draft.workStatus = newStatus
        case .payment(_, let newStatus):
            draft.paymentStatus = newStatus
        case .pickup(_, let newStatus):
            draft.pickupStatus = newStatus
        }

        pendingStatusChange = nil
    }

    private func ensureInventoryStringSelection() {
        guard !inventoryStrings.isEmpty else {
            return
        }

        if record == nil && !inventoryStrings.contains(draft.stringName) {
            draft.stringName = inventoryStrings[0]
        }
    }
}

private enum RecordFormStatusChange: Identifiable {
    case work(from: WorkStatus, to: WorkStatus)
    case payment(from: PaymentStatus, to: PaymentStatus)
    case pickup(from: PickupStatus, to: PickupStatus)

    var id: String {
        "\(kind)-\(fromLabel)-\(toLabel)"
    }

    var kind: String {
        switch self {
        case .work:
            return "work"
        case .payment:
            return "payment"
        case .pickup:
            return "pickup"
        }
    }

    var fromLabel: String {
        switch self {
        case .work(let from, _):
            return from.label
        case .payment(let from, _):
            return from.label
        case .pickup(let from, _):
            return from.label
        }
    }

    var toLabel: String {
        switch self {
        case .work(_, let to):
            return to.label
        case .payment(_, let to):
            return to.label
        case .pickup(_, let to):
            return to.label
        }
    }
}
