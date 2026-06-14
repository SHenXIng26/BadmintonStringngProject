import SwiftUI

@main
struct StringingRecordsApp: App {
    @StateObject private var recordStore = RecordStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recordStore)
        }
    }
}
