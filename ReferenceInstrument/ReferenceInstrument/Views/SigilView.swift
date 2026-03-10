import SigilEngine
import SwiftUI

struct SigilView: View {
    let geometry: SigilGeometry
    let isFrozen: Bool
    @State private var revealProgress: CGFloat = 1

    var body: some View {
        Path { path in
            guard geometry.points.count > 1 else { return }

            let first = geometry.points[0]
            path.move(
                to: CGPoint(
                    x: first.x * SigilMetrics.frame,
                    y: first.y * SigilMetrics.frame
                )
            )

            for point in geometry.points.dropFirst() {
                path.addLine(
                    to: CGPoint(
                        x: point.x * SigilMetrics.frame,
                        y: point.y * SigilMetrics.frame
                    )
                )
            }
        }
        .trim(from: 0, to: revealProgress)
        .stroke(Color.black, lineWidth: SigilMetrics.stroke)
        .frame(
            width: SigilMetrics.frame,
            height: SigilMetrics.frame
        )
        .onChange(of: isFrozen) { _, frozen in
            guard frozen else { return }

            revealProgress = 0

            withAnimation(.linear(duration: InstrumentTiming.sigil)) {
                revealProgress = 1
            }
        }
    }
}
