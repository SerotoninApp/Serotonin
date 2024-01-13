// bomberfish
// ContentView.swift – AppLogDemo
// created on 2023-12-26

//import FluidGradient
import SwiftUI
//import SwiftUIBackports
//

let fancyAnimation: SwiftUI.Animation = .snappy(duration: 0.35, extraBounce: 0.085) // smoooooth operaaatooor

/// An actually good UI, courtesy of ya boi BomberFish.
struct CoolerContentView: View {
    @Binding var useNewUI: Bool
    var pipe = Pipe()
//    @Binding var triggerRespring: Bool // dont use this when porting this ui to your jailbreak (unless you respring in the same way)
    @State var logItems: [String] = []
    @State var progress: Double = 0.0
    @State var isRunning = false
    @State var finished = false
    @State var settingsOpen = false
    @State var color: Color = .init("accent", bundle: Bundle.main)
    @AppStorage("accent") var accentColor: String = ""
    @AppStorage("swag") var swag = true
    @State var showingGradient = false
    @State var blurScreen = false
    @AppStorage("cr") var customReboot = true
    @AppStorage("verbose") var verboseBoot = false
    @AppStorage("unthreded") var untether = true
    @AppStorage("hide") var hide = false
    @AppStorage("loadd") var loadLaunch = false
    @AppStorage("showStdout") var showStdout = true
    @AppStorage("isBeta") var isBeta = false
    @State var reinstall = false
    @State var resetfs = false
    
    @State var shouldShowLog = true

    @AppStorage("headroom") var staticHeadroomMB: Double = 512.0
    @AppStorage("pages") var pUaFPages: Double = 3072.0
    @AppStorage("theme") var theme: Int = 0

    public func openConsolePipe() {
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor,
             STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor,
             STDERR_FILENO)
        // listening on the readabilityHandler
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            let str = String(data: data, encoding: .ascii) ?? "[i] <Non-ascii data of size\(data.count)>\n"
            DispatchQueue.main.async {
                withAnimation(fancyAnimation) {
                    logItems.append(str)
                }
            }
        }
    }

    @ViewBuilder
    var settings: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        NavigationLink(destination: CreditsView(), label: {
                            HStack {
                                Group {
                                    Label("Credits", systemImage: "heart")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }.padding(15)
                            }
                            .background(.regularMaterial)
                        })
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    Divider()
                        .padding(.vertical, 8)
                    Label("Jailbreak", systemImage: "lock.open")
                        .padding(.leading, 17.5)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            HStack {
                                Label("PUAF Pages", systemImage: "doc")
                                Spacer()
                                Picker("PUAF Pages", systemImage: "doc", selection: $pUaFPages) {
                                    Text("16").tag(16.0)
                                    Text("32").tag(32.0)
                                    Text("64").tag(64.0)
                                    Text("128").tag(128.0)
                                    Text("256").tag(256.0)
                                    Text("512").tag(512.0)
                                    Text("1024").tag(1024.0)
                                    Text("2048").tag(2048.0)
                                    Text("3072").tag(3072.0)
                                    Text("4096").tag(4096.0)
                                    Text("65536").tag(65536.0)
                                }
                                .labelsHidden()
                            }
                            let memSizeMB = getPhysicalMemorySize() / 1048576
                            HStack {
                                Label("Static Headroom", systemImage: "memorychip")
                                Spacer()
                                Slider(value: $staticHeadroomMB, in: 0...Double(memSizeMB), step: 128.0, label: {})
                                Text("\(Int(staticHeadroomMB)) MB")
                                    .font(.caption.monospacedDigit())
                            }
//                            Group {
//                                Toggle("Custom Reboot Logo", systemImage: "applelogo", isOn: $customReboot) // soon
//                                Toggle("Load Launch Daemons", systemImage: "restart.circle", isOn: $loadLaunch)
//                            }
//                            .disabled(true)
                            Toggle("Beta iOS",systemImage: "star",isOn: $isBeta)
                            Toggle("Verbose Boot", systemImage: "ladybug", isOn: $verboseBoot)
                                .onChange(of: verboseBoot) {_ in
                                    if verboseBoot {
                                        if !(FileManager.default.createFile(atPath: "/var/mobile/.serotonin_verbose", contents: nil)) {
                                            verboseBoot = false
                                        }
                                    } else {
                                        do {
                                            try FileManager.default.removeItem(atPath: "/var/mobile/.serotonin_verbose")
                                        } catch {
                                            verboseBoot = true
                                        }
                                    }
                                }
//                            Group {
//                                Toggle("Enable untether", systemImage: "slash.circle", isOn: $untether)
//                                Toggle("Hide environment", systemImage: "eye.slash", isOn: $hide)
//                            }
//                            .disabled(true)
                            Toggle("Show output (recommended)", systemImage: "terminal", isOn: $showStdout)
                        }
                        .toggleStyle(SwitchToggleStyle())
                        .padding(15)
                        .background(.regularMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(isRunning || finished)
                    Divider()
                        .padding(.vertical, 8)
                    Label("Appearance", systemImage: "paintpalette")
                        .padding(.leading, 17.5)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            HStack {
                                Label("Accent Color", systemImage: "paintpalette")
                                Spacer()
                                ColorPicker("Accent Color", selection: $color)
                                    .onChange(of: color) {_ in
                                        accentColor = updateCardColorInAppStorage(color: color)
                                    }
                                    .labelsHidden()
                                Button("", systemImage: "arrow.counterclockwise") {
                                    withAnimation(fancyAnimation) {
                                        color = .accentColor
                                        accentColor = updateCardColorInAppStorage(color: .init("accent", bundle: Bundle.main))
                                    }
                                }
                                .tint(color)
                                .foregroundColor(color)
                            }
                            Toggle("Swag Mode", systemImage: "flame", isOn: $swag)
                            if #available(iOS 16.0, *) {
                                Picker("Theme", selection: $theme, content: {
                                    Text("Default")
                                        .tag(0)
                                    Text("Unveil")
                                        .tag(1)
                                })
                                .pickerStyle(.navigationLink)
                                .padding(5)
                            } else {
                                Picker("Theme", selection: $theme, content: {
                                    Text("Default")
                                        .tag(0)
                                    Text("Unveil")
                                        .tag(1)
                                })
                                .padding(5)
                            }
                        }
                        .padding(15)

                        .background(.regularMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    Label("Disable Swag Mode if the app seems sluggish.", systemImage: "info.circle")
                        .padding(.leading, 17.5)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "xmark") {
                        settingsOpen = false
                        withAnimation(fancyAnimation) {
                            blurScreen = false
                        }
                    }
                    .font(.system(size: 15))
                    .tint(Color(UIColor.label))
                }
            }
        }
    }

    @ViewBuilder
    var sheet: some View {
        if #available(iOS 16.0, *) {
            if #available(iOS 16.4, *) {
                settings
                    .presentationDetents([.medium, .large])
                    .presentationBackground(.regularMaterial)
            } else {
                settings
                    .presentationDetents([.medium, .large])
                    .background(.regularMaterial)
            }
        } else {
            settings
                .background(.regularMaterial)
//                .backport.presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                ZStack {
                    Color.black
                        .ignoresSafeArea(.all)
                    if theme == 1 {
                        Image("uncoverPissEditionReal")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea(.all)
                    }
                    
                    if showingGradient && theme != 1 {
                        FluidGradient(blobs: [color, color, color, color, color, color, color, color, color], speed: 0.35, blur: 0.7) // swag alert #420blazeit
                            .ignoresSafeArea(.all)
                    } else if theme == 1 {
                        Color(UIColor.systemBackground)
                            .opacity(0.9)
                            .ignoresSafeArea(.all)
                    }
                    
                    if theme != 1 {
                        Rectangle()
                            .fill(.clear)
                            .background(.black.opacity(0.8))
                            .ignoresSafeArea(.all)
                    }
                    
                    VStack(spacing: 15) {
                        VStack(alignment: .leading) {
                            Text("Serotonin") // apex?????
                                .multilineTextAlignment(.leading)
                                .font(theme != 1 ? .system(.largeTitle, design: .rounded).weight(.bold) : .custom("PaintingWithChocolate", size: 34.0))
                            Text("Semi-jailbreak for iOS 16.0-16.6.1")
                        }
                        .foregroundColor(.primary)
                        .padding(.top, geo.size.height / 50)
                        .padding(.leading, 5)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        Spacer()
                        if !isRunning && !finished {
                            ZStack {
                                Rectangle()
                                    .fill(.clear)
                                    .blur(radius: 16)
                                    .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
                                VStack {
                                    Toggle("Reinstall bootstrap", isOn: $reinstall)
                                        .disabled(true)
                                        .onChange(of: reinstall) { _ in
                                            if reinstall {
                                                withAnimation(fancyAnimation) {
                                                    resetfs = false
                                                }
                                            }
                                        }
                                    Divider()
                                    Toggle("Restore system", isOn: $resetfs)
                                        .disabled(true)
                                        .onChange(of: resetfs) { _ in
                                            if resetfs {
                                                withAnimation(fancyAnimation) {
                                                    reinstall = false
                                                }
                                            }
                                        }
                                    Divider()
                                    Button("More Settings", systemImage: "gear") {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 200)
                                        settingsOpen.toggle()
                                        withAnimation(fancyAnimation) {
                                            blurScreen = true
                                        }
                                    }
                                    .padding(.top, 5)
                                }
                                .padding()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .frame(width: geo.size.width / 1.5, height: geo.size.height / 6.5)
                            .padding(.vertical)
                        }

                        ZStack {
                            Rectangle()
                                .fill(.clear)
                                .blur(radius: 16)
                                .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
                            ScrollView {
                                LazyVStack(alignment: .leading) {
                                    ScrollViewReader { value in
                                        ForEach(logItems, id: \.self) { log in // caveat: no two log messages can be the same. can be solved by custom struct with a uuid, but i cba to do that rn
                                            Text(log)
                                                .id(log)
                                                .multilineTextAlignment(.leading)
                                                .frame(width: geo.size.width - 50, alignment: .leading)
                                        }
                                        .font(.system(.body, design: .monospaced))
                                        .multilineTextAlignment(.leading)
                                        .onChange(of: logItems.count) { new in
                                            value.scrollTo(logItems[new - 1])
                                        }
                                    }
                                }
                                .padding(.bottom, 15)
                                .padding()
                            }
                        }
                        .frame(height: logItems.isEmpty ? 0 : geo.size.height / 2.5, alignment: .leading)
                        //                    .background(.ultraThinMaterial)

                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .onChange(of: progress) { p in
                            if p == 1.0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                    withAnimation(fancyAnimation) {
                                        isRunning = false
                                        finished = true
                                    }
                                }
                            }
                        }

                        HStack {
                            if isRunning {
                                ProgressView(value: progress)
                                    .tint(progress == 1.0 ? .green : color)
                                Text(progress == 1.0 ? "Complete" : "\(Int(progress * 100))%")
                                    .font(.caption)
                            }
                        }
                        .padding(.top, 10)

                        Button(action: {
                            withAnimation(fancyAnimation) {
                                shouldShowLog = true
                            }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 200)
                            if finished {
//                                triggerRespring = true // change this when porting this ui to your jailbreak
                                userspaceReboot()
                            } else {
                                withAnimation(fancyAnimation) {
                                    isRunning = true
                                    shouldShowLog = true
                                }
//                                funnyThing(true) { prog, log in
//                                    withAnimation(fancyAnimation) {
//                                        progress = prog
//                                        logItems.append(log)
//                                    }
//                                }
                                
                                withAnimation(fancyAnimation) {
                                    logItems.append("[i] \(UIDevice.current.localizedModel), iOS \(UIDevice.current.systemVersion)")
                                }

                                DispatchQueue.global(qos: .default).async {
                                    //                                        logItems.append("[*] Doing kopen")
                                    setProgress(0.1)
                                    do_kopen(UInt64(pUaFPages), 2, 1, 1)
                                    setProgress(0.25)
                                    //                                        logItems.append("[*] Exploit fixup")
                                    setProgress(0.3)
                                    fix_exploit()
                                    setProgress(0.5)
                                    //                                        logItems.append("[*] Hammer time.")
                                    setProgress(0.6)
                                    
                                    setProgress(0.75)
                                    //                                        logItems.append("[*] All done, kclosing")
                                    go(isBeta)
                                    setProgress(0.9)
                                    do_kclose()
                                    logItems.append("[√] All done!")
                                    setProgress(1.0)
                                }
                            }
                        }, label: {
                            if isRunning {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .tint(Color(UIColor.secondaryLabel))
                                        .controlSize(.regular)
                                    Text("Jelbreking")
                                }
                                .frame(width: geo.size.width / 2.5)
                            } else if finished {
                                Label("Userspace Reboot", systemImage: "arrow.clockwise")
                                    .frame(width: geo.size.width / 1.75)
                            } else {
                                Label("Jelbrek", systemImage: "lock.open")
                                    .frame(width: geo.size.width / 1.75)
                            }
                        })
                        .disabled(isRunning)
                        .buttonStyle(.bordered)
                        .tint(finished ? .green : color)
                        .controlSize(.large)
                        .padding(.vertical, 0.1)
                        if !isRunning && !finished {
                            Button("Switch to old UI", systemImage: "switch.2") {
                                withAnimation(fancyAnimation) {
                                    useNewUI.toggle()
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding()
                }
                .blur(radius: swag && blurScreen ? 3 : 0)
                .overlay {
                    if blurScreen {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea(.all)
                    }
                }
                .sheet(isPresented: $settingsOpen, onDismiss: {
                    withAnimation(fancyAnimation) {
                        blurScreen = false
                    }
                }, content: {
                    sheet
                })
            }
            .tint(color)
            .navigationViewStyle(.stack)
        }
        .onChange(of: color) { new in
            accentColor = updateCardColorInAppStorage(color: new)
        }
        .animation(fancyAnimation, value: logItems)
        .onAppear {
            if accentColor == "" {
                accentColor = updateCardColorInAppStorage(color: .init("accent", bundle: Bundle.main))
            }
            if showStdout {
                openConsolePipe()
            }
            showingGradient = swag
            withAnimation(fancyAnimation) {
                let rgbArray = accentColor.components(separatedBy: ",")
                if let red = Double(rgbArray[0]), let green = Double(rgbArray[1]), let blue = Double(rgbArray[2]), let alpha = Double(rgbArray[3]) {
                    color = .init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
                }
            }
        }
        .onChange(of: swag) { new in
            withAnimation(fancyAnimation) {
                showingGradient = new
            }
        }
    }
    
    func setProgress(_ p: Double) {
        withAnimation(fancyAnimation) {
            progress = p
        }
    }
}

struct LinkCell: View {
    var title: String
    var detail: String
    var link: String
    var imageName: String?
    var body: some View {
        Link(destination: URL(string: link)!) {
            HStack(alignment: .center) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle")
                        .font(.system(size: 32))
                }
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct CreditsView: View {
    var body: some View {
        List {
            LinkCell(title: "mineek", detail: "Main dev", link: "https://twitter.com/mineekdev", imageName: "mineek")
            LinkCell(title: "hrtowii/sacrosanctuary", detail: "Main dev", link: "https://twitter.com/htrowii", imageName: "htrowii")
            LinkCell(title: "DuyTranKhanh", detail: "Contributed SpringBoard hooks and launchd hooks", link: "https://twitter.com/TranKha50277352", imageName: "duy")
            LinkCell(title: "NSBedtime", detail: "launchd hax, helped out a ton!", link: "https://twitter.com/NSBedtime", imageName: "bedtime")
            LinkCell(title: "Nick Chan", detail: "Helped out a lot!", link: "https://twitter.com/riscv64", imageName: "alfienick")
            LinkCell(title: "Alfie CG", detail: "insert_dylib, name, helped out a lot", link: "https://twitter.com/alfiecg_dev", imageName: "alfienick")
            LinkCell(title: "BomberFish", detail: "Main UI", link: "https://bomberfish.ca", imageName: "fish")
            LinkCell(title: "haxi0", detail: "Added initial log", link: "https://bomberfish.ca", imageName: "haxi0")
        }
        .navigationTitle("Credits")
    }
}

func updateCardColorInAppStorage(color: Color) -> String {
    let uiColor = UIColor(color)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    return "\(red),\(green),\(blue),\(alpha)"
}

#Preview {
    ContentView(useNewUI: .constant(true))
}
