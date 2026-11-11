import AppKit
import ApplicationServices

if let idx = CommandLine.arguments.firstIndex(of: "--render-test") {
    let out = CommandLine.arguments.count > idx + 1 ? CommandLine.arguments[idx + 1] : "/tmp/armtest.png"
    RenderTest.run(outPath: out)
    exit(0)
}

if let idx = CommandLine.arguments.firstIndex(of: "--toolbar-test") {
    _ = NSApplication.shared
    let bar = Toolbar()
    bar.select(.lavender)
    let out = CommandLine.arguments.count > idx + 1 ? CommandLine.arguments[idx + 1] : "/tmp/toolbar.png"
    if let data = bar.snapshot()?.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: out))
        print("rendered \(out)")
    }
    if CommandLine.arguments.contains("--hint") {
        bar.showHint([("Click", "like normal"), ("⌃⌥H", "to turn off")])
        if let data = bar.snapshotHint()?.representation(using: .png, properties: [:]) {
            let hintOut = out.replacingOccurrences(of: ".png", with: "-hint.png")
            try? data.write(to: URL(fileURLWithPath: hintOut))
            print("rendered \(hintOut)")
        }
    }
    exit(0)
}

if let idx = CommandLine.arguments.firstIndex(of: "--settings-test") {
    _ = NSApplication.shared
    let out = CommandLine.arguments.count > idx + 1 ? CommandLine.arguments[idx + 1] : "/tmp/settings.png"
    let dark = ProcessInfo.processInfo.environment["TH_DARK"] != nil
    if let image = SettingsWindow().snapshot(dark: dark),
       let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: out))
        print("rendered \(out)")
    }
    exit(0)
}

if let idx = CommandLine.arguments.firstIndex(of: "--welcome-test") {
    _ = NSApplication.shared
    let out = CommandLine.arguments.count > idx + 1 ? CommandLine.arguments[idx + 1] : "/tmp/welcome.png"
    let welcome = WelcomeWindow()
    if let data = welcome.snapshot()?.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: out))
        print("rendered \(out)")
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
