import Foundation
import CoreGraphics
import SigilEngine

struct SigilSVGExporter {
    static func export(
        geometry: SigilGeometry
    ) -> String {
        let frame = SigilMetrics.frame

        guard geometry.points.count > 1 else { return "" }

        let xs = geometry.points.map(\.x)
        let ys = geometry.points.map(\.y)

        guard let minX = xs.min(),
            let maxX = xs.max(),
            let minY = ys.min(),
            let maxY = ys.max() else {
            return ""
        }

        let width = maxX - minX
        let height = maxY - minY
        let maxDimension = max(width, height)

        guard maxDimension > 0 else { return "" }

        let scale = frame / maxDimension

        let normalizedPoints = geometry.points.map { point in
            CGPoint(
                x: (point.x - minX) * scale,
                y: (point.y - minY) * scale
            )
        }

        let offsetX = (frame - width * scale) / 2
        let offsetY = (frame - height * scale) / 2

        let centeredPoints = normalizedPoints.map {
            CGPoint(
                x: $0.x + offsetX,
                y: $0.y + offsetY
            )
        }

        var d = "M \(centeredPoints[0].x) \(centeredPoints[0].y)"

        for point in centeredPoints.dropFirst() {
            d += " L \(point.x) \(point.y)"
        }

        return """
        <svg xmlns="http://www.w3.org/2000/svg"
             width="\(frame)"
             height="\(frame)"
             viewBox="0 0 \(frame) \(frame)">
          <path d="\(d)"
                fill="none"
                stroke="black"
                stroke-width="\(SigilMetrics.stroke)"
                stroke-linecap="round"
                stroke-linejoin="round"/>
        </svg>
        """
    }
}
