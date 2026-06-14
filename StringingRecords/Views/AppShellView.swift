import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var businessStore = BusinessStore()
    @State private var selectedModule: BusinessModule? = .dashboard
    @State private var compactPath: [BusinessModule] = []

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                sidebarNavigation
            } else {
                compactNavigation
            }
        }
        .environmentObject(businessStore)
    }

    private var compactNavigation: some View {
        NavigationStack(path: $compactPath) {
            List(BusinessModule.allCases) { module in
                NavigationLink {
                    BusinessModuleView(
                        module: module,
                        onNavigate: { compactPath.append($0) }
                    )
                } label: {
                    Label(module.title, systemImage: module.systemImage)
                }
            }
            .navigationTitle("Stringing Ops")
            .navigationDestination(for: BusinessModule.self) { module in
                BusinessModuleView(
                    module: module,
                    onNavigate: { compactPath.append($0) }
                )
            }
        }
    }

    private var sidebarNavigation: some View {
        NavigationSplitView {
            List(BusinessModule.allCases, selection: $selectedModule) { module in
                Label(module.title, systemImage: module.systemImage)
                    .tag(Optional(module))
            }
            .listStyle(.sidebar)
            .navigationTitle("Stringing Ops")
        } detail: {
            NavigationStack {
                BusinessModuleView(
                    module: selectedModule ?? .dashboard,
                    onNavigate: { selectedModule = $0 }
                )
            }
        }
    }
}

struct BusinessModuleView: View {
    let module: BusinessModule
    let onNavigate: (BusinessModule) -> Void

    var body: some View {
        Group {
            switch module {
            case .dashboard:
                DashboardView(onNavigate: onNavigate)
            case .stringingRecords:
                StringingRecordsView()
            case .purchase:
                PurchaseManagementView()
            case .sales:
                SalesManagementView()
            case .inventory:
                InventoryManagementView()
            case .cashflow:
                CashflowManagementView()
            case .information:
                InformationCenterView()
            case .maintenance:
                SystemMaintenanceView()
            }
        }
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
