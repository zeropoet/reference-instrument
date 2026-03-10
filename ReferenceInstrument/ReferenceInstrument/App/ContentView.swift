import SwiftUI
import FoldKernel

struct ContentView: View {
    @StateObject var state = InstrumentState()
    @State private var hasEnteredInstrument = false

    var body: some View {
        ZStack {
            if hasEnteredInstrument {
                InstrumentView(state: state)
                    .transition(.opacity)
            } else {
                LaunchView()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .task {
            guard !hasEnteredInstrument else { return }

            try? await Task.sleep(nanoseconds: 1_200_000_000)

            await MainActor.run {
                withAnimation(.easeOut(duration: InstrumentTiming.sigil)) {
                    hasEnteredInstrument = true
                }
            }
        }
    }
}

private struct InstrumentView: View {
    @ObservedObject var state: InstrumentState

    var body: some View {
        VStack(spacing: 32) {
            LockRowView(
                sumLock: state.convergenceState.sumSatisfied,
                adjacencyLock: state.convergenceState.adjacencySatisfied,
                canonicalLock: state.canonicalDistance.distance(from: state.permutation) == 0
            )

            GridView(state: state)

            SigilView(
                geometry: state.sigilGeometry,
                isFrozen: state.isFrozen
            )
            .frame(width: SigilMetrics.frame, height: SigilMetrics.frame)
            .padding(.top, 24)

            if let signature = state.artifactSignature {
                ArtifactSignatureView(signature: signature)
                    .padding(.top, 12)
            }

            if state.hasArtifacts {
                VStack(spacing: 0) {
                    if state.artifact != nil {
                        Button("EXPORT ARTIFACT") {
                            state.exportArtifact()
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.top, 6)
                    }

                    Button("EXPORT ARCHIVE") {
                        state.exportArchive()
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.top, 6)

                    Button("CLEAR ARTIFACTS") {
                        state.clearArtifacts()
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.top, 4)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LaunchView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .foregroundStyle(.black)
        }
    }
}
