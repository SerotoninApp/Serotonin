import SwiftUI
@main
struct usprebooterApp: App {
    @State var useNewUI: Bool = true
    init() {
        if !FileManager.default.fileExists(atPath: "/var/mobile/boot-happy.jp2") {
            if let bootlogo = Bundle.main.url(forResource: "boot-happy", withExtension: "jp2") {
                try? FileManager.default.copyItem(at: bootlogo, to: URL(fileURLWithPath: "/var/mobile/boot-happy.jp2"))
            }
        }
        
        if !FileManager.default.fileExists(atPath: "/var/mobile/boot-sad.jp2") {
            if let bootlogo = Bundle.main.url(forResource: "boot-sad", withExtension: "jp2") {
                try? FileManager.default.copyItem(at: bootlogo, to: URL(fileURLWithPath: "/var/mobile/boot-sad.jp2"))
            }
        }
    }
    var body: some Scene {
        WindowGroup {
            if useNewUI {
                CoolerContentView(useNewUI: $useNewUI)
                    .preferredColorScheme(.dark)
            } else {
                ContentView(useNewUI: $useNewUI)
            }
        }
    }
}
