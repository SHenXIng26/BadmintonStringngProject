import SwiftUI

struct RecordCardView: View {
    let record: StringingRecord
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleWork: () -> Void
    let onTogglePayment: () -> Void
    let onTogglePickup: () -> Void

    @State private var isConfirmingDelete = false

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
                Button(action: onToggleWork) {
                    Label(record.workStatus.actionLabel, systemImage: record.workStatus.systemImage)
                }
                .buttonStyle(.bordered)

                Button(action: onTogglePayment) {
                    Label(record.paymentStatus.actionLabel, systemImage: record.paymentStatus.systemImage)
                }
                .buttonStyle(.bordered)

                Button(action: onTogglePickup) {
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
