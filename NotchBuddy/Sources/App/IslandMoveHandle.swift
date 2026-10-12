import AppKit
import SwiftUI

struct IslandMoveHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { HandleView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class HandleView: NSView {
        private var lastMouseX: CGFloat?

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }

        override func mouseDown(with event: NSEvent) {
            lastMouseX = NSEvent.mouseLocation.x
            NSCursor.closedHand.set()
        }

        override func mouseDragged(with event: NSEvent) {
            guard let previous = lastMouseX else { return }
            // Screen coordinates stay stable while the panel moves under the pointer.
            let current = NSEvent.mouseLocation.x
            lastMouseX = current
            NotificationCenter.default.post(name: .islandMoveBy, object: current - previous)
        }

        override func mouseUp(with event: NSEvent) {
            lastMouseX = nil
            NSCursor.openHand.set()
            NotificationCenter.default.post(name: .islandMoveEnded, object: nil)
        }
    }
}
