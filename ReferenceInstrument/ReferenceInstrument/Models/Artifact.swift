import Foundation

struct Artifact: Codable {
    let hash: String
    let memoryHash: String
    let svg: String
    let eventCount: Int
    let timestamp: TimeInterval

    var displayHash: String {
        String(hash.prefix(9))
    }

    var baseFilename: String {
        displayHash
    }

    var svgFilename: String {
        "\(baseFilename).svg"
    }

    var artifactHashFilename: String {
        "\(baseFilename).artifact-hash.txt"
    }

    var memoryHashFilename: String {
        "\(baseFilename).memory-hash.txt"
    }

    var metadataFilename: String {
        "\(baseFilename).metadata.json"
    }

    var qrFilename: String {
        "\(baseFilename).artifact-qr.png"
    }

    var pathFilename: String {
        "path.json"
    }
}
