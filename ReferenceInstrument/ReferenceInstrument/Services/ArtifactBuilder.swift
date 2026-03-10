import Foundation
import FoldKernel
import SigilEngine

struct ArtifactBuilder {
    static func build(
        events: [FoldEvent],
        canonicalDistance: CanonicalDistance,
        convergenceEvaluator: ConvergenceEvaluator
    ) -> Artifact {
        let encoder = MemoryEncoder()
        let memory = encoder.encode(events)

        let memoryHashBytes = HashEngine().convergenceHash(memorySignature: memory)
        let memoryHash = memoryHashBytes
            .map { String(format: "%02x", $0) }
            .joined()

        let generator = SigilGenerator()
        let geometry = generator.generate(
            events: events,
            canonicalDistance: canonicalDistance,
            convergenceEvaluator: convergenceEvaluator
        )

        let svg = SigilSVGExporter.export(geometry: geometry)
        let artifactHashBytes = ArtifactHash.compute(
            memorySignature: memory,
            svg: svg
        )
        let artifactHash = artifactHashBytes
            .map { String(format: "%02x", $0) }
            .joined()

        return Artifact(
            hash: artifactHash,
            memoryHash: memoryHash,
            svg: svg,
            eventCount: events.count,
            timestamp: Date().timeIntervalSince1970
        )
    }
}
