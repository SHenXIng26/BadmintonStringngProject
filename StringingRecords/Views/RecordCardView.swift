import SwiftUI

struct RecordCardView: View {
    let record: StringingRecord
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onChangeWorkStatus: (WorkStatus) -> Void
    let onChangePaymentStatus: (PaymentStatus) -> Void
    let onChangePickupStatus: (PickupStatus) -> Void

    @State private var isConfirmingDelete = false
    @State private var pendingStatusChange: RecordCardStatusChange?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Racket", value: record.racketModel)
                DetailRow(label: "String", value: record.stringName)
                DetailRow(label: "Tension", value: record.tension)
                DetailRow(label: "Received", value: record.receivedDateText)
                DetailRow(label: "Price", value: record.priceText)
            }

            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGroupedBackground))
                    )
            }

            VStack(spacing: 8) {
                Button {
                    pendingStatusChange = .work(
                        from: record.workStatus,
                        to: record.workStatus == .completed ? .pending : .completed
                    )
                } label: {
                    Label(record.workStatus.actionLabel, systemImage: record.workStatus.systemImage)
                }
                .buttonStyle(.bordered)

                Button {
                    pendingStatusChange = .payment(
                        from: record.paymentStatus,
                        to: record.paymentStatus == .paid ? .unpaid : .paid
                    )
                } label: {
                    Label(record.paymentStatus.actionLabel, systemImage: record.paymentStatus.systemImage)
                }
                .buttonStyle(.bordered)

                Button {
                    pendingStatusChange = .pickup(
                        from: record.pickupStatus,
                        to: record.pickupStatus == .pickedUp ? .notPickedUp : .pickedUp
                    )
                } label: {
                    Label(record.pickupStatus.actionLabel, systemImage: record.pickupStatus.systemImage)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .confirmationDialog("Delete record \(record.id)?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
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
                confirmStatusChange(change)
            }
        } message: { change in
            Text("确定要将状态从 \(change.fromLabel) 更改为 \(change.toLabel) 吗？")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.id)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)

                    Text(record.customerName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                StatusPillView(label: "Work: \(record.workStatus.label)", color: record.workStatus.tint)
                StatusPillView(label: "Payment: \(record.paymentStatus.label)", color: record.paymentStatus.tint)
                StatusPillView(label: "Pickup: \(record.pickupStatus.label)", color: record.pickupStatus.tint)
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

    private func confirmStatusChange(_ change: RecordCardStatusChange) {
        switch change {
        case .work(_, let newStatus):
            onChangeWorkStatus(newStatus)
        case .payment(_, let newStatus):
            onChangePaymentStatus(newStatus)
        case .pickup(_, let newStatus):
            onChangePickupStatus(newStatus)
        }

        pendingStatusChange = nil
    }
}

private enum RecordCardStatusChange: Identifiable {
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

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct StatusPillView: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.14))
            )
    }
}
