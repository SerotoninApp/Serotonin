import SwiftUI

struct ContentView: View {
    @State var LogItems: [String.SubSequence] = {
            return [""]
        }()
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
            }
            Button("uspreboot") {
                userspaceReboot()
            }
        }
        // thx haxi0
        VStack {
                    ScrollView {
                        ScrollViewReader { scroll in
                            VStack(alignment: .leading) {
                                ForEach(0..<LogItems.count, id: \.self) { LogItem in
                                    Text("\(String(LogItems[LogItem]))")
                                        .textSelection(.enabled)
                                        .font(.custom("Menlo", size: 10))
                                        .foregroundColor(.white)
                                }
                            }
                            .onReceive(NotificationCenter.default.publisher(for: LogStream.shared.reloadNotification)) { obj in
                                DispatchQueue.global(qos: .utility).async {
                                    FetchLog()
                                    scroll.scrollTo(LogItems.count - 1)
                                }
                            }
                        }
                    }
                    .frame(height: 230)
                }
                .frame(width: 253)
                .padding(20)
                .background {
                    Color(.black)
                        .cornerRadius(20)
                        .opacity(0.5)
                }
            }

            private func FetchLog() {
                guard let AttributedText = LogStream.shared.outputString.copy() as? NSAttributedString else {
                    LogItems = ["Error Getting Log!"]
                    return
                }
                LogItems = AttributedText.string.split(separator: "\n")
    }
}

//#Preview {
//    ContentView()
//}
