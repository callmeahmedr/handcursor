import AppKit

struct PointerStyle: Hashable {
    let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    init?(rawValue: String) {
        guard PointerStyle.allCases.contains(where: { $0.rawValue == rawValue }) else {
            return nil
        }
        self.rawValue = rawValue
    }

    static let lavender = PointerStyle("lavender")
    static let glove = PointerStyle("glove")
    static let coral = PointerStyle("coral")
    static let plush = PointerStyle("plush")
    static let robot = PointerStyle("robot")
    static let laser = PointerStyle("laser")

    private static let builtIn: [(id: String, title: String)] = [
        ("lavender", "Lavender toy"),
        ("glove", "Cursor glove"),
        ("coral", "Coral vinyl"),
        ("plush", "Plush"),
        ("robot", "Robot"),
        ("pink", "Bubblegum"),
        ("blue", "Sky"),
        ("mint", "Mint"),
        ("lemon", "Lemon"),
        ("black", "Midnight"),
        ("chrome", "Chrome"),
        ("holo", "Holo"),
        ("fuzzy", "Fuzzy"),
        ("wood", "Wood"),
        ("marble", "Marble"),
        ("terrazzo", "Terrazzo"),
        ("glass", "Glass"),
        ("jelly", "Jelly"),
        ("pastel", "Pastel"),
        ("pixel", "Pixel"),
        ("lowpoly", "Low poly"),
        ("knit", "Knit"),
        ("skeleton", "Skeleton"),
        ("astro", "Astronaut"),
        ("space", "Space"),
        ("monster", "Monster"),
        ("water", "Water"),
        ("lava", "Lava"),
        ("grass", "Grass"),
        ("cactus", "Cactus"),
        ("choco", "Chocolate"),
        ("cloud", "Cloud"),
        ("mech", "Mech"),
        ("neon", "Neon"),
        ("leaf", "Leaf"),
        ("cookie", "Gingerbread"),
    ]

    static var builtInHands: [PointerStyle] {
        builtIn.map { PointerStyle($0.id) }
    }

    static var allCases: [PointerStyle] {
        builtInHands + [.laser]
    }

    static let defaultPinned: [PointerStyle] = [.lavender, .glove, .coral, .plush, .robot, .laser]

    var title: String {
        if self == .laser {
            return "Laser dot"
        }
        return PointerStyle.builtIn.first { $0.id == rawValue }?.title ?? rawValue
    }

    var assetName: String? {
        if self == .laser {
            return nil
        }
        return "hand_\(rawValue)"
    }

    private static let defaultsKey = "pointerStyle"

    static var saved: PointerStyle {
        get {
            let raw = UserDefaults.standard.string(forKey: defaultsKey)
            if raw == "dot" {
                return .laser
            }
            if raw == "sunny" {
                return .coral
            }
            return raw.flatMap(PointerStyle.init(rawValue:)) ?? .lavender
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }
}

struct HandAsset {
    let image: CGImage
    let aspect: CGFloat
    let handTop: CGFloat
    let tip: CGFloat
    let wrist: CGFloat
    let rodEnd: CGFloat
    let tipX: CGFloat
    let rodX: CGFloat
    let handMinX: CGFloat
    let handMaxX: CGFloat

    private static var cache: [String: HandAsset] = [:]
    private static var recent: [String] = []
    private static let cacheLimit = 2

    static func load(_ name: String) -> HandAsset? {
        if let hit = cache[name] {
            touch(name)
            return hit
        }
        guard let image = loadImage(name), let asset = measure(image) else {
            return nil
        }
        cache[name] = asset
        touch(name)
        return asset
    }

    private static func touch(_ name: String) {
        recent.removeAll { $0 == name }
        recent.append(name)
        while recent.count > cacheLimit {
            cache[recent.removeFirst()] = nil
        }
    }

    private static var thumbnails: [String: NSImage] = [:]

    static func forget(_ name: String) {
        cache[name] = nil
        recent.removeAll { $0 == name }
        thumbnails[name] = nil
    }

    static func cachedThumbnail(_ name: String) -> NSImage? {
        thumbnails[name]
    }

    static func preloadThumbnails(_ names: [String], done: (() -> Void)? = nil) {
        let missing = names.filter { thumbnails[$0] == nil }
        guard !missing.isEmpty else {
            done?()
            return
        }
        DispatchQueue.global(qos: .utility).async {
            var built: [(String, NSImage)] = []
            for name in missing {
                autoreleasepool {
                    if let thumb = loadImage(name).flatMap(measure)?.thumbnail {
                        built.append((name, thumb))
                    }
                }
            }
            DispatchQueue.main.async {
                for (name, thumb) in built where thumbnails[name] == nil {
                    thumbnails[name] = thumb
                }
                done?()
            }
        }
    }

    static func thumbnail(_ name: String) -> NSImage? {
        if let hit = thumbnails[name] {
            return hit
        }
        let asset = cache[name] ?? loadImage(name).flatMap(measure)
        guard let thumb = asset?.thumbnail else {
            return nil
        }
        thumbnails[name] = thumb
        return thumb
    }

    var thumbnail: NSImage {
        let h = CGFloat(image.height)
        let w = CGFloat(image.width)
        let handW = (handMaxX - handMinX) * w
        let handH = (wrist - handTop) * h
        let side = max(handW, handH) * 1.06
        let cx = (handMinX + handMaxX) / 2 * w
        let cy = (handTop + wrist) / 2 * h
        let rect = CGRect(x: cx - side / 2, y: cy - side / 2, width: side, height: side)
            .intersection(CGRect(x: 0, y: 0, width: w, height: h))
        let cropped = image.cropping(to: rect) ?? image
        let px = 128
        guard let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return NSImage(cgImage: cropped, size: NSSize(width: 64, height: 64))
        }
        ctx.interpolationQuality = .high
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: px, height: px))
        guard let small = ctx.makeImage() else {
            return NSImage(cgImage: cropped, size: NSSize(width: 64, height: 64))
        }
        return NSImage(cgImage: small, size: NSSize(width: 64, height: 64))
    }

    static func resized(_ image: CGImage, height: Int) -> CGImage? {
        let width = max(1, Int((CGFloat(image.width) * CGFloat(height) / CGFloat(image.height)).rounded()))
        let space = image.colorSpace.flatMap { $0.model == .rgb ? $0 : nil }
            ?? CGColorSpace(name: CGColorSpace.sRGB)
            ?? CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()
    }

    private static func measure(_ image: CGImage) -> HandAsset? {
        let w = image.width
        let h = image.height
        var alpha = [UInt8](repeating: 0, count: w * h)
        guard let ctx = CGContext(data: &alpha, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                                  space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else {
            return nil
        }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

        func count(_ y: Int) -> Int {
            var n = 0
            let row = y * w
            for x in 0..<w where alpha[row + x] > 128 {
                n += 1
            }
            return n
        }
        func center(_ y: Int) -> CGFloat {
            let row = y * w
            var lo = -1
            var hi = -1
            for x in 0..<w where alpha[row + x] > 128 {
                if lo < 0 {
                    lo = x
                }
                hi = x
            }
            return lo < 0 ? 0.5 : CGFloat(lo + hi) / 2 / CGFloat(w)
        }

        let counts = (0..<h).map(count)
        guard let top = counts.firstIndex(where: { $0 > 0 }) else {
            return nil
        }
        let searchEnd = min(h, top + Int(0.45 * Double(h)))
        let maxW = counts[top..<searchEnd].max() ?? 0
        guard maxW > 0,
              let fist = (top..<h).first(where: { Double(counts[$0]) > 0.6 * Double(maxW) }),
              let wrist = (fist..<h).first(where: { Double(counts[$0]) < 0.35 * Double(maxW) }) else {
            return nil
        }
        let rodW = counts[min(h - 1, wrist + h / 50)]
        let lastRow = counts.lastIndex(where: { $0 > 0 }) ?? (h - 1)
        let from = min(h - 1, wrist + h / 33)
        let handle = (from..<h).first(where: { Double(counts[$0]) > 1.8 * Double(rodW) })
        let rodEnd = handle ?? lastRow

        var minX = w
        var maxX = 0
        for y in top..<wrist {
            let row = y * w
            for x in 0..<w where alpha[row + x] > 128 {
                minX = min(minX, x)
                maxX = max(maxX, x)
            }
        }

        let fh = CGFloat(h)
        return HandAsset(
            image: image,
            aspect: CGFloat(w) / fh,
            handTop: max(0, CGFloat(top) - 0.004 * fh) / fh,
            tip: CGFloat(top) / fh,
            wrist: CGFloat(wrist) / fh,
            rodEnd: CGFloat(rodEnd) / fh,
            tipX: center(min(h - 1, top + h / 200)),
            rodX: center((wrist + rodEnd) / 2),
            handMinX: CGFloat(minX) / CGFloat(w),
            handMaxX: CGFloat(maxX) / CGFloat(w)
        )
    }

    private static func loadImage(_ name: String) -> CGImage? {
        let exeDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
        var urls: [URL] = []

        if let u = Bundle.main.url(forResource: name, withExtension: "png") {
            urls.append(u)
        }
        urls.append(exeDir.appendingPathComponent("\(name).png"))
        urls.append(exeDir.appendingPathComponent("assets/\(name).png"))
        urls.append(URL(fileURLWithPath: "assets/\(name).png"))
        for url in urls where FileManager.default.fileExists(atPath: url.path) {
            if let image = NSImage(contentsOf: url),
               let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                return cg
            }
        }
        return nil
    }
}
