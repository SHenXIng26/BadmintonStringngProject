import Foundation

enum MockBusinessData {
    static func makeSnapshot(referenceDate: Date = Date()) -> BusinessSnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today) ?? today

        let products = [
            BusinessProduct(code: "STR-BG65", name: "Yonex BG65", category: .string, brand: "Yonex", salePrice: 25, costPrice: 14),
            BusinessProduct(code: "STR-BG80", name: "Yonex BG80", category: .string, brand: "Yonex", salePrice: 25, costPrice: 15),
            BusinessProduct(code: "STR-EX63", name: "Yonex Exbolt 63", category: .string, brand: "Yonex", salePrice: 27.5, costPrice: 17),
            BusinessProduct(code: "STR-VBS61", name: "Victor VBS-61", category: .string, brand: "Victor", salePrice: 25, costPrice: 14),
            BusinessProduct(code: "RKT-LNCAN", name: "Li-Ning Cannon", category: .racket, brand: "Li-Ning", salePrice: 145, costPrice: 96),
            BusinessProduct(code: "SVC-STRING", name: "Badminton Stringing Service", category: .service, brand: "Service", salePrice: 15, costPrice: 0)
        ]

        let inventoryItems = [
            InventoryItem(product: products[0], quantity: 18, lowStockThreshold: 6, location: "Main Box"),
            InventoryItem(product: products[1], quantity: 4, lowStockThreshold: 6, location: "Main Box"),
            InventoryItem(product: products[2], quantity: 3, lowStockThreshold: 5, location: "Main Box"),
            InventoryItem(product: products[3], quantity: 8, lowStockThreshold: 5, location: "Main Box"),
            InventoryItem(product: products[4], quantity: 2, lowStockThreshold: 1, location: "Racket Rack")
        ]

        let salesOrders = [
            SalesOrder(
                id: "SO-001",
                date: today,
                customerName: "Walk-in Customer",
                items: [
                    OrderLineItem(productCode: "SVC-STRING", productName: "Badminton Stringing Service", quantity: 2, unitPrice: 15),
                    OrderLineItem(productCode: "STR-BG80", productName: "Yonex BG80", quantity: 2, unitPrice: 25)
                ],
                paidAmount: 80,
                status: .paid
            ),
            SalesOrder(
                id: "SO-002",
                date: today,
                customerName: "Club Player",
                items: [
                    OrderLineItem(productCode: "SVC-STRING", productName: "Badminton Stringing Service", quantity: 1, unitPrice: 15),
                    OrderLineItem(productCode: "STR-EX63", productName: "Yonex Exbolt 63", quantity: 1, unitPrice: 27.5)
                ],
                paidAmount: 0,
                status: .unpaid
            ),
            SalesOrder(
                id: "SO-003",
                date: yesterday,
                customerName: "Training Group",
                items: [
                    OrderLineItem(productCode: "STR-BG65", productName: "Yonex BG65", quantity: 5, unitPrice: 25),
                    OrderLineItem(productCode: "SVC-STRING", productName: "Badminton Stringing Service", quantity: 5, unitPrice: 15)
                ],
                paidAmount: 120,
                status: .unpaid
            ),
            SalesOrder(
                id: "SO-004",
                date: twoDaysAgo,
                customerName: "Nagarjun",
                items: [
                    OrderLineItem(productCode: "RKT-LNCAN", productName: "Li-Ning Cannon", quantity: 1, unitPrice: 145),
                    OrderLineItem(productCode: "STR-BG65", productName: "Yonex BG65", quantity: 1, unitPrice: 25)
                ],
                paidAmount: 170,
                status: .paid
            ),
            SalesOrder(
                id: "SO-OLD",
                date: lastMonth,
                customerName: "Old Month Sample",
                items: [
                    OrderLineItem(productCode: "STR-VBS61", productName: "Victor VBS-61", quantity: 2, unitPrice: 25)
                ],
                paidAmount: 50,
                status: .paid
            )
        ]

        let purchaseOrders = [
            PurchaseOrder(
                id: "PO-001",
                date: today,
                supplierName: "Yonex Distributor",
                items: [
                    OrderLineItem(productCode: "STR-BG65", productName: "Yonex BG65", quantity: 10, unitPrice: 14),
                    OrderLineItem(productCode: "STR-BG80", productName: "Yonex BG80", quantity: 10, unitPrice: 15)
                ],
                paidAmount: 160,
                status: .unpaid
            ),
            PurchaseOrder(
                id: "PO-002",
                date: twoDaysAgo,
                supplierName: "Victor Supplier",
                items: [
                    OrderLineItem(productCode: "STR-VBS61", productName: "Victor VBS-61", quantity: 8, unitPrice: 14)
                ],
                paidAmount: 112,
                status: .paid
            )
        ]

        let inventoryMovements = [
            InventoryMovement(id: "IM-001", date: today, type: .purchaseIn, productCode: "STR-BG65", productName: "Yonex BG65", quantityChange: 10, reference: "PO-001"),
            InventoryMovement(id: "IM-002", date: today, type: .salesOut, productCode: "STR-BG80", productName: "Yonex BG80", quantityChange: -2, reference: "SO-001"),
            InventoryMovement(id: "IM-003", date: today, type: .salesOut, productCode: "STR-EX63", productName: "Yonex Exbolt 63", quantityChange: -1, reference: "SO-002"),
            InventoryMovement(id: "IM-004", date: yesterday, type: .salesOut, productCode: "STR-BG65", productName: "Yonex BG65", quantityChange: -5, reference: "SO-003")
        ]

        let moneyRecords = [
            MoneyRecord(id: "MR-001", date: today, direction: .incoming, counterparty: "Walk-in Customer", amount: 80, relatedOrderID: "SO-001", note: "Cash"),
            MoneyRecord(id: "MR-002", date: today, direction: .outgoing, counterparty: "Yonex Distributor", amount: 160, relatedOrderID: "PO-001", note: "Deposit"),
            MoneyRecord(id: "MR-003", date: yesterday, direction: .incoming, counterparty: "Training Group", amount: 120, relatedOrderID: "SO-003", note: "Partial payment")
        ]

        let notices = [
            InformationNotice(id: "INFO-001", title: "Prototype scope", detail: "Current data is mock data for dashboard and workflow testing."),
            InformationNotice(id: "INFO-002", title: "Next data step", detail: "Purchase, sales and inventory can later share one local persistent store.")
        ]

        return BusinessSnapshot(
            products: products,
            inventoryItems: inventoryItems,
            salesOrders: salesOrders,
            purchaseOrders: purchaseOrders,
            inventoryMovements: inventoryMovements,
            moneyRecords: moneyRecords,
            notices: notices
        )
    }
}
