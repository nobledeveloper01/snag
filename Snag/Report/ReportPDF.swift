// The PDF a landlord reads. Drawn by hand, one room per page, the tier
// word beside every room, and the last page saying what the report is.
// The PDF is a rendering of the sealed bytes, never the other way round:
// nothing in it is signed, and it says so on its last page by pointing at
// the bundle.
import SnagDomain
import UIKit

enum ReportPDF {
    static let page = CGRect(x: 0, y: 0, width: 595, height: 842)   // A4 at 72 dpi
    static let margin: CGFloat = 48

    static func write(_ sealed: ReportStore.Sealed) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Snag-\(sealed.id.prefix(12)).pdf")
        try render(sealed.report, id: sealed.id, photos: { SnagBundle.photoURL(in: sealed.url, hash: $0) }).write(to: url)
        return url
    }

    static func render(_ r: Report, id: String, photos: (Hash) -> URL) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y = margin
            y = draw(ReportText.title, at: y, font: .boldSystemFont(ofSize: 26))
            y = draw(r.address, at: y + 6, font: .systemFont(ofSize: 15))
            y = draw("\(r.kind == .moveIn ? Strings.moveIn : Strings.moveOut) · \(Dates.short(r.createdAt)), \(Strings.datedByPhone)", at: y, font: .systemFont(ofSize: 11), color: .darkGray)
            y = draw("\(r.rooms.count) \(Strings.room.lowercased())s · \(r.itemCount) \(Strings.items) · \(r.snagCount) \(Strings.snags) · \(r.tier.word)", at: y, font: .systemFont(ofSize: 11), color: .darkGray)
            y = draw("\(Strings.reportId): \(id)", at: y + 4, font: .monospacedSystemFont(ofSize: 9, weight: .regular), color: .darkGray)
            for room in r.rooms {
                ctx.beginPage()
                y = margin
                y = draw("\(room.title)  ·  \(room.tier.word)", at: y, font: .boldSystemFont(ofSize: 18))
                if let w = room.width, let l = room.length {
                    y = draw("\(w.centimetres) × \(l.centimetres) cm · \(w.tier.word)", at: y, font: .systemFont(ofSize: 11), color: .darkGray)
                }
                if room.items.isEmpty { y = draw(Strings.noItems, at: y + 8, font: .systemFont(ofSize: 11), color: .darkGray) }
                for item in room.items {
                    if y > page.height - margin - 140 { ctx.beginPage(); y = margin }
                    let box = CGRect(x: margin, y: y, width: 120, height: 90)
                    if let img = UIImage(contentsOfFile: photos(item.photoHash).path) {
                        img.draw(in: fit(img.size, in: box))
                    } else {
                        UIColor.lightGray.setStroke(); UIBezierPath(rect: box).stroke()
                    }
                    var ty = y
                    ty = draw(item.state == .snag ? Strings.snag.uppercased() : Strings.fine.uppercased(), at: ty, x: margin + 132, font: .boldSystemFont(ofSize: 10), color: item.state == .snag ? UIColor(red: 0.7, green: 0.15, blue: 0.1, alpha: 1) : .darkGray)
                    ty = draw(item.caption.isEmpty ? Strings.noCaption : item.caption, at: ty, x: margin + 132, font: .systemFont(ofSize: 12))
                    ty = draw("\(Dates.short(item.takenAt)) · \(Tier.photographed.word) · \(SnagBundle.hex(item.photoHash).prefix(16))…", at: ty, x: margin + 132, font: .systemFont(ofSize: 9), color: .darkGray)
                    y = max(y + 90, ty) + 14
                }
            }
            ctx.beginPage()
            y = margin
            y = draw(ReportText.whatThisIs, at: y, font: .boldSystemFont(ofSize: 18))
            for para in ReportText.whatThisIsBody { y = draw(para, at: y + 8, font: .systemFont(ofSize: 11)) }
            y = draw("\(Strings.reportId): \(id)", at: y + 12, font: .monospacedSystemFont(ofSize: 9, weight: .regular), color: .darkGray)
        }
    }

    @discardableResult
    private static func draw(_ text: String, at y: CGFloat, x: CGFloat = margin, font: UIFont, color: UIColor = .black) -> CGFloat {
        let width = page.width - x - margin
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let bounds = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        (text as NSString).draw(with: CGRect(x: x, y: y, width: width, height: ceil(bounds.height)), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        return y + ceil(bounds.height) + 4
    }

    private static func fit(_ size: CGSize, in box: CGRect) -> CGRect {
        let s = min(box.width / size.width, box.height / size.height)
        let w = size.width * s, h = size.height * s
        return CGRect(x: box.minX + (box.width - w) / 2, y: box.minY + (box.height - h) / 2, width: w, height: h)
    }
}
