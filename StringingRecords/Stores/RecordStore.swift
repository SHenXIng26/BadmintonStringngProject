import Foundation
import Combine

@MainActor
final class RecordStore: ObservableObject {
    @Published private(set) var records: [StringingRecord] = []
    @Published var message: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        loadRecords()
    }

    var totalCount: Int {
        records.count
    }

    var pendingCount: Int {
        records.filter { $0.workStatus == .pending }.count
    }

    var unpaidCount: Int {
        records.filter { $0.paymentStatus == .unpaid }.count
    }

    func filteredRecords(
        searchText: String,
        workStatus: WorkStatus?,
        paymentStatus: PaymentStatus?,
        pickupStatus: PickupStatus?
    ) -> [StringingRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return records.filter { record in
            let matchesSearch = query.isEmpty || record.searchableText.contains(query)
            let matchesWork = workStatus == nil || record.workStatus == workStatus
            let matchesPayment = paymentStatus == nil || record.paymentStatus == paymentStatus
            let matchesPickup = pickupStatus == nil || record.pickupStatus == pickupStatus

            return matchesSearch && matchesWork && matchesPayment && matchesPickup
        }
    }

    @discardableResult
    func addRecord(from draft: RecordDraft) -> StringingRecord {
        let record = draft.makeRecord(id: nextMonthlyRecordID(for: draft.receivedAt))
        records.append(record)
        records = Self.sorted(records)
        persistRecords()
        message = "Record \(record.id) saved."
        return record
    }

    func updateRecord(id: String, with draft: RecordDraft) {
        guard let index = records.firstIndex(where: { $0.id == id }) else {
            return
        }

        let createdAt = records[index].createdAt
        records[index] = draft.makeRecord(id: id, createdAt: createdAt)
        records = Self.sorted(records)
        persistRecords()
        message = "Record \(id) updated."
    }

    func deleteRecord(id: String) {
        records.removeAll { $0.id == id }
        persistRecords()
        message = "Record \(id) deleted."
    }

    func toggleWorkStatus(for id: String) {
        updateRecord(id: id) { record in
            record.workStatus = record.workStatus == .completed ? .pending : .completed
        }
    }

    func togglePaymentStatus(for id: String) {
        updateRecord(id: id) { record in
            record.paymentStatus = record.paymentStatus == .paid ? .unpaid : .paid
        }
    }

    func togglePickupStatus(for id: String) {
        updateRecord(id: id) { record in
            record.pickupStatus = record.pickupStatus == .pickedUp ? .notPickedUp : .pickedUp
        }
    }

    func backupJSONData() throws -> Data {
        let encoder = Self.makeJSONEncoder()
        return try encoder.encode(RecordsBackup(records: records))
    }

    func csvData() -> Data {
        let headers = [
            "ID",
            "Customer",
            "Racket",
            "String",
            "Tension",
            "Received",
            "Price",
            "Work",
            "Payment",
            "Pickup",
            "Notes"
        ]

        let rows = records.map { record in
            [
                record.id,
                record.customerName,
                record.racketModel,
                record.stringName,
                record.tension,
                record.receivedDateText,
                String(format: "%.2f", record.price),
                record.workStatus.label,
                record.paymentStatus.label,
                record.pickupStatus.label,
                record.notes
            ]
        }

        let csv = ([headers] + rows)
            .map { row in row.map(Self.escapeCSVCell).joined(separator: ",") }
            .joined(separator: "\n")

        return Data(csv.utf8)
    }

    @discardableResult
    func importBackupData(_ data: Data) throws -> Int {
        let decoder = JSONDecoder()
        let incomingRecords: [StringingRecord]

        if let backup = try? decoder.decode(RecordsBackup.self, from: data) {
            incomingRecords = backup.records
        } else {
            incomingRecords = try decoder.decode([StringingRecord].self, from: data)
        }

        let usableRecords = incomingRecords.filter(\.isUsableImportedRecord)
        var mergedRecords: [String: StringingRecord] = [:]

        for record in records {
            mergedRecords[record.id] = record
        }

        for record in usableRecords {
            mergedRecords[record.id] = record
        }

        records = Self.sorted(Array(mergedRecords.values))
        persistRecords()
        message = "Imported \(usableRecords.count) records."
        return usableRecords.count
    }

    private func updateRecord(id: String, mutate: (inout StringingRecord) -> Void) {
        guard let index = records.firstIndex(where: { $0.id == id }) else {
            return
        }

        var record = records[index]
        mutate(&record)
        record.updatedAt = Date()
        records[index] = record
        records = Self.sorted(records)
        persistRecords()
    }

    private func loadRecords() {
        guard let data = try? Data(contentsOf: fileURL) else {
            records = []
            return
        }

        do {
            let decodedRecords = try JSONDecoder().decode([StringingRecord].self, from: data)
            records = Self.sorted(decodedRecords)
        } catch {
            records = []
            message = "Saved records could not be loaded."
        }
    }

    private func persistRecords() {
        do {
            let data = try Self.makeJSONEncoder().encode(records)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            message = "Records could not be saved."
        }
    }

    private func nextMonthlyRecordID(for date: Date) -> String {
        let prefix = Self.monthFormatter.string(from: date)
        let largestNumber = records.compactMap { record -> Int? in
            guard record.id.hasPrefix(prefix + "-") else {
                return nil
            }

            return Int(record.id.replacingOccurrences(of: prefix + "-", with: ""))
        }.max() ?? 0

        return "\(prefix)-\(String(format: "%03d", largestNumber + 1))"
    }

    private static func sorted(_ records: [StringingRecord]) -> [StringingRecord] {
        records.sorted { first, second in
            if first.receivedAt != second.receivedAt {
                return first.receivedAt > second.receivedAt
            }

            return first.id > second.id
        }
    }

    private static func makeJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func defaultFileURL() -> URL {
        let fileManager = FileManager.default
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ??
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let folderURL = baseURL.appendingPathComponent("StringingRecords", isDirectory: true)

        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)

        return folderURL.appendingPathComponent("records.json")
    }

    private static func escapeCSVCell(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMM"
        return formatter
    }()
}
