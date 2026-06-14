import Foundation

enum InitialBusinessData {
    static func makeSnapshot() -> BusinessSnapshot {
        BusinessSnapshot(
            products: [],
            inventoryItems: [],
            salesOrders: [],
            purchaseOrders: [],
            inventoryMovements: [],
            moneyRecords: [],
            notices: []
        )
    }
}
