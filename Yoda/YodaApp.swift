import SwiftUI

@main
struct YodaApp: App {
    var body: some Scene {
        WindowGroup("yoda") {
            WebView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 1100, height: 700)
        .windowResizability(.contentMinSize)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
