import AppKit

final class WelcomeWindow: NSObject {
    var onTryIt: (() -> Void)?

    private final class Card: NSWindow {
        override var canBecomeKey: Bool { true }
        override func cancelOperation(_ sender: Any?) {
            orderOut(nil)
        }
    }

    private var window: Card?
    private let title = NSTextField(labelWithString: "")
    private let subtitle = NSTextField(labelWithString: "")
    private let button = NSButton(title: "Start", target: nil, action: nil)
    private let loginBox = NSButton(checkboxWithTitle: "Keep it running — open at login", target: nil, action: nil)
    private let thanks = NSButton(title: "", target: nil, action: nil)

    static let shownKey = "welcomeShown"

    func show() {
        if window == nil {
            build()
        }
        refresh()
        UserDefaults.standard.set(true, forKey: WelcomeWindow.shownKey)
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        window?.invalidateShadow()
        window?.makeFirstResponder(nil)
    }

    private func refresh() {
        loginBox.state = (Preferences.launchAtLogin || !UserDefaults.standard.bool(forKey: WelcomeWindow.shownKey)) ? .on : .off
        title.stringValue = "You're all set"
        subtitle.stringValue = "Press \(Preferences.toggleShortcut.display) any time to start,\nor click the hand in the menu bar."
    }

    @objc private func openOriginal() {
        if let url = URL(string: AppInfo.originalURL) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func buttonPressed() {
        let wantsLogin = loginBox.state == .on
        if wantsLogin != Preferences.launchAtLogin {
            Preferences.launchAtLogin = wantsLogin
        }
        close()
        onTryIt?()
    }

    @objc private func close() {
        window?.orderOut(nil)
    }

    private func build() {
        let size = CGSize(width: 340, height: 380)
        let w = Card(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = true
        w.isMovableByWindowBackground = true
        w.isReleasedWhenClosed = false
        w.level = .normal

        let card = NSVisualEffectView(frame: CGRect(origin: .zero, size: size))
        card.material = .popover
        card.blendingMode = .behindWindow
        card.state = .active
        card.roundCorners(20)
        w.contentView = card

        let icon = NSImageView()
        icon.image = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 76).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 76).isActive = true

        title.font = NSFont.systemFont(ofSize: 19, weight: .semibold)
        title.alignment = .center
        subtitle.font = NSFont.systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center
        subtitle.maximumNumberOfLines = 2

        button.target = self
        button.action = #selector(buttonPressed)
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.keyEquivalent = "\r"
        button.widthAnchor.constraint(equalToConstant: 180).isActive = true

        thanks.isBordered = false
        thanks.attributedTitle = NSAttributedString(string: "Rebuilt for fun by @callmeahmedr — thanks to TinyHand\nand @nilbuild for the original ♥ Star it on GitHub", attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.linkColor,
            .paragraphStyle: { let p = NSMutableParagraphStyle(); p.alignment = .center; return p }(),
        ])
        thanks.target = self
        thanks.action = #selector(openOriginal)

        let stack = NSStackView(views: [icon, title, subtitle, loginBox, button, thanks])
        stack.setCustomSpacing(14, after: loginBox)
        stack.setCustomSpacing(16, after: button)
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 6
        stack.setCustomSpacing(16, after: icon)
        stack.setCustomSpacing(18, after: subtitle)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let closeButton = NSButton(image: NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")!,
                                   target: self, action: #selector(close))
        closeButton.isBordered = false
        closeButton.contentTintColor = .tertiaryLabelColor
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(closeButton)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: 4),
            closeButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            closeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
        ])
        card.removeFocusRings()
        window = w
    }

    func snapshot() -> NSBitmapImageRep? {
        if window == nil {
            build()
        }
        refresh()
        guard let view = window?.contentView else {
            return nil
        }
        window?.appearance = NSAppearance(named: .aqua)
        view.layer?.backgroundColor = NSColor(white: 0.96, alpha: 1).cgColor
        view.layoutSubtreeIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            return nil
        }
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep
    }
}
