import AppKit

enum RenderTest {
    static func run(outPath: String) {
        _ = NSApplication.shared

        let panel = CGSize(width: 420, height: 560)
        let styles = PointerStyle.allCases
        let target = CGPoint(x: panel.width - 230, y: 380)
        let w = Int(panel.width) * styles.count
        let h = Int(panel.height)

        guard let ctx = CGContext(
            data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            exit(3)
        }

        for (i, style) in styles.enumerated() {
            ctx.saveGState()
            ctx.translateBy(x: CGFloat(i) * panel.width, y: 0)
            ctx.setFillColor(CGColor(red: 0.93, green: 0.94, blue: 0.92, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: panel.width, height: panel.height))

            let view = ArmView(frame: NSRect(origin: .zero, size: panel))
            view.setStyle(style)
            let resting = ProcessInfo.processInfo.environment["TH_RESTING"] != nil
            if !resting {
                view.press()
                view.held = true
            }
            view.aim(cursor: target)
            view.layer?.render(in: ctx)

            if style != .laser && ProcessInfo.processInfo.environment["TH_NO_MARKER"] == nil {
                ctx.setFillColor(CGColor(red: 0.95, green: 0.8, blue: 0.1, alpha: 1))
                ctx.fillEllipse(in: CGRect(x: target.x - 3, y: target.y - 3, width: 6, height: 6))
            }
            ctx.restoreGState()
        }

        guard let cg = ctx.makeImage() else {
            exit(4)
        }
        let rep = NSBitmapImageRep(cgImage: cg)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            exit(5)
        }
        try? data.write(to: URL(fileURLWithPath: outPath))
        print("rendered \(outPath)  \(w)x\(h)")
    }
}
