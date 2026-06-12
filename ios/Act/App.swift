import SwiftUI

@main
struct ActApp: App {
    @State private var rootModel = RootModel(store: try? LocalStore())

    var body: some Scene {
        WindowGroup {
            RootView(model: rootModel)
        }
    }
}
