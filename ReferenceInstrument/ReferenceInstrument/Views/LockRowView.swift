import SwiftUI

struct LockRowView: View {
    @State private var hasMerged = false
    @State private var mergeTask: Task<Void, Never>?
    let sumLock: Bool
    let adjacencyLock: Bool
    let canonicalLock: Bool

    var body: some View {
        let fullyLocked = sumLock && adjacencyLock && canonicalLock

        ZStack {
            if !hasMerged {
                HStack(spacing: InstrumentMetrics.gridSpacing) {
                    LockIndicatorView(locked: sumLock)
                    LockIndicatorView(locked: adjacencyLock)
                    LockIndicatorView(locked: canonicalLock)
                }
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(
                        width: InstrumentMetrics.lockSize * 4,
                        height: InstrumentMetrics.lockSize
                    )
                    .transition(.opacity)
            }
        }
        .frame(width: InstrumentMetrics.gridWidth)
        .frame(height: 10)
        .onAppear {
            hasMerged = fullyLocked
        }
        .onChange(of: fullyLocked) { _, locked in
            if locked && !hasMerged {
                mergeTask?.cancel()
                mergeTask = Task {
                    let delay = InstrumentTiming.lockFill + InstrumentTiming.settle
                    try? await Task.sleep(
                        nanoseconds: UInt64(delay * 1_000_000_000)
                    )

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        withAnimation(.easeInOut(duration: InstrumentTiming.merge)) {
                            hasMerged = true
                        }
                    }
                }
            } else {
                mergeTask?.cancel()
                withAnimation(.easeInOut(duration: InstrumentTiming.merge)) {
                    hasMerged = false
                }
            }
        }
        .onDisappear {
            mergeTask?.cancel()
        }
    }
}
