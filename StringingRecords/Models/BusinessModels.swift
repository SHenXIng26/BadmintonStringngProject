import Foundation
import SwiftUI

enum BusinessModule: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case stringingRecords
    case inventory
    case stockIn
    case maintenance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            return "经营概览"
        case .stringingRecords:
            return "穿线记录工具"
        case .inventory:
            return "线材库存"
        case .stockIn:
            return "入库记录"
        case .maintenance:
            return "系统维护"
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard:
            return "查看本月收入、线材成本、入库支出和盈亏。"
        case .stringingRecords:
            return "记录球拍穿线、付款、取拍和导入导出。"
        case .inventory:
            return "维护每种线材的成本、库存和低库存提醒。"
        case .stockIn:
            return "记录买线和入库，自动增加线材库存。"
        case .maintenance:
            return "清除库存或入库记录，穿线记录单独保留。"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            return "chart.line.uptrend.xyaxis"
        case .stringingRecords:
            return "list.clipboard"
        case .inventory:
            return "tennis.racket"
        case .stockIn:
            return "tray.and.arrow.down"
        case .maintenance:
            return "gearshape"
        }
    }
}

enum QuickAction: String, CaseIterable, Identifiable {
    case stringingRecords
    case inventory
    case stockIn
    case maintenance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stringingRecords:
            return "穿线记录"
        case .inventory:
            return "线材库存"
        case .stockIn:
            return "新增入库"
        case .maintenance:
            return "系统维护"
        }
    }

    var systemImage: String {
        switch self {
        case .stringingRecords:
            return "plus.rectangle.on.folder"
        case .inventory:
            return "shippingbox.fill"
        case .stockIn:
            return "tray.and.arrow.down.fill"
        case .maintenance:
            return "gearshape.fill"
        }
    }

    var targetModule: BusinessModule {
        switch self {
        case .stringingRecords:
            return .stringingRecords
        case .inventory:
            return .inventory
        case .stockIn:
            return .stockIn
        case .maintenance:
            return .maintenance
        }
    }
}

struct DashboardMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let color: Color
    var destination: DashboardDetailRoute? = nil
}

enum DashboardDetailRoute: String, Hashable {
    case paidIncome
    case stringCost
    case grossProfit
    case stockInExpense
    case netResult
    case completedRecords
    case lowStock
    case unmatchedCost
}

struct BusinessSnapshot: Codable {
    var inventoryItems: [StringInventoryItem]
    var stockInRecords: [StringStockInRecord]
}

struct StringInventoryItem: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var brand: String
    var color: String
    var costPerPack: Double
    var quantity: Int
    var lowStockThreshold: Int
    var note: String

    init(
        id: UUID,
        name: String,
        brand: String,
        color: String,
        costPerPack: Double,
        quantity: Int,
        lowStockThreshold: Int,
        note: String
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.color = color
        self.costPerPack = costPerPack
        self.quantity = quantity
        self.lowStockThreshold = lowStockThreshold
        self.note = note
    }

    var isLowStock: Bool {
        quantity <= lowStockThreshold
    }

    var displayName: String {
        color.businessTrimmed.isEmpty ? name : "\(name) - \(color)"
    }

    var normalizedName: String {
        name.normalizedInventoryKey
    }

    var normalizedColor: String {
        color.normalizedInventoryKey
    }

    var normalizedDisplayName: String {
        displayName.normalizedInventoryKey
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case color
        case costPerPack
        case quantity
        case lowStockThreshold
        case note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        brand = try container.decode(String.self, forKey: .brand)
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? ""
        costPerPack = try container.decode(Double.self, forKey: .costPerPack)
        quantity = try container.decode(Int.self, forKey: .quantity)
        lowStockThreshold = try container.decode(Int.self, forKey: .lowStockThreshold)
        note = try container.decode(String.self, forKey: .note)
    }
}

struct StringStockInRecord: Codable, Identifiable, Hashable {
    let id: String
    var date: Date
    var stringName: String
    var brand: String
    var color: String
    var quantity: Int
    var costPerPack: Double
    var note: String

    init(
        id: String,
        date: Date,
        stringName: String,
        brand: String,
        color: String,
        quantity: Int,
        costPerPack: Double,
        note: String
    ) {
        self.id = id
        self.date = date
        self.stringName = stringName
        self.brand = brand
        self.color = color
        self.quantity = quantity
        self.costPerPack = costPerPack
        self.note = note
    }

    var totalCost: Double {
        Double(quantity) * costPerPack
    }

    var displayName: String {
        color.businessTrimmed.isEmpty ? stringName : "\(stringName) - \(color)"
    }

    var normalizedStringName: String {
        stringName.normalizedInventoryKey
    }

    var normalizedColor: String {
        color.normalizedInventoryKey
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case stringName
        case brand
        case color
        case quantity
        case costPerPack
        case note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        stringName = try container.decode(String.self, forKey: .stringName)
        brand = try container.decode(String.self, forKey: .brand)
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? ""
        quantity = try container.decode(Int.self, forKey: .quantity)
        costPerPack = try container.decode(Double.self, forKey: .costPerPack)
        note = try container.decode(String.self, forKey: .note)
    }
}

struct StringInventoryBackup: Codable {
    let version: Int
    let exportedAt: Date
    let items: [StringInventoryItem]
}

struct ProfitSummary {
    let monthTitle: String
    let totalRevenue: Double
    let stringUsageCost: Double
    let grossProfit: Double
    let stockInExpense: Double
    let netCashResult: Double
    let monthlyRecordCount: Int
    let completedRecordCount: Int
    let unmatchedCostCount: Int
    let lowStockCount: Int

    var isProfitable: Bool {
        netCashResult >= 0
    }
}

struct ProfitRecordRow: Identifiable, Hashable {
    let id: String
    let recordID: String
    let date: Date
    let customerName: String
    let racketModel: String
    let stringName: String
    let revenue: Double
    let stringCost: Double
    let grossProfit: Double
    let hasMatchedCost: Bool
}

struct StringInventoryItemDraft: Equatable {
    var name = ""
    var brand = ""
    var color = ""
    var costPerPack = 0.0
    var quantity = 0
    var lowStockThreshold = 0
    var note = ""

    init() {}

    init(item: StringInventoryItem) {
        name = item.name
        brand = item.brand
        color = item.color
        costPerPack = item.costPerPack
        quantity = item.quantity
        lowStockThreshold = item.lowStockThreshold
        note = item.note
    }

    var normalizedName: String {
        name.normalizedInventoryKey
    }

    var validationMessage: String? {
        if normalizedName.isEmpty {
            return "请输入线材名称。"
        }

        if costPerPack < 0 {
            return "每包成本不能为负数。"
        }

        if quantity < 0 {
            return "库存数量不能为负数。"
        }

        if lowStockThreshold < 0 {
            return "低库存提醒数量不能为负数。"
        }

        return nil
    }

    func makeItem(id: UUID = UUID()) -> StringInventoryItem {
        StringInventoryItem(
            id: id,
            name: name.businessTrimmed,
            brand: brand.businessTrimmed,
            color: color.businessTrimmed,
            costPerPack: costPerPack,
            quantity: quantity,
            lowStockThreshold: lowStockThreshold,
            note: note.businessTrimmed
        )
    }
}

struct StringStockInDraft: Equatable {
    var date = Date()
    var stringName = ""
    var brand = ""
    var color = ""
    var quantity = 1
    var costPerPack = 0.0
    var note = ""

    init() {}

    init(item: StringInventoryItem) {
        stringName = item.name
        brand = item.brand
        color = item.color
        costPerPack = item.costPerPack
    }

    var normalizedStringName: String {
        stringName.normalizedInventoryKey
    }

    var totalCost: Double {
        Double(quantity) * costPerPack
    }

    var validationMessage: String? {
        if normalizedStringName.isEmpty {
            return "请输入线材名称。"
        }

        if quantity <= 0 {
            return "入库数量必须大于 0。"
        }

        if costPerPack < 0 {
            return "每包成本不能为负数。"
        }

        return nil
    }

    func makeRecord(id: String) -> StringStockInRecord {
        StringStockInRecord(
            id: id,
            date: date,
            stringName: stringName.businessTrimmed,
            brand: brand.businessTrimmed,
            color: color.businessTrimmed,
            quantity: quantity,
            costPerPack: costPerPack,
            note: note.businessTrimmed
        )
    }
}

extension String {
    var businessTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedInventoryKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}
