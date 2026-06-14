import Foundation
import SwiftUI

enum BusinessModule: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case stringingRecords
    case purchase
    case sales
    case inventory
    case cashflow
    case information
    case maintenance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            return "经营驾驶舱"
        case .stringingRecords:
            return "穿线记录工具"
        case .purchase:
            return "进货管理"
        case .sales:
            return "销售管理"
        case .inventory:
            return "库存管理"
        case .cashflow:
            return "钱流管理"
        case .information:
            return "信息中心"
        case .maintenance:
            return "系统维护"
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard:
            return "快速查看销售、库存、应收应付和经营动向。"
        case .stringingRecords:
            return "记录球拍穿线、付款、取拍和导入导出。"
        case .purchase:
            return "管理供应商采购、入库和应付款。"
        case .sales:
            return "管理穿线服务、商品售卖和销售出库。"
        case .inventory:
            return "查看库存数量、低库存预警和库存流水。"
        case .cashflow:
            return "跟踪收款、付款、应收和应付。"
        case .information:
            return "维护商品、供应商、客户等基础信息。"
        case .maintenance:
            return "处理数据备份、系统设置和运营参数。"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            return "gauge.with.dots.needle.bottom.50percent"
        case .stringingRecords:
            return "list.clipboard"
        case .purchase:
            return "tray.and.arrow.down"
        case .sales:
            return "cart"
        case .inventory:
            return "shippingbox"
        case .cashflow:
            return "creditcard"
        case .information:
            return "info.circle"
        case .maintenance:
            return "gearshape"
        }
    }
}

enum QuickAction: String, CaseIterable, Identifiable {
    case salesOut
    case purchaseIn
    case inventoryStatus
    case lowStock
    case receivePayment
    case makePayment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .salesOut:
            return "销售出库"
        case .purchaseIn:
            return "采购入库"
        case .inventoryStatus:
            return "库存状况"
        case .lowStock:
            return "低库存预警"
        case .receivePayment:
            return "收款登记"
        case .makePayment:
            return "付款登记"
        }
    }

    var systemImage: String {
        switch self {
        case .salesOut:
            return "cart.badge.minus"
        case .purchaseIn:
            return "tray.and.arrow.down.fill"
        case .inventoryStatus:
            return "shippingbox.fill"
        case .lowStock:
            return "exclamationmark.triangle.fill"
        case .receivePayment:
            return "banknote.fill"
        case .makePayment:
            return "creditcard.fill"
        }
    }

    var targetModule: BusinessModule {
        switch self {
        case .salesOut:
            return .sales
        case .purchaseIn:
            return .purchase
        case .inventoryStatus, .lowStock:
            return .inventory
        case .receivePayment, .makePayment:
            return .cashflow
        }
    }
}

enum ProductCategory: String, CaseIterable, Codable, Identifiable {
    case string = "羽毛球线"
    case racket = "羽毛球拍"
    case service = "穿线服务"
    case accessory = "配件"

    var id: String { rawValue }
}

enum BusinessOrderStatus: String, Codable {
    case draft = "草稿"
    case completed = "已完成"
    case unpaid = "未结清"
    case paid = "已结清"
}

enum InventoryMovementType: String, Codable {
    case purchaseIn = "采购入库"
    case salesOut = "销售出库"
    case adjustment = "库存调整"
}

enum MoneyDirection: String, Codable {
    case incoming = "收款"
    case outgoing = "付款"
}

struct DashboardMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let color: Color
}

struct BusinessSnapshot: Codable {
    var products: [BusinessProduct]
    var inventoryItems: [InventoryItem]
    var salesOrders: [SalesOrder]
    var purchaseOrders: [PurchaseOrder]
    var inventoryMovements: [InventoryMovement]
    var moneyRecords: [MoneyRecord]
    var notices: [InformationNotice]
}

struct BusinessProduct: Codable, Identifiable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    let category: ProductCategory
    let brand: String
    let salePrice: Double
    let costPrice: Double
}

struct InventoryItem: Codable, Identifiable, Hashable {
    var id: String { product.code }
    let product: BusinessProduct
    var quantity: Int
    var lowStockThreshold: Int
    var location: String

    var isLowStock: Bool {
        quantity <= lowStockThreshold
    }
}

struct SalesOrder: Codable, Identifiable, Hashable {
    let id: String
    let date: Date
    let customerName: String
    let items: [OrderLineItem]
    let paidAmount: Double
    let status: BusinessOrderStatus

    var totalAmount: Double {
        items.reduce(0) { $0 + $1.lineTotal }
    }

    var receivableAmount: Double {
        max(totalAmount - paidAmount, 0)
    }
}

struct PurchaseOrder: Codable, Identifiable, Hashable {
    let id: String
    let date: Date
    let supplierName: String
    let items: [OrderLineItem]
    let paidAmount: Double
    let status: BusinessOrderStatus

    var totalAmount: Double {
        items.reduce(0) { $0 + $1.lineTotal }
    }

    var payableAmount: Double {
        max(totalAmount - paidAmount, 0)
    }
}

struct OrderLineItem: Codable, Identifiable, Hashable {
    var id = UUID()
    let productCode: String
    let productName: String
    let quantity: Int
    let unitPrice: Double

    var lineTotal: Double {
        Double(quantity) * unitPrice
    }
}

struct InventoryMovement: Codable, Identifiable, Hashable {
    let id: String
    let date: Date
    let type: InventoryMovementType
    let productCode: String
    let productName: String
    let quantityChange: Int
    let reference: String
}

struct MoneyRecord: Codable, Identifiable, Hashable {
    let id: String
    let date: Date
    let direction: MoneyDirection
    let counterparty: String
    let amount: Double
    let relatedOrderID: String
    let note: String
}

struct HotProduct: Identifiable, Hashable {
    var id: String { productCode }
    let rank: Int
    let productCode: String
    let productName: String
    let quantity: Int
    let salesAmount: Double
}

struct InformationNotice: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

struct InventoryItemDraft: Equatable {
    var code = ""
    var name = ""
    var category = ProductCategory.string
    var brand = ""
    var salePrice = 0.0
    var costPrice = 0.0
    var quantity = 0
    var lowStockThreshold = 0
    var location = ""

    init() {}

    init(item: InventoryItem) {
        code = item.product.code
        name = item.product.name
        category = item.product.category
        brand = item.product.brand
        salePrice = item.product.salePrice
        costPrice = item.product.costPrice
        quantity = item.quantity
        lowStockThreshold = item.lowStockThreshold
        location = item.location
    }

    var normalizedCode: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var validationMessage: String? {
        if normalizedCode.isEmpty {
            return "Product code is required."
        }

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Product name is required."
        }

        if salePrice < 0 || costPrice < 0 {
            return "Prices cannot be negative."
        }

        if quantity < 0 {
            return "Quantity cannot be negative."
        }

        if lowStockThreshold < 0 {
            return "Low stock threshold cannot be negative."
        }

        return nil
    }

    func makeProduct() -> BusinessProduct {
        BusinessProduct(
            code: normalizedCode,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            salePrice: salePrice,
            costPrice: costPrice
        )
    }

    func makeInventoryItem() -> InventoryItem {
        InventoryItem(
            product: makeProduct(),
            quantity: quantity,
            lowStockThreshold: lowStockThreshold,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
