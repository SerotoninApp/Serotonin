import SwiftUI

struct ContentView: View {
    @State var LogItems: [String.SubSequence] = [""]
    private let puaf_method_options = ["physpuppet", "smith         ", "landa         "]
    @AppStorage("puaf_method") private var puaf_method = 2.0
    private let kwrite_method_options = ["kqueue_\nworkloop_ctl", "sem_open"];
    @AppStorage("kwrite_method") private var kwrite_method = 1.0;
    private let kread_method_options = ["dup        "," sem_open"];
    @AppStorage("kread_method") private var kread_method = 1.0;
    @AppStorage("use_hogger") var use_hogger = true;
    @AppStorage("isBeta") var isBeta = false;
    @AppStorage("headroom") var staticHeadroomMB: Double = 384.0
    @AppStorage("pages") var pUaFPages: Double = 3072.0
    @Binding var useNewUI: Bool
    var body: some View {
        // thx haxi0
        VStack {
            List {
                let memSizeMB = getPhysicalMemorySize() / 1048576
                HStack {
                    Text("Headroom: \(Int(staticHeadroomMB))")
                    Slider(value: $staticHeadroomMB, in: 0...Double(memSizeMB), step: 256.0)
                }
                HStack {
                    Text("puaf pages: \(Int(pUaFPages))")
                    Slider(value: $pUaFPages, in: 16...4096, step: 16.0)
                }
                HStack {
                    Text("puaf method: \(puaf_method_options[Int(puaf_method)])").layoutPriority(1.0)
                    Slider(value: $puaf_method, in: 0...Double(puaf_method_options.count-1), step: 1.0).layoutPriority(0.25)
                }
                HStack {
                    Text("kread method: \(kread_method_options[Int(kread_method)])").layoutPriority(1.0)
                    Slider(value: $kread_method, in: 0...Double(kread_method_options.count-1), step: 1.0).layoutPriority(0.25)
                }
                HStack {
                    Text("kwrite method: \(kwrite_method_options[Int(kwrite_method)])").layoutPriority(1.0)
                    Slider(value: $kwrite_method, in: 0...Double(kwrite_method_options.count-1), step: 1.0).layoutPriority(0.7)
                }
                Toggle("Use memory hogger", systemImage: "memorychip", isOn: $use_hogger);
                Toggle("iOS Beta", systemImage: "ladybug", isOn: $isBeta);
            }
            ScrollView {
                ScrollViewReader { scroll in
                    VStack(alignment: .leading) {
                        ForEach(0 ..< LogItems.count, id: \.self) { LogItem in
                            Text("\(String(LogItems[LogItem]))")
                                .textSelection(.enabled)
                                .font(.custom("Menlo", size: 9))
                                .foregroundColor(.white)
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: LogStream.shared.reloadNotification)) { _ in
                        DispatchQueue.global(qos: .utility).async {
                            FetchLog()
                            scroll.scrollTo(LogItems.count - 1)
                        }
                    }
                }
            }
        }
        .background {
            Color(.black)
                .cornerRadius(20)
                .opacity(0.5)
        }
        HStack {
            Button("do the thing!") {
                DispatchQueue.main.async {
                    do_kopen(UInt64(pUaFPages), UInt64(puaf_method), UInt64(kread_method), UInt64(kwrite_method), Int(staticHeadroomMB), use_hogger)
                    go(isBeta, "install")
                    do_kclose()
                }
            }.padding(16)
            Button("reboot userspace") {
                userspaceReboot()
            }
        }
        Button("Back to new UI", systemImage: "switch.2") {
            withAnimation(fancyAnimation) {
                useNewUI.toggle()
            }
        }.padding(16);
        Text("");
    }
    private func FetchLog() {
        guard let AttributedText = LogStream.shared.outputString.copy() as? NSAttributedString else {
            LogItems = ["Error Getting Log!"]
            return
        }
        LogItems = AttributedText.string.split(separator: "\n")
    }
}

// #Preview {
//    ContentView()
// }
