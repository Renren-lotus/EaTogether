//
//  QRCodeImageView.swift
//  EaTogether
//
//  Created by Codex on 2026/06/08.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

/// 文字列をQRコード画像として表示します。
struct QRCodeImageView: View {
    let text: String

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = makeQRCodeImage(from: text) {
            Image(decorative: image, scale: 1.0)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("グループ共有用QRコード")
        } else {
            Text("QRコードを作成できませんでした。")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 160)
        }
    }

    /// QRコード用のCGImageを作ります。
    private func makeQRCodeImage(from text: String) -> CGImage? {
        guard let data = text.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        return context.createCGImage(scaledImage, from: scaledImage.extent)
    }
}

#Preview {
    QRCodeImageView(text: "A3FK9Q")
        .frame(width: 180, height: 180)
        .padding()
}
