import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Act.")
                .foregroundStyle(.white)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    ContentView()
}
