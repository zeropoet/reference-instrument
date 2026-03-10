import Combine
import Foundation
import FoldKernel
import SigilEngine
import SwiftUI
import UIKit

final class InstrumentState: ObservableObject {
    @Published var permutation: Permutation
    @Published var selectedIndex: Int? = nil
    @Published var events: [FoldEvent] = []
    @Published var isFrozen: Bool = false
    @Published var convergenceState: ConvergenceState
    @Published var artifact: Artifact?
    @Published var artifactSignature: String? = nil

    let canonicalSet: Set<Permutation>
    let adjacencyGraph: AdjacencyGraph
    let invariantEvaluator: InvariantEvaluator
    let canonicalDistance: CanonicalDistance
    let convergenceEvaluator: ConvergenceEvaluator
    let memoryEncoder = MemoryEncoder()
    let hashEngine = HashEngine()
    let sigilGenerator = SigilGenerator()
    private var stabilityTask: Task<Void, Never>?
    private var loggedPathHashes: Set<String> = []

    var memorySignature: [UInt8] {
        memoryEncoder.encode(events)
    }

    var convergenceHash: [UInt8] {
        hashEngine.convergenceHash(memorySignature: memorySignature)
    }

    var sigilGeometry: SigilGeometry {
        sigilGenerator.generate(
            events: events,
            canonicalDistance: canonicalDistance,
            convergenceEvaluator: convergenceEvaluator
        )
    }

    var hasArtifacts: Bool {
        let artifactsDir = Self.documentsDirectory().appendingPathComponent("artifacts")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: artifactsDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        return !contents.isEmpty
    }

    init() {
        let s0 = CanonicalSquare.S0

        let orbit = Set(
            SymmetryTransform.allCases.map {
                $0.apply(to: s0)
            }
        )

        canonicalSet = orbit
        adjacencyGraph = AdjacencyGraph(from: s0)
        invariantEvaluator = InvariantEvaluator()
        canonicalDistance = CanonicalDistance(canonicalSet: orbit)
        convergenceEvaluator = ConvergenceEvaluator(
            canonicalSet: orbit,
            adjacencyGraph: adjacencyGraph,
            invariantEvaluator: invariantEvaluator,
            canonicalDistance: canonicalDistance
        )

        let initialPermutation = InstrumentState.makeRandomPermutation()
        permutation = initialPermutation
        convergenceState = convergenceEvaluator.evaluate(initialPermutation)
    }

    func swap(_ i: Int, _ j: Int) {
        var values = permutation.values

        values.swapAt(i, j)

        if let newPermutation = try? Permutation(values) {
            permutation = newPermutation
            events.append(.permutationCommit(newPermutation))
            convergenceState = convergenceEvaluator.evaluate(permutation)
            logCurrentPathIfNeeded()
            evaluateStability()
        }
    }

    func tap(index: Int) {
        guard !isFrozen else { return }

        if let selected = selectedIndex {
            swap(selected, index)
            selectedIndex = nil
        } else {
            selectedIndex = index
        }
    }

    func evaluateStability() {
        guard !isFrozen else { return }

        let hasOrbitConverged =
            canonicalDistance.distance(from: permutation) == 0

        if convergenceState.sumSatisfied &&
            convergenceState.adjacencySatisfied &&
            hasOrbitConverged {
            stabilityTask?.cancel()

            stabilityTask = Task {
                try? await Task.sleep(nanoseconds: 3_200_000_000)

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard !self.isFrozen else { return }

                    let generator = UIImpactFeedbackGenerator(style: .rigid)
                    generator.prepare()
                    generator.impactOccurred(intensity: 0.7)

                    withAnimation(.easeInOut(duration: InstrumentTiming.collapse)) {
                        self.isFrozen = true
                    }

                    let artifact = ArtifactBuilder.build(
                        events: self.events,
                        canonicalDistance: self.canonicalDistance,
                        convergenceEvaluator: self.convergenceEvaluator
                    )
                    self.artifact = artifact
                    self.artifactSignature = artifact.baseFilename
                    self.saveArtifact()
                }
            }
        } else {
            stabilityTask?.cancel()
        }
    }

    func saveArtifact() {
        guard let artifact else { return }

        for root in Self.artifactStorageRoots() {
            let dir = root.appendingPathComponent("artifacts")
            let artifactDir = dir.appendingPathComponent(artifact.hash)

            Self.writeArtifact(artifact, events: events, to: artifactDir)
        }
    }

    func exportArchive() {
        let docs = Self.documentsDirectory()
        let artifactsDir = docs.appendingPathComponent("artifacts", isDirectory: true)
        let exportDir = docs.appendingPathComponent(
            "reference-instrument-export",
            isDirectory: true
        )

        guard FileManager.default.fileExists(atPath: artifactsDir.path) else {
            return
        }

        try? FileManager.default.removeItem(at: exportDir)
        try? FileManager.default.createDirectory(
            at: exportDir,
            withIntermediateDirectories: true
        )

        let targetArtifacts = exportDir.appendingPathComponent("artifacts", isDirectory: true)
        try? FileManager.default.copyItem(
            at: artifactsDir,
            to: targetArtifacts
        )

        ArchiveExporter.writeDocs(into: exportDir, artifactsDir: artifactsDir)
        ArchiveExporter.share(url: exportDir)
    }

    func exportArtifact() {
        guard let artifact else { return }

        let artifactDir = Self.documentsDirectory()
            .appendingPathComponent("artifacts", isDirectory: true)
            .appendingPathComponent(artifact.hash, isDirectory: true)

        guard FileManager.default.fileExists(atPath: artifactDir.path) else {
            return
        }

        ArchiveExporter.share(url: artifactDir)
    }

    func clearArtifacts() {
        let docs = Self.documentsDirectory()
        let artifactsDir = docs.appendingPathComponent("artifacts", isDirectory: true)
        let pathDir = docs.appendingPathComponent("path-log", isDirectory: true)

        try? FileManager.default.removeItem(at: artifactsDir)
        try? FileManager.default.removeItem(at: pathDir)

        artifact = nil
        artifactSignature = nil
        loggedPathHashes.removeAll()
    }

    private func logCurrentPathIfNeeded() {
        let artifact = ArtifactBuilder.build(
            events: events,
            canonicalDistance: canonicalDistance,
            convergenceEvaluator: convergenceEvaluator
        )

        guard !artifact.svg.isEmpty else { return }

        if loggedPathHashes.contains(artifact.hash) {
            return
        }

        loggedPathHashes.insert(artifact.hash)

        for root in Self.artifactStorageRoots() {
            let dir = root.appendingPathComponent("path-log")
            let artifactDir = dir.appendingPathComponent(artifact.hash)

            if FileManager.default.fileExists(atPath: artifactDir.path) {
                continue
            }

            Self.writeArtifact(artifact, events: events, to: artifactDir)
        }
    }

    private static func makeRandomPermutation() -> Permutation {
        try! Permutation(Array(UInt8(1)...UInt8(16)).shuffled())
    }

    private static func documentsDirectory() -> URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }

    private static func artifactStorageRoots() -> [URL] {
        var roots: [URL] = [documentsDirectory()]

        if let override = ProcessInfo.processInfo.environment["REFERENCE_INSTRUMENT_ARTIFACTS_DIR"],
            !override.isEmpty {
            let mirrorRoot = URL(fileURLWithPath: override, isDirectory: true)
            if !roots.contains(mirrorRoot) {
                roots.append(mirrorRoot)
            }
        }

        return roots
    }

    private static func writeArtifact(
        _ artifact: Artifact,
        events: [FoldEvent],
        to artifactDir: URL
    ) {
        try? FileManager.default.createDirectory(
            at: artifactDir,
            withIntermediateDirectories: true
        )

        try? artifact.svg.write(
            to: artifactDir.appendingPathComponent(artifact.svgFilename),
            atomically: true,
            encoding: .utf8
        )

        try? artifact.hash.write(
            to: artifactDir.appendingPathComponent(artifact.artifactHashFilename),
            atomically: true,
            encoding: .utf8
        )

        try? artifact.memoryHash.write(
            to: artifactDir.appendingPathComponent(artifact.memoryHashFilename),
            atomically: true,
            encoding: .utf8
        )

        let metadata = ArtifactMetadata(
            artifactHash: artifact.hash,
            memoryHash: artifact.memoryHash,
            eventCount: artifact.eventCount,
            kernel: "FoldKernel-1.0.0",
            timestamp: artifact.timestamp
        )
        if let metadataData = try? JSONEncoder().encode(metadata) {
            try? metadataData.write(
                to: artifactDir.appendingPathComponent(artifact.metadataFilename)
            )
        }

        let path = ArtifactPathExport.make(
            artifactHash: artifact.hash,
            events: events
        )
        if let pathData = try? JSONEncoder().encode(path) {
            try? pathData.write(
                to: artifactDir.appendingPathComponent(artifact.pathFilename)
            )
        }

        if let legacyMetadata = try? JSONEncoder().encode(metadata) {
            try? legacyMetadata.write(
                to: artifactDir.appendingPathComponent("metadata.json")
            )
        }

        if let legacyPath = try? JSONEncoder().encode(path) {
            try? legacyPath.write(
                to: artifactDir.appendingPathComponent("path.json")
            )
        }

        if let legacyArtifactHash = artifact.hash.data(using: .utf8) {
            try? legacyArtifactHash.write(
                to: artifactDir.appendingPathComponent("artifact_hash.txt")
            )
        }

        if let legacyMemoryHash = artifact.memoryHash.data(using: .utf8) {
            try? legacyMemoryHash.write(
                to: artifactDir.appendingPathComponent("memory_hash.txt")
            )
        }

        if let legacySVG = artifact.svg.data(using: .utf8) {
            try? legacySVG.write(
                to: artifactDir.appendingPathComponent("sigil.svg")
            )
        }

        let publicURL = ArtifactQR.publicURL(for: artifact.hash)
        if let qrImage = ArtifactQR.generate(url: publicURL),
            let pngData = qrImage.pngData() {
            try? pngData.write(
                to: artifactDir.appendingPathComponent(artifact.qrFilename)
            )

            try? pngData.write(
                to: artifactDir.appendingPathComponent("artifact_qr.png")
            )
        }
    }
}
