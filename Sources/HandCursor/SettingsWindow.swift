import AppKit

/// A small, plain-AppKit settings window.
final class SettingsWindow: NSObject, NSWindowDelegate {
    var applyToggleShortcut: ((Shortcut) -> Bool)?
    var onRecording: ((Bool) -> Void)?

    private var window: NSWindow?
    private var previewSound: TapSound?
    private var styleButtons: [PointerStyle: NSButton] = [:]
    private let sizeSlider = NSSlider(value: 0.13, minValue: Double(Preferences.pointerSizeRange.lowerBound),
                                      maxValue: Double(Preferences.pointerSizeRange.upperBound), target: nil, action: nil)
    private let shadowBox = NSButton(checkboxWithTitle: "Soft shadow under the hand", target: nil, action: nil)
    private let toolbarBox = NSButton(checkboxWithTitle: "Show the toolbar when the pointer is on", target: nil, action: nil)
    private let soundMenu = NSPopUpButton(frame: .zero, pullsDown: false)
    private let laserSoundBox = NSButton(checkboxWithTitle: "Laser dot clicks too", target: nil, action: nil)
    private let loginBox = NSButton(checkboxWithTitle: "Open \(AppInfo.name) when you log in", target: nil, action: nil)
    private let shortcutError = NSTextField(labelWithString: "")
    private var recorder: ShortcutRecorder?
    private var observer: Any?

    func show() {
        if window == nil {
            build()
        }
        refresh()
        NSApp.activate(ignoringOtherApps: true)
        if window?.isVisible != true {
            window?.center()
        }
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(nil)
        previewSound?.warm()
    }

    func snapshot(dark: Bool = false) -> CGImage? {
        if window == nil {
            build()
        }
        guard let w = window, let view = w.contentView else {
            return nil
        }
        refresh()
        w.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        view.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            return nil
        }
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep.cgImage
    }

    func windowWillClose(_ notification: Notification) {
        onRecording?(false)
    }

    // MARK: Building

    private func build() {
        let content = NSStackView()
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 10
        content.edgeInsets = NSEdgeInsets(top: 22, left: 24, bottom: 22, right: 24)

        content.addArrangedSubview(heading("Pointer"))
        content.addArrangedSubview(pointerGrid())
        content.addArrangedSubview(labeled("Size", sizeSlider))
        content.addArrangedSubview(shadowBox)
        content.addArrangedSubview(toolbarBox)

        content.addArrangedSubview(spacer())
        content.addArrangedSubview(heading("Click sound"))
        content.addArrangedSubview(labeled("Sound", soundMenu))
        content.addArrangedSubview(laserSoundBox)

        content.addArrangedSubview(spacer())
        content.addArrangedSubview(heading("General"))
        let recorder = ShortcutRecorder(shortcut: Preferences.toggleShortcut)
        recorder.onChange = { [weak self] shortcut in
            guard let self = self else {
                return false
            }
            let ok = self.applyToggleShortcut?(shortcut) ?? false
            self.shortcutError.stringValue = ok ? "" : "That shortcut is taken by another app."
            return ok
        }
        recorder.onRecording = { [weak self] recording in
            self?.shortcutError.stringValue = ""
            self?.onRecording?(recording)
        }
        self.recorder = recorder
        content.addArrangedSubview(labeled("Turn pointer on/off", recorder))
        shortcutError.textColor = .systemRed
        shortcutError.font = .systemFont(ofSize: 11)
        content.addArrangedSubview(shortcutError)
        content.addArrangedSubview(loginBox)

        content.addArrangedSubview(spacer())
        content.addArrangedSubview(aboutRow())

        sizeSlider.target = self
        sizeSlider.action = #selector(sizeChanged)
        sizeSlider.isContinuous = true
        sizeSlider.widthAnchor.constraint(equalToConstant: 220).isActive = true
        for box in [shadowBox, toolbarBox, laserSoundBox, loginBox] {
            box.target = self
            box.action = #selector(boxChanged(_:))
        }
        soundMenu.addItem(withTitle: "Off")
        soundMenu.menu?.addItem(.separator())
        for choice in TapSoundChoice.allCases {
            soundMenu.addItem(withTitle: choice.title)
            soundMenu.lastItem?.representedObject = choice.rawValue
        }
        soundMenu.target = self
        soundMenu.action = #selector(soundChanged)

        let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable],
                         backing: .buffered, defer: false)
        w.title = "\(AppInfo.name) Settings"
        w.isReleasedWhenClosed = false
        w.delegate = self
        w.contentView = content
        content.layoutSubtreeIfNeeded()
        w.setContentSize(content.fittingSize)
        window = w

        observer = NotificationCenter.default.addObserver(forName: Preferences.changed, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
    }

    private func pointerGrid() -> NSView {
        let columns = 8
        let styles = PointerStyle.allCases
        let rows = stride(from: 0, to: styles.count, by: columns).map { start -> NSStackView in
            let row = NSStackView(views: styles[start..<min(start + columns, styles.count)].map(pointerButton))
            row.orientation = .horizontal
            row.spacing = 4
            return row
        }
        let grid = NSStackView(views: rows)
        grid.orientation = .vertical
        grid.alignment = .leading
        grid.spacing = 4
        return grid
    }

    private func pointerButton(_ style: PointerStyle) -> NSButton {
        let b = NSButton()
        b.isBordered = false
        b.imageScaling = .scaleProportionallyUpOrDown
        b.image = Toolbar.icon(for: style)
        b.toolTip = style.title
        b.setAccessibilityLabel(style.title)
        b.wantsLayer = true
        b.layer?.cornerRadius = 10
        b.layer?.borderWidth = 2
        b.target = self
        b.action = #selector(pointerPicked(_:))
        b.widthAnchor.constraint(equalToConstant: 48).isActive = true
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        styleButtons[style] = b
        return b
    }

    private func heading(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }

    private func labeled(_ text: String, _ control: NSView) -> NSStackView {
        let label = NSTextField(labelWithString: text)
        label.textColor = .secondaryLabelColor
        label.widthAnchor.constraint(equalToConstant: 130).isActive = true
        let row = NSStackView(views: [label, control])
        row.orientation = .horizontal
        row.spacing = 8
        return row
    }

    private func spacer() -> NSView {
        let v = NSView()
        v.heightAnchor.constraint(equalToConstant: 4).isActive = true
        return v
    }

    private func aboutRow() -> NSView {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        let label = NSTextField(labelWithString: "\(AppInfo.name) \(version) · MIT · based on")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        let link = NSButton(title: "TinyHand", target: self, action: #selector(openOriginal))
        link.isBordered = false
        link.font = .systemFont(ofSize: 11)
        link.contentTintColor = .linkColor
        let source = NSButton(title: "Source", target: self, action: #selector(openSource))
        source.isBordered = false
        source.font = .systemFont(ofSize: 11)
        source.contentTintColor = .linkColor
        let reset = NSButton(title: "Reset settings…", target: self, action: #selector(resetAll))
        reset.controlSize = .small
        let row = NSStackView(views: [label, link, source, reset])
        row.orientation = .horizontal
        row.spacing = 6
        let thanks = NSButton(title: "♥ Rebuilt for fun, thanks to @nilbuild's TinyHand — star the original", target: self, action: #selector(openOriginal))
        thanks.isBordered = false
        thanks.font = .systemFont(ofSize: 11, weight: .medium)
        thanks.contentTintColor = .linkColor
        let column = NSStackView(views: [thanks, row])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 6
        return column
    }

    // MARK: State

    private func refresh() {
        for (style, b) in styleButtons {
            let selected = style == PointerStyle.saved
            b.layer?.borderColor = selected ? NSColor.controlAccentColor.cgColor : NSColor.clear.cgColor
            b.layer?.backgroundColor = selected ? NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor : NSColor.clear.cgColor
        }
        sizeSlider.doubleValue = Double(Preferences.pointerSize)
        shadowBox.state = Preferences.showShadow ? .on : .off
        toolbarBox.state = Preferences.showToolbar ? .on : .off
        laserSoundBox.state = Preferences.laserSound ? .on : .off
        laserSoundBox.isEnabled = Preferences.handSound
        loginBox.state = Preferences.launchAtLogin ? .on : .off
        if Preferences.handSound,
           let index = soundMenu.itemArray.firstIndex(where: { $0.representedObject as? String == Preferences.tapSound.rawValue }) {
            soundMenu.selectItem(at: index)
        } else {
            soundMenu.selectItem(at: 0)
        }
        recorder?.show(Preferences.toggleShortcut)
    }

    // MARK: Actions

    @objc private func pointerPicked(_ sender: NSButton) {
        guard let style = styleButtons.first(where: { $0.value === sender })?.key else {
            return
        }
        PointerStyle.saved = style
        NotificationCenter.default.post(name: Preferences.changed, object: nil)
    }

    @objc private func sizeChanged() {
        Preferences.pointerSize = CGFloat(sizeSlider.doubleValue)
    }

    @objc private func boxChanged(_ sender: NSButton) {
        let on = sender.state == .on
        switch sender {
        case shadowBox: Preferences.showShadow = on
        case toolbarBox: Preferences.showToolbar = on
        case laserSoundBox: Preferences.laserSound = on
        case loginBox: Preferences.launchAtLogin = on
        default: break
        }
    }

    @objc private func soundChanged() {
        guard let raw = soundMenu.selectedItem?.representedObject as? String,
              let choice = TapSoundChoice(rawValue: raw) else {
            Preferences.handSound = false
            return
        }
        Preferences.tapSound = choice
        Preferences.handSound = true
        if previewSound == nil {
            previewSound = TapSound(choice)
        }
        previewSound?.load(choice)
        previewSound?.play()
    }

    @objc private func openOriginal() {
        if let url = URL(string: AppInfo.originalURL) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openSource() {
        if let url = URL(string: AppInfo.repoURL) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func resetAll() {
        let alert = NSAlert()
        alert.messageText = "Reset all settings?"
        alert.informativeText = "Pointer, size, shadow, sound and shortcut go back to how they were at first."
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }
        Preferences.resetAll()
        _ = applyToggleShortcut?(.toggleDefault)
        refresh()
    }
}
