import Foundation
import UIKit

struct ArchiveExporter {
    static func share(url: URL) {
        let controller = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .rootViewController?
            .present(controller, animated: true)
    }

    static func writeDocs(into exportDir: URL, artifactsDir: URL) {
        let docsDir = exportDir.appendingPathComponent("docs", isDirectory: true)

        try? FileManager.default.removeItem(at: docsDir)
        try? FileManager.default.createDirectory(
            at: docsDir,
            withIntermediateDirectories: true
        )

        let artifactFolders = (try? FileManager.default
            .contentsOfDirectory(atPath: artifactsDir.path)
            .sorted()) ?? []

        if let artifactsData = try? JSONEncoder().encode(artifactFolders) {
            try? artifactsData.write(
                to: docsDir.appendingPathComponent("artifacts.json")
            )
        }
    }
}
