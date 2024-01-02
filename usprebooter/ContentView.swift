import SwiftUI

struct ContentView: View {
    @State var LogItems: [String.SubSequence] = {
            return [""]
        }()
    @State var staticHeadroomMB = 384.0;
    @State var pUaFPages = 3072.0;
    var body: some View {
        // thx haxi0
        VStack {
            HStack {
                Button("do the thing!") {
                    DispatchQueue.main.async {
                        do_kopen(UInt64(pUaFPages), 1, 1, 1, Int(staticHeadroomMB), true);
                        fix_exploit()
                        go()
                        do_kclose()
                    }
                }
                Button("reboot userspace") {
                    userspaceReboot()
                }
            }
            let memSizeMB = getPhysicalMemorySize() / 1048576;
            HStack {
                Text("Headroom: \(Int(staticHeadroomMB))")
                Slider(value: $staticHeadroomMB, in: 0...Double(memSizeMB), step: 128.0);
            }
            HStack {
                Text("puaf pages: \(Int(pUaFPages))")
                Slider(value: $pUaFPages, in: 16...4096, step: 16.0);
            }
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
