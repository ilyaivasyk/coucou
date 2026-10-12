import Foundation
import CoreGraphics

@main
enum IslandScreenGeometryTests {
    static func main() {
        // Regression: absent auxiliary areas must never mean "screen-wide notch".
        for screenWidth: CGFloat in [1080, 1920, 2560, 3840] {
            let geometry = IslandScreenGeometry(
                screenWidth: screenWidth, safeAreaTop: 0,
                auxiliaryLeftWidth: nil, auxiliaryRightWidth: nil, menuBarHeight: 30
            )
            precondition(!geometry.hasNotch)
            precondition(geometry.width == 80)
            precondition(geometry.height == 24)
        }

        // A shorter menu bar must also contain the resting island.
        let shortMenuBar = IslandScreenGeometry(
            screenWidth: 1920, safeAreaTop: 0,
            auxiliaryLeftWidth: nil, auxiliaryRightWidth: nil, menuBarHeight: 22
        )
        precondition(shortMenuBar.height == 22)

        // Real MacBook notch measurements retain their physical dimensions.
        let macBook = IslandScreenGeometry(
            screenWidth: 1512, safeAreaTop: 32,
            auxiliaryLeftWidth: 660, auxiliaryRightWidth: 660, menuBarHeight: 32
        )
        precondition(macBook.hasNotch)
        precondition(macBook.width == 192 && macBook.height == 32)

        // Incomplete or invalid measurements use the notch fallback, not the screen.
        for auxiliaryWidth: CGFloat? in [nil, 0, 1000] {
            let geometry = IslandScreenGeometry(
                screenWidth: 1512, safeAreaTop: 32,
                auxiliaryLeftWidth: auxiliaryWidth, auxiliaryRightWidth: auxiliaryWidth,
                menuBarHeight: 32
            )
            precondition(geometry.width == 184 && geometry.height == 32)
        }
        // Compact/greeting destinations share the measured resting height.
        for height: CGFloat in [22, 24, 32, 38] {
            let compact = IslandRestingLayout(width: 240, height: height)
            precondition(compact.botCenterY == height / 2)
            precondition(compact.botDiameter == min(20, height - 6))
            precondition(compact.botCenterY - compact.botDiameter / 2 >= 3)
            precondition(compact.botCenterY + compact.botDiameter / 2 <= height - 3)
            precondition(compact.miniGridCenterX == 200)
            precondition(compact.miniGridScale * 28 <= height - 4)
        }
        let screen = CGRect(x: -1920, y: 200, width: 1920, height: 1080)
        let panel = CGSize(width: 720, height: 560)
        for offset: CGFloat in [0, 200, -200, -10000, 10000, .nan] {
            let frame = IslandHorizontalPosition.frame(screen: screen, panelSize: panel,
                                                      offset: offset, islandWidth: 640)
            precondition(frame.maxY == screen.maxY && frame.size == panel)
            precondition(frame.midX - 320 >= screen.minX && frame.midX + 320 <= screen.maxX)
            if offset.isFinite && abs(offset) <= 200 { precondition(frame.midX == screen.midX + offset) }
            if !offset.isFinite { precondition(frame.midX == screen.midX) }
        }
        let narrow = IslandHorizontalPosition.frame(screen: CGRect(x: 0, y: 0, width: 480, height: 800),
            panelSize: panel, offset: 10000, islandWidth: 640)
        precondition(narrow.midX == 240)
        print("Island screen geometry, resting layout and horizontal positioning: 20 cases passed")
    }
}
