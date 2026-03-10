import SwiftUI

struct LockIndicatorView: View {
    let locked: Bool

    var body: some View {
        Rectangle()
            .fill(locked ? Color.black : Color.clear)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 1)
            )
            .frame(
                width: InstrumentMetrics.lockSize,
                height: InstrumentMetrics.lockSize
            )
            .animation(
                .linear(duration: InstrumentTiming.lockFill),
                value: locked
            )
    }
}
