import SwiftUI
@main
struct usprebooterApp: App {
    @State var useNewUI: Bool = true
    @AppStorage("theme") var theme: Int = 0
    init() {
        if !FileManager.default.fileExists(atPath: "/var/mobile/Serotonin.jp2") {
            if let bootlogo = Bundle.main.url(forResource: "Serotonin", withExtension: "jp2") {
                try? FileManager.default.copyItem(at: bootlogo, to: URL(fileURLWithPath: "/var/mobile/Serotonin.jp2"))
            }
        }
        
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
                    .preferredColorScheme(theme == 1 ? .none : .dark)
            } else {
                ContentView(useNewUI: $useNewUI)
            }
        }
    }
}
