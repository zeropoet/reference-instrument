import SwiftUI

struct CellView: View {
    let value: UInt8
    let frozen: Bool
    let isSelected: Bool
    @State private var settleOffset: CGFloat = 0
    @State private var numberColor: Color = .black

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    frozen
                    ? Color.black
                    : isSelected
                        ? Color.black
                        : Color.white
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.black, lineWidth: 1)
                )
                .frame(
                    width: InstrumentMetrics.cellSize,
                    height: InstrumentMetrics.cellSize
                )

            Text("\(value)")
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(
                    frozen
                    ? numberColor
                    : isSelected
                        ? Color.white
                        : Color.black
                )
                .offset(y: -0.5 + settleOffset)
        }
        .onAppear {
            numberColor = frozen ? .white : .black
        }
        .onChange(of: value) { _, _ in
            guard !frozen else { return }

            withAnimation(.linear(duration: InstrumentTiming.settle)) {
                settleOffset = 0.5
            }

            withAnimation(
                .linear(duration: InstrumentTiming.settle)
                    .delay(InstrumentTiming.settle)
            ) {
                settleOffset = 0
            }
        }
        .onChange(of: frozen) { _, isNowFrozen in
            if isNowFrozen {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + InstrumentTiming.numberInvertDelay
                ) {
                    withAnimation(.linear(duration: InstrumentTiming.numberInvert)) {
                        numberColor = .white
                    }
                }
            } else {
                numberColor = .black
            }
        }
    }
}
