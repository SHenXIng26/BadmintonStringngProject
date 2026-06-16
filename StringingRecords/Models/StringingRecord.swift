import Foundation

struct StringingRecord: Identifiable, Codable, Equatable {
    var id: String
    var customerName: String
    var racketModel: String
    var stringName: String
    var tension: String
    var receivedAt: Date
    var price: Double
    var workStatus: WorkStatus
    var paymentStatus: PaymentStatus
    var pickupStatus: PickupStatus
    var notes: String
    var inventoryDeducted: Bool
    var createdAt: Date
    var updatedAt: Date

    var receivedDateText: String {
        Self.dateOnlyFormatter.string(from: receivedAt)
    }

    var priceText: String {
        String(format: "$%.2f", price)
    }

    var searchableText: String {
        [
            id,
            customerName,
            racketModel,
            stringName,
            tension,
            notes
        ].joined(separator: " ").lowercased()
    }

    var isUsableImportedRecord: Bool {
        !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !racketModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(
        id: String,
        customerName: String,
        racketModel: String,
        stringName: String,
        tension: String,
        receivedAt: Date,
        price: Double,
        workStatus: WorkStatus = .pending,
        paymentStatus: PaymentStatus = .unpaid,
        pickupStatus: PickupStatus = .notPickedUp,
        notes: String = "",
        inventoryDeducted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.customerName = customerName
        self.racketModel = racketModel
        self.stringName = stringName
        self.tension = tension
        self.receivedAt = receivedAt
        self.price = price
        self.workStatus = workStatus
        self.paymentStatus = paymentStatus
        self.pickupStatus = pickupStatus
        self.notes = notes
        self.inventoryDeducted = inventoryDeducted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case customerName
        case racketModel
        case stringName
        case tension
        case receivedAt
        case price
        case workStatus
        case paymentStatus
        case pickupStatus
        case notes
        case inventoryDeducted
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        customerName = (try? container.decode(String.self, forKey: .customerName)) ?? ""
        racketModel = (try? container.decode(String.self, forKey: .racketModel)) ?? ""
        stringName = (try? container.decode(String.self, forKey: .stringName)) ?? ""
        tension = (try? container.decode(String.self, forKey: .tension)) ?? ""
        receivedAt = Self.decodeDate(from: container, forKey: .receivedAt) ?? Date()
        price = Self.decodeDouble(from: container, forKey: .price) ?? 25
        workStatus = (try? container.decode(WorkStatus.self, forKey: .workStatus)) ?? .pending
        paymentStatus = (try? container.decode(PaymentStatus.self, forKey: .paymentStatus)) ?? .unpaid
        pickupStatus = (try? container.decode(PickupStatus.self, forKey: .pickupStatus)) ?? .notPickedUp
        notes = (try? container.decode(String.self, forKey: .notes)) ?? ""
        inventoryDeducted = (try? container.decode(Bool.self, forKey: .inventoryDeducted)) ?? false
        createdAt = Self.decodeDate(from: container, forKey: .createdAt) ?? Date()
        updatedAt = Self.decodeDate(from: container, forKey: .updatedAt) ?? createdAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(customerName, forKey: .customerName)
        try container.encode(racketModel, forKey: .racketModel)
        try container.encode(stringName, forKey: .stringName)
        try container.encode(tension, forKey: .tension)
        try container.encode(Self.dateOnlyFormatter.string(from: receivedAt), forKey: .receivedAt)
        try container.encode(price, forKey: .price)
        try container.encode(workStatus, forKey: .workStatus)
        try container.encode(paymentStatus, forKey: .paymentStatus)
        try container.encode(pickupStatus, forKey: .pickupStatus)
        try container.encode(notes, forKey: .notes)
        try container.encode(inventoryDeducted, forKey: .inventoryDeducted)
        try container.encode(Self.isoString(from: createdAt), forKey: .createdAt)
        try container.encode(Self.isoString(from: updatedAt), forKey: .updatedAt)
    }

    static func isoString(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static func decodeDate<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Date? {
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }

        guard let string = try? container.decode(String.self, forKey: key) else {
            return nil
        }

        return isoFormatter.date(from: string) ??
        isoFormatterWithoutFractions.date(from: string) ??
        dateOnlyFormatter.date(from: string)
    }

    private static func decodeDouble<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Double? {
        if let number = try? container.decode(Double.self, forKey: key) {
            return number
        }

        if let string = try? container.decode(String.self, forKey: key) {
            return Double(string)
        }

        return nil
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterWithoutFractions: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

struct RecordDraft: Equatable {
    var customerName = ""
    var racketModel = ""
    var stringName = ""
    var tension = ""
    var receivedAt = Date()
    var price = 25.0
    var workStatus = WorkStatus.pending
    var paymentStatus = PaymentStatus.unpaid
    var pickupStatus = PickupStatus.notPickedUp
    var notes = ""
    var inventoryDeducted = false

    init() {}

    init(record: StringingRecord) {
        customerName = record.customerName
        racketModel = record.racketModel
        stringName = record.stringName
        tension = record.tension
        receivedAt = record.receivedAt
        price = record.price
        workStatus = record.workStatus
        paymentStatus = record.paymentStatus
        pickupStatus = record.pickupStatus
        notes = record.notes
        inventoryDeducted = record.inventoryDeducted
    }

    var validationMessage: String? {
        if customerName.trimmed.isEmpty {
            return "Customer name is required."
        }

        if racketModel.trimmed.isEmpty {
            return "Racket model is required."
        }

        if stringName.trimmed.isEmpty {
            return "String name is required."
        }

        if tension.trimmed.isEmpty {
            return "Tension is required."
        }

        if price < 0 {
            return "Price cannot be negative."
        }

        return nil
    }

    func makeRecord(id: String, createdAt: Date = Date()) -> StringingRecord {
        StringingRecord(
            id: id,
            customerName: customerName.trimmed,
            racketModel: racketModel.trimmed,
            stringName: stringName.trimmed,
            tension: tension.trimmed,
            receivedAt: receivedAt,
            price: price,
            workStatus: workStatus,
            paymentStatus: paymentStatus,
            pickupStatus: pickupStatus,
            notes: notes.trimmed,
            inventoryDeducted: inventoryDeducted,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
