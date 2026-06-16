import Foundation

enum InitialBusinessData {
    static func makeSnapshot() -> BusinessSnapshot {
        BusinessSnapshot(
            inventoryItems: [],
            stockInRecords: []
        )
    }
}
