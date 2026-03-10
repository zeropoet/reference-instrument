import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

struct ArtifactQR {
    static let archiveBaseURL =
        "https://zeropoet.github.io/reference-instrument/artifact.html?hash="

    static func publicURL(for artifactHash: String) -> String {
        "\(archiveBaseURL)\(artifactHash)"
    }

    static func generate(url: String) -> UIImage? {
        let data = Data(url.utf8)

        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")

        let transform = CGAffineTransform(scaleX: 10, y: 10)

        if let output = filter.outputImage?.transformed(by: transform) {
            let context = CIContext()

            if let cgimg = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return nil
    }
}
