import SwiftUI

struct RecordFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: RecordStore

    let record: StringingRecord?

    @State private var draft: RecordDraft
    @State private var validationMessage: String?

    private let commonStrings = [
        "Yonex BG65",
        "Yonex BG80",
        "Yonex BG66U",
        "Yonex Exbolt 63",
        "Yonex Nanogy 98",
        "Victor VBS-61",
        "Victor VBS-66 Nano",
        "Li-Ning L67"
    ]

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
                    TextField("String name", text: $draft.stringName)
                        .textInputAutocapitalization(.words)

                    Menu {
                        ForEach(commonStrings, id: \.self) { stringName in
                            Button(stringName) {
                                draft.stringName = stringName
                            }
                        }
                    } label: {
                        Label("Choose common string", systemImage: "list.bullet")
                    }

                    TextField("Tension, e.g. 26 lbs", text: $draft.tension)
                        .textInputAutocapitalization(.never)

                    TextField("Price", value: $draft.price, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)

                    DatePicker("Received date", selection: $draft.receivedAt, displayedComponents: .date)
                }

                Section("Status") {
                    Picker("Work", selection: $draft.workStatus) {
                        ForEach(WorkStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }

                    Picker("Payment", selection: $draft.paymentStatus) {
                        ForEach(PaymentStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }

                    Picker("Pickup", selection: $draft.pickupStatus) {
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
                }
            }
            .alert("Check Record", isPresented: validationAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage ?? "")
            }
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

    private func saveRecord() {
        if let validationMessage = draft.validationMessage {
            self.validationMessage = validationMessage
            return
        }

        if let record {
            store.updateRecord(id: record.id, with: draft)
        } else {
            store.addRecord(from: draft)
        }

        dismiss()
    }
}
