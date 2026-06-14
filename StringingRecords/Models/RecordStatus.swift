import SwiftUI

enum WorkStatus: String, CaseIterable, Codable, Identifiable {
    case pending
    case completed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pending:
            return "Pending"
        case .completed:
            return "Completed"
        }
    }

    var actionLabel: String {
        switch self {
        case .pending:
            return "Mark Completed"
        case .completed:
            return "Mark Pending"
        }
    }

    var systemImage: String {
        switch self {
        case .pending:
            return "clock"
        case .completed:
            return "checkmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .pending:
            return .orange
        case .completed:
            return .green
        }
    }
}

enum PaymentStatus: String, CaseIterable, Codable, Identifiable {
    case unpaid
    case paid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unpaid:
            return "Unpaid"
        case .paid:
            return "Paid"
        }
    }

    var actionLabel: String {
        switch self {
        case .unpaid:
            return "Mark Paid"
        case .paid:
            return "Mark Unpaid"
        }
    }

    var systemImage: String {
        switch self {
        case .unpaid:
            return "dollarsign.circle"
        case .paid:
            return "checkmark.seal"
        }
    }

    var tint: Color {
        switch self {
        case .unpaid:
            return .gray
        case .paid:
            return .green
        }
    }
}

enum PickupStatus: String, CaseIterable, Codable, Identifiable {
    case notPickedUp = "not_picked_up"
    case pickedUp = "picked_up"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notPickedUp:
            return "Not picked up"
        case .pickedUp:
            return "Picked up"
        }
    }

    var actionLabel: String {
        switch self {
        case .notPickedUp:
            return "Mark Picked Up"
        case .pickedUp:
            return "Mark Not Picked"
        }
    }

    var systemImage: String {
        switch self {
        case .notPickedUp:
            return "bag"
        case .pickedUp:
            return "bag.fill"
        }
    }

    var tint: Color {
        switch self {
        case .notPickedUp:
            return .blue
        case .pickedUp:
            return .green
        }
    }
}
