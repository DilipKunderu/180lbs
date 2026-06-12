import SwiftUI

@main
struct ActApp: App {
    @State private var rootModel: RootModel

    init() {
        #if DEBUG
        // UI tests pass this to walk onboarding from a fresh-install state.
        if CommandLine.arguments.contains("-ActResetLocalStore") {
            LocalStore.removeProductionDatabase()
        }
        #endif
        _rootModel = State(initialValue: RootModel(store: try? LocalStore()))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: rootModel)
        }
    }
}
