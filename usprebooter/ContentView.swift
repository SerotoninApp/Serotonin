import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack {
            Button("kfdgo") {
                do_kopen(2048, 1, 2, 2)
                do_fun()
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
