import SwiftUI

struct ContentView: View {
    @State var LogItems: [String.SubSequence] = [""]
    private let puaf_method_options = ["physpuppet", "smith", "landa"]
    @AppStorage("puaf_method") private var puaf_method = 2
    private let puaf_pages_options = [16, 32, 64, 128, 256, 512, 1024, 2048, 3072, 3584, 4096];
    private var headroom_options = [16, 128, 256, 512, 768, 1024, 2048, 4096, 8192, 16384, 65536, 131072, 262144];
    private let kwrite_method_options = ["kqueue_workloop_ctl", "sem_open"];
    @AppStorage("kwrite_method") private var kwrite_method = 1;
    private let kread_method_options = ["dup"," sem_open"];
    @AppStorage("kread_method") private var kread_method = 1;
    @AppStorage("puaf_pages_index") private var puaf_pages_index = 8;
    @AppStorage("headroom_index") private var headroom_index = 3;
    @AppStorage("use_hogger") var use_hogger = true;
    @AppStorage("isBeta") var isBeta = false;
    @AppStorage("headroom") var staticHeadroomMB = 384;
    @AppStorage("pages") var pUaFPages: Double = 3072.0
    @Binding var useNewUI: Bool;
    var body: some View {
        // thx haxi0
        VStack {
            List {
                Picker("Headroom:", selection: $headroom_index) {
                    ForEach(0..<headroom_options.count, id: \.self) {
                        Text(String(headroom_options[$0]))
                    }
                }
                .onChange(of: headroom_index) {sel in
                    staticHeadroomMB = headroom_options[sel]
                }
                Picker("puaf pages:", selection: $puaf_pages_index) {
                    ForEach(0..<puaf_pages_options.count, id: \.self) {
                        Text(String(puaf_pages_options[$0]))
                    }
                }
                .onChange(of: puaf_pages_index) {sel in
                    pUaFPages = Double(puaf_pages_options[sel])
                }
                Picker("puaf method:", selection: $puaf_method) {
                    ForEach(0..<puaf_method_options.count, id: \.self) {
                        Text(String(puaf_method_options[$0]))
                    }
                }
                Picker("kread method:", selection: $kread_method) {
                    ForEach(0..<kread_method_options.count, id: \.self) {
                        Text(String(kread_method_options[$0]))
                    }
                }
                Picker("kwrite method:", selection: $kwrite_method) {
                    ForEach(0..<kwrite_method_options.count, id: \.self) {
                        Text(String(kwrite_method_options[$0]))
                    }
                }
                Toggle("Use memory hogger", systemImage: "memorychip", isOn: $use_hogger).tint(.accentColor)
                Toggle("iOS Beta", systemImage: "ladybug", isOn: $isBeta).tint(.accentColor)
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
        }
        Text("");
    }
    private func FetchLog() {
        guard let AttributedText = LogStream.shared.outputString.copy() as? NSAttributedString else {
            LogItems = ["Error Getting Log!"]
            return
        }
        LogItems = AttributedText.string.split(separator: "\n")
    }
    init(useNewUI: Binding<Bool>) {
        self._useNewUI = useNewUI;
        let memSizeMB = getPhysicalMemorySize() / 1048576
        var new_headroom_options = headroom_options
        for option in headroom_options {
            if (option > memSizeMB) {
                new_headroom_options = new_headroom_options.filter { $0 != option }
            }
        }
        headroom_options = new_headroom_options;
    }

}

// #Preview {
//    ContentView()
// }
