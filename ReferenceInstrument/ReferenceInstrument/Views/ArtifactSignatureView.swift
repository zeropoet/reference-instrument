import SwiftUI

struct ArtifactSignatureView: View {
    let signature: String

    @State private var visible: Bool = false

    var body: some View {
        Text(signature)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(
                    .easeIn(duration: 0.4)
                        .delay(InstrumentTiming.sigil)
                ) {
                    visible = true
                }
            }
    }
}
