import AppKit

/// Watches mouse buttons so the hand can press down and release. It only observes: clicks, drags
/// and scrolls always reach the app underneath, and no system permission is needed to see them.
final class ClickMonitor {
    var onDown: (() -> Void)?
    var onUp: (() -> Void)?
    var onDragged: (() -> Void)?

    private var monitors: [Any] = []

    private static let down: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
    private static let up: NSEvent.EventTypeMask = [.leftMouseUp, .rightMouseUp, .otherMouseUp]
    private static let dragged: NSEvent.EventTypeMask = [.leftMouseDragged, .rightMouseDragged, .otherMouseDragged]

    func start() {
        guard monitors.isEmpty else {
            return
        }
        let mask = ClickMonitor.down.union(ClickMonitor.up).union(ClickMonitor.dragged)
        // The global monitor sees other apps; the local one sees our own windows (toolbar, settings).
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handle(event)
        }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handle(event)
            return event
        }) {
            monitors.append(local)
        }
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors = []
    }

    private func handle(_ event: NSEvent) {
        let type = NSEvent.EventTypeMask(rawValue: 1 << UInt64(event.type.rawValue))
        if ClickMonitor.down.contains(type) {
            onDown?()
        } else if ClickMonitor.up.contains(type) {
            onUp?()
        } else {
            onDragged?()
        }
    }
}
