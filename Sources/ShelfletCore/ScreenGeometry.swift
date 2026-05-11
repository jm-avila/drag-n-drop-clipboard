import CoreGraphics
import Foundation

public enum ShelfEdge: String, Codable, CaseIterable, Equatable, Sendable {
    case left
    case right
    case top
    case bottom
}

public struct ScreenFrame: Equatable, Sendable {
    public var frame: CGRect
    public var visibleFrame: CGRect
    public var auxiliaryTopLeftArea: CGRect?
    public var auxiliaryTopRightArea: CGRect?

    public init(
        frame: CGRect,
        visibleFrame: CGRect,
        auxiliaryTopLeftArea: CGRect? = nil,
        auxiliaryTopRightArea: CGRect? = nil
    ) {
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.auxiliaryTopLeftArea = auxiliaryTopLeftArea
        self.auxiliaryTopRightArea = auxiliaryTopRightArea
    }
}

public enum ShelfGeometry {
    public static func hotZoneFrames(screen: ScreenFrame, edge: ShelfEdge, thickness: CGFloat) -> [CGRect] {
        let thickness = max(1, thickness)
        let visible = screen.visibleFrame

        switch edge {
        case .left:
            return [CGRect(x: visible.minX, y: visible.minY, width: thickness, height: visible.height)]
        case .right:
            return [CGRect(x: visible.maxX - thickness, y: visible.minY, width: thickness, height: visible.height)]
        case .bottom:
            return [CGRect(x: visible.minX, y: visible.minY, width: visible.width, height: thickness)]
        case .top:
            var frames = [CGRect(x: visible.minX, y: visible.maxY - thickness, width: visible.width, height: thickness)]
            if let auxiliaryTopLeftArea = screen.auxiliaryTopLeftArea, !auxiliaryTopLeftArea.isEmpty {
                frames.append(topStrip(in: auxiliaryTopLeftArea, thickness: thickness))
            }
            if let auxiliaryTopRightArea = screen.auxiliaryTopRightArea, !auxiliaryTopRightArea.isEmpty {
                frames.append(topStrip(in: auxiliaryTopRightArea, thickness: thickness))
            }
            return frames
        }
    }

    public static func shelfFrame(
        screen: ScreenFrame,
        edge: ShelfEdge,
        preferredSize: CGSize,
        margin: CGFloat
    ) -> CGRect {
        let visible = screen.visibleFrame
        let width = min(preferredSize.width, max(120, visible.width - margin * 2))
        let height = min(preferredSize.height, max(120, visible.height - margin * 2))

        let origin: CGPoint
        switch edge {
        case .left:
            origin = CGPoint(x: visible.minX + margin, y: visible.midY - height / 2)
        case .right:
            origin = CGPoint(x: visible.maxX - width - margin, y: visible.midY - height / 2)
        case .top:
            origin = CGPoint(x: visible.midX - width / 2, y: visible.maxY - height - margin)
        case .bottom:
            origin = CGPoint(x: visible.midX - width / 2, y: visible.minY + margin)
        }

        return clamp(CGRect(origin: origin, size: CGSize(width: width, height: height)), to: visible)
    }

    public static func clamp(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        let width = min(rect.width, bounds.width)
        let height = min(rect.height, bounds.height)
        let x = min(max(rect.minX, bounds.minX), bounds.maxX - width)
        let y = min(max(rect.minY, bounds.minY), bounds.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func topStrip(in rect: CGRect, thickness: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: rect.maxY - thickness, width: rect.width, height: thickness)
    }
}
