import SwiftUI
@main
struct usprebooterApp: App {
    @State var useNewUI: Bool = true
    var body: some Scene {
        WindowGroup {
            if useNewUI {
                CoolerContentView(useNewUI: $useNewUI)
            } else {
                ContentView(useNewUI: $useNewUI)
            }
        }
    }
}
