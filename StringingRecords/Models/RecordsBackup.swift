import Foundation

struct RecordsBackup: Codable {
    var exportedAt: String
    var app: String
    var records: [StringingRecord]

    init(records: [StringingRecord]) {
        exportedAt = StringingRecord.isoString(from: Date())
        app = "South Brisbane Badminton Stringing Records"
        self.records = records
    }
}
