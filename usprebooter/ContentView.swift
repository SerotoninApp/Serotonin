import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack {
            Button("kfdgo") {
                do_kopen(2048, 1, 1, 1)
                fix_exploit()
                fuck2()
                do_kclose()
            }
            Button("go") {
                fuck()
//                copyLaunchd()
//                userspaceReboot()
            }
            Button("uspreboot") {
//                fuck()
//                copyLaunchd()
                userspaceReboot()
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
