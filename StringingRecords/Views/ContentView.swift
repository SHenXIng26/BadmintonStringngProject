import SwiftUI
import UniformTypeIdentifiers

struct StringingRecordsView: View {
    @EnvironmentObject private var store: RecordStore
    @EnvironmentObject private var businessStore: BusinessStore

    @State private var searchText = ""
    @State private var workFilter: WorkStatus?
    @State private var paymentFilter: PaymentStatus?
    @State private var pickupFilter: PickupStatus?
    @State private var editorRoute: EditorRoute?
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var exportDocument = RecordsExportDocument()
    @State private var exportContentType = UTType.json
    @State private var exportFileName = "stringing-records-backup"
    @State private var alertMessage: String?

    private var filteredRecords: [StringingRecord] {
        store.filteredRecords(
            searchText: searchText,
            workStatus: workFilter,
            paymentStatus: paymentFilter,
            pickupStatus: pickupFilter
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SummaryHeaderView(
                    total: store.totalCount,
                    pending: store.pendingCount,
                    unpaid: store.unpaidCount
                )

                FilterPanelView(
                    searchText: $searchText,
                    workFilter: $workFilter,
                    paymentFilter: $paymentFilter,
                    pickupFilter: $pickupFilter
                )

                RecordsSectionView(
                    records: filteredRecords,
                    hasAnyRecords: store.totalCount > 0,
                    onEdit: { record in editorRoute = .edit(record) },
                    onDelete: { record in store.deleteRecord(id: record.id) },
                    onChangeWorkStatus: { record, status in
                        changeWorkStatus(for: record, to: status)
                    },
                    onChangePaymentStatus: { record, status in
                        store.changePaymentStatus(for: record.id, to: status)
                    },
                    onChangePickupStatus: { record, status in
                        store.changePickupStatus(for: record.id, to: status)
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Stringing Records")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        prepareJSONExport()
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        prepareCSVExport()
                    } label: {
                        Label("Export CSV", systemImage: "tablecells")
                    }

                    Button {
                        isImporting = true
                    } label: {
                        Label("Import JSON", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }

                Button {
                    editorRoute = .new
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(item: $editorRoute) { route in
            switch route {
            case .new:
                RecordFormView(record: nil)
                    .environmentObject(store)
                    .environmentObject(businessStore)
            case .edit(let record):
                RecordFormView(record: record)
                    .environmentObject(store)
                    .environmentObject(businessStore)
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFileName
        ) { result in
            if case .failure(let error) = result {
                alertMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            importRecords(from: result)
        }
        .alert("Stringing Records", isPresented: alertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
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

    private func prepareJSONExport() {
        do {
            exportDocument = RecordsExportDocument(data: try store.backupJSONData())
            exportContentType = .json
            exportFileName = "stringing-records-backup"
            isExporting = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func prepareCSVExport() {
        exportDocument = RecordsExportDocument(data: store.csvData())
        exportContentType = .commaSeparatedText
        exportFileName = "stringing-records"
        isExporting = true
    }

    private func importRecords(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let canAccess = url.startAccessingSecurityScopedResource()
            defer {
                if canAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let count = try store.importBackupData(data)
            alertMessage = "Imported \(count) records."
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func changeWorkStatus(for record: StringingRecord, to status: WorkStatus) {
        do {
            try store.changeWorkStatus(for: record.id, to: status, businessStore: businessStore)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

private enum EditorRoute: Identifiable {
    case new
    case edit(StringingRecord)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let record):
            return record.id
        }
    }
}

private struct SummaryHeaderView: View {
    let total: Int
    let pending: Int
    let unpaid: Int

    var body: some View {
            HStack(spacing: 10) {
                SummaryMetricView(title: "Total", value: total, color: .blue)
                SummaryMetricView(title: "Pending", value: pending, color: .orange)
                SummaryMetricView(title: "Unpaid", value: unpaid, color: .gray)
            }
    }
}

private struct SummaryMetricView: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.12))
        )
    }
}

private struct FilterPanelView: View {
    @Binding var searchText: String
    @Binding var workFilter: WorkStatus?
    @Binding var paymentFilter: PaymentStatus?
    @Binding var pickupFilter: PickupStatus?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search customer, racket, string", text: $searchText)
                    .textInputAutocapitalization(.words)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            VStack(spacing: 10) {
                FilterPicker(title: "Work", selection: $workFilter, values: WorkStatus.allCases)
                FilterPicker(title: "Payment", selection: $paymentFilter, values: PaymentStatus.allCases)
                FilterPicker(title: "Pickup", selection: $pickupFilter, values: PickupStatus.allCases)
            }
        }
    }
}

private struct FilterPicker<Value>: View where Value: CaseIterable & Identifiable, Value: Hashable {
    let title: String
    @Binding var selection: Value?
    let values: [Value]

    var body: some View {
        Picker(title, selection: $selection) {
            Text("\(title): All").tag(Optional<Value>.none)

            ForEach(values) { value in
                Text("\(title): \(label(for: value))").tag(Optional(value))
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func label(for value: Value) -> String {
        if let work = value as? WorkStatus {
            return work.label
        }

        if let payment = value as? PaymentStatus {
            return payment.label
        }

        if let pickup = value as? PickupStatus {
            return pickup.label
        }

        return String(describing: value)
    }
}

private struct RecordsSectionView: View {
    let records: [StringingRecord]
    let hasAnyRecords: Bool
    let onEdit: (StringingRecord) -> Void
    let onDelete: (StringingRecord) -> Void
    let onChangeWorkStatus: (StringingRecord, WorkStatus) -> Void
    let onChangePaymentStatus: (StringingRecord, PaymentStatus) -> Void
    let onChangePickupStatus: (StringingRecord, PickupStatus) -> Void

    var body: some View {
        LazyVStack(spacing: 12) {
            if records.isEmpty {
                EmptyRecordsView(hasAnyRecords: hasAnyRecords)
            } else {
                ForEach(records) { record in
                    RecordCardView(
                        record: record,
                        onEdit: { onEdit(record) },
                        onDelete: { onDelete(record) },
                        onChangeWorkStatus: { status in onChangeWorkStatus(record, status) },
                        onChangePaymentStatus: { status in onChangePaymentStatus(record, status) },
                        onChangePickupStatus: { status in onChangePickupStatus(record, status) }
                    )
                }
            }
        }
    }
}

private struct EmptyRecordsView: View {
    let hasAnyRecords: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: hasAnyRecords ? "line.3.horizontal.decrease.circle" : "tray")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text(hasAnyRecords ? "No records match these filters." : "No records yet.")
                .font(.headline)

            Text(hasAnyRecords ? "Try a different search or status filter." : "Tap the plus button to add the first stringing job.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
