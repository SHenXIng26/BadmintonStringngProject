import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var businessStore = BusinessStore()
    @State private var selectedModule = BusinessModule.dashboard
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
            List {
                ForEach(BusinessModule.allCases) { module in
                    Button {
                        selectedModule = module
                    } label: {
                        HStack {
                            Label(module.title, systemImage: module.systemImage)

                            Spacer()

                            if selectedModule == module {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        selectedModule == module
                        ? Color.accentColor.opacity(0.12)
                        : Color.clear
                    )
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Stringing Ops")
        } detail: {
            NavigationStack {
                BusinessModuleView(
                    module: selectedModule,
                    onNavigate: { selectedModule = $0 }
                )
                .id(selectedModule)
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
            case .inventory:
                InventoryManagementView()
            case .stockIn:
                StockInRecordsView()
            case .maintenance:
                SystemMaintenanceView()
            }
        }
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
