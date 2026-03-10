import SwiftUI
import FoldKernel

struct GridView: View {
    @ObservedObject var state: InstrumentState

    var body: some View {
        let values = state.permutation.values

        LazyVGrid(
            columns: Array(
                repeating: GridItem(
                    .fixed(InstrumentMetrics.cellSize),
                    spacing: InstrumentMetrics.gridSpacing
                ),
                count: 4
            ),
            spacing: InstrumentMetrics.gridSpacing
        ) {
            ForEach(0..<16, id: \.self) { index in
                CellView(
                    value: values[index],
                    frozen: state.isFrozen,
                    isSelected: state.selectedIndex == index
                )
                .onTapGesture {
                    state.tap(index: index)
                }
            }
        }
        .frame(width: InstrumentMetrics.gridWidth)
        .animation(
            .easeInOut(duration: InstrumentTiming.swap),
            value: state.permutation
        )
    }
}
