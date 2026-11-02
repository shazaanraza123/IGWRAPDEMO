import SwiftUI
import UIKit

/// Archivo line for a Wrapped card. Sizes come from `CardSpace` or a text style.
struct CardText: View {
    var text: String
    var size: CGFloat
    var weight: CGFloat = CardSpace.heavy
    var width: CGFloat = CardSpace.condensed
    var tracking: CGFloat = 0
    var lineHeight: CGFloat = 1
    var color: Color
    var uppercase: Bool = false
    var alignment: TextAlignment = .leading

    var body: some View {
        Text(styled)
    }

    private var styled: AttributedString {
        let font = ArchivoFont.uiFont(size: size, weight: weight, width: width)
        let paragraph = NSMutableParagraphStyle()
        switch alignment {
        case .center: paragraph.alignment = .center
        case .trailing: paragraph.alignment = .right
        default: paragraph.alignment = .left
        }
        if lineHeight < 1 {
            let height = size * lineHeight
            paragraph.minimumLineHeight = height
            paragraph.maximumLineHeight = height
        }
        let raw = uppercase ? text.uppercased() : text
        let mutable = NSMutableAttributedString(
            string: raw,
            attributes: [
                .font: font,
                .kern: tracking,
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor(color)
            ]
        )
        if lineHeight < 1 {
            let height = size * lineHeight
            let offset = (height - font.lineHeight) / 2
            mutable.addAttribute(.baselineOffset, value: offset, range: NSRange(location: 0, length: mutable.length))
        }
        return AttributedString(mutable)
    }
}

enum BundlePhoto {
    static func image(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}
