import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
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
        
        let viewController = MainTabBarController()
        let navController = UINavigationController(rootViewController: viewController)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        return true
    }

}
