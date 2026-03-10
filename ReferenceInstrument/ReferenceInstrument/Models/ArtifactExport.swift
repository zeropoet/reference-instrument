import Foundation
import FoldKernel

struct ArtifactMetadata: Encodable {
    let artifactHash: String
    let memoryHash: String
    let eventCount: Int
    let kernel: String
    let timestamp: TimeInterval

    enum CodingKeys: String, CodingKey {
        case artifactHash = "artifact_hash"
        case memoryHash = "memory_hash"
        case eventCount = "event_count"
        case kernel
        case timestamp
    }
}

struct ArtifactPathExport: Encodable {
    let artifactHash: String
    let eventCount: Int
    let events: [ArtifactPathEvent]

    enum CodingKeys: String, CodingKey {
        case artifactHash = "artifact_hash"
        case eventCount = "event_count"
        case events
    }

    static func make(artifactHash: String, events: [FoldEvent]) -> ArtifactPathExport {
        ArtifactPathExport(
            artifactHash: artifactHash,
            eventCount: events.count,
            events: events.map(ArtifactPathEvent.init)
        )
    }
}

struct ArtifactPathEvent: Encodable {
    let type: String
    let values: [UInt8]?
    let bitmask: UInt8?
    let topology: UInt8?

    init(_ event: FoldEvent) {
        switch event {
        case .permutationCommit(let permutation):
            type = "permutation_commit"
            values = permutation.values
            bitmask = nil
            topology = nil
        case .lockStateChange(let state):
            type = "lock_state_change"
            values = nil
            bitmask = state
            topology = nil
        case .foldTopologyChange(let value):
            type = "fold_topology_change"
            values = nil
            bitmask = nil
            topology = value
        }
    }
}
