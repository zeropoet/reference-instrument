import Foundation
import FoldKernel

struct ArtifactHash {
    static func compute(
        memorySignature: [UInt8],
        svg: String
    ) -> [UInt8] {
        let svgBytes = Array(svg.utf8)
        let combined = memorySignature + svgBytes
        return Keccak256().hash(combined)
    }
}
