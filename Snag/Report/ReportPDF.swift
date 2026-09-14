// The PDF a landlord reads. Set in Inter, as the app is. A cover with the
// walk's timeline and a table of rooms; one page per room with the tier
// word beside it; a contact sheet of every photograph with its hash prefix,
// so paper can be matched to the bundle; and a last page saying what the
// report is. Every page carries the address, the id and "page n of N".
//
// The PDF is a rendering of the sealed bytes, never the other way round:
// nothing in it is signed, and it says so on its last page by pointing at
// the bundle. The QR on the cover carries the id and the key's fingerprint
// so *Check a paper copy* can match the paper to a bundle on a phone.
import CoreImage.CIFilterBuiltins
import SnagDomain
import UIKit

enum ReportPDF {
    static let page = CGRect(x: 0, y: 0, width: 595, height: 842)   // A4 at 72 dpi
    static let margin: CGFloat = 48
    static let footerHeight: CGFloat = 40

    static func write(_ sealed: ReportStore.Sealed, publicKey: [UInt8], movedIn: Report? = nil) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Snag-\(sealed.id.prefix(12)).pdf")
        let signature = sealed.counter.map { c in (c, UIImage(contentsOfFile: sealed.url.appendingPathComponent(SnagBundle.signatureImage).path)) }
        try render(sealed.report, id: sealed.id, publicKey: publicKey, movedIn: movedIn, signature: signature,
                   photos: { SnagBundle.photoURL(in: sealed.url, hash: $0) }).write(to: url)
        return url
    }

    /// The text the QR carries: the id, and the first eight bytes of the
    /// SHA-256 of the public key. Enough to match paper to a bundle; nothing
    /// that says the paper is true.
    static func qrPayload(id: String, publicKey: [UInt8]) -> String {
        "snag:1:\(id):\(SnagBundle.hex(Array(SnagBundle.sha256(Data(publicKey)).prefix(8))))"
    }

    static func render(_ r: Report, id: String, publicKey: [UInt8], movedIn: Report? = nil, signature: (CounterSignature, UIImage?)? = nil, photos: (Hash) -> URL) -> Data {
        // Two passes: the first counts pages so the second can print "of N".
        let count = draw(r, id: id, publicKey: publicKey, movedIn: movedIn, signature: signature, photos: photos, total: nil).pages
        return draw(r, id: id, publicKey: publicKey, movedIn: movedIn, signature: signature, photos: photos, total: count).data
    }

    private static func draw(_ r: Report, id: String, publicKey: [UInt8], movedIn: Report?, signature: (CounterSignature, UIImage?)?, photos: (Hash) -> URL, total: Int?) -> (data: Data, pages: Int) {
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        var pages = 0
        let labels = r.roomLabels
        let data = renderer.pdfData { ctx in
            func newPage() {
                ctx.beginPage()
                pages += 1
                footer(pages, of: total, address: r.address, id: id)
            }
            // --- Cover
            newPage()
            var y = margin
            y = text(ReportText.title, at: y, font: font(26, .bold))
            y = text(r.address, at: y + 6, font: font(15))
            y = text("\(r.kind == .moveIn ? Strings.moveIn : Strings.moveOut) · \(Dates.short(r.createdAt)), \(Strings.datedByPhone)", at: y, font: font(11), color: .darkGray)
            if let walked = r.walked, let minutes = r.minutesWalked {
                y = text("\(Strings.walkedIn) \(minutes) \(Strings.minutes): \(Dates.short(walked.first)) – \(Dates.short(walked.last))", at: y, font: font(11), color: .darkGray)
            }
            y = text("\(r.rooms.count) \(Strings.room.lowercased())s · \(r.itemCount) \(Strings.items) · \(r.snagCount) \(Strings.snags) · \(r.tier.word)", at: y, font: font(11), color: .darkGray)
            // QR, top right of the cover.
            if let qr = qrImage(qrPayload(id: id, publicKey: publicKey)) {
                qr.draw(in: CGRect(x: page.width - margin - 96, y: margin, width: 96, height: 96))
            }
            y = max(y, margin + 110)
            // The table of rooms.
            y = text(ReportText.rooms, at: y + 8, font: font(14, .semibold))
            let cols: [CGFloat] = [margin, margin + 230, margin + 300, margin + 370]
            y = row([ReportText.colRoom, ReportText.colItems, ReportText.colSnags, ReportText.colTier], at: y + 4, cols: cols, font: font(10, .semibold), color: .darkGray)
            for (i, room) in r.rooms.enumerated() {
                y = row([labels[i].sentenceCased, String(room.items.count), String(room.items.filter { $0.state == .snag }.count), room.tier.word], at: y, cols: cols, font: font(11))
                if y > page.height - margin - footerHeight - 20 { newPage(); y = margin }
            }
            // --- One page per room
            for (i, room) in r.rooms.enumerated() {
                newPage()
                y = margin
                y = text("\(labels[i].sentenceCased)  ·  \(room.tier.word)", at: y, font: font(18, .bold))
                if let w = room.width, let l = room.length {
                    y = text("\(w.centimetres) × \(l.centimetres) cm · \(w.tier.word)", at: y, font: font(11), color: .darkGray)
                }
                if room.items.isEmpty { y = text(Strings.noItems, at: y + 8, font: font(11), color: .darkGray) }
                for item in room.items {
                    if y > page.height - margin - footerHeight - 110 { newPage(); y = margin }
                    let box = CGRect(x: margin, y: y, width: 120, height: 90)
                    if let img = UIImage(contentsOfFile: photos(item.photoHash).path) {
                        img.draw(in: fit(img.size, in: box))
                    } else {
                        UIColor.lightGray.setStroke(); UIBezierPath(rect: box).stroke()
                    }
                    var ty = y
                    ty = text(item.state == .snag ? Strings.snag.uppercased() : Strings.fine.uppercased(), at: ty, x: margin + 132, font: font(10, .bold), color: item.state == .snag ? UIColor(red: 0.7, green: 0.15, blue: 0.1, alpha: 1) : .darkGray)
                    ty = text(item.caption.isEmpty ? Strings.noCaption : item.caption, at: ty, x: margin + 132, font: font(12))
                    ty = text("\(Dates.short(item.takenAt)) · \(Tier.photographed.word) · \(SnagBundle.hex(item.photoHash).prefix(16))…", at: ty, x: margin + 132, font: font(9), color: .darkGray)
                    y = max(y + 90, ty) + 14
                }
            }
            // --- Contact sheet: every photograph, small, with its hash prefix.
            let all = r.rooms.enumerated().flatMap { i, room in room.items.map { (labels[i].sentenceCased, $0) } }
            if !all.isEmpty {
                newPage()
                y = margin
                y = text(ReportText.contactSheet, at: y, font: font(18, .bold))
                y = text(ReportText.contactSheetHint, at: y, font: font(10), color: .darkGray)
                let cell: CGFloat = (page.width - 2 * margin - 3 * 8) / 4
                var col = 0
                for (label, item) in all {
                    if y + cell + 30 > page.height - margin - footerHeight { newPage(); y = margin; col = 0 }
                    let x = margin + CGFloat(col) * (cell + 8)
                    let box = CGRect(x: x, y: y, width: cell, height: cell * 0.75)
                    if let img = UIImage(contentsOfFile: photos(item.photoHash).path) { img.draw(in: fit(img.size, in: box)) }
                    else { UIColor.lightGray.setStroke(); UIBezierPath(rect: box).stroke() }
                    _ = text(label, at: box.maxY + 2, x: x, width: cell, font: font(8), color: .darkGray)
                    _ = text(String(SnagBundle.hex(item.photoHash).prefix(12)), at: box.maxY + 12, x: x, width: cell, font: mono(8), color: .darkGray)
                    col += 1
                    if col == 4 { col = 0; y += cell * 0.75 + 30 }
                }
            }
            // --- Against the move-in, when that report is to hand
            if let movedIn {
                newPage()
                y = margin
                y = text(ReportText.sinceMoveIn, at: y, font: font(18, .bold))
                y = text(ReportText.sinceMoveInHint, at: y, font: font(10), color: .darkGray)
                for line in Changes.lines(movedIn: movedIn, movedOut: r) {
                    if y > page.height - margin - footerHeight - 30 { newPage(); y = margin }
                    y = text("\(line.room) · \(line.text) — \(line.word)", at: y + 2, font: font(11))
                }
            }
            // --- The counter-signature, when there is one
            if let (c, image) = signature {
                newPage()
                y = margin
                y = text(ReportText.signaturePage, at: y, font: font(18, .bold))
                y = text("\(ReportText.signedBy) \(c.name) · \(c.phone)", at: y + 6, font: font(12))
                y = text("\(ReportText.signedAt) \(Dates.short(c.signedAt)), \(Strings.datedByPhone)", at: y, font: font(11), color: .darkGray)
                let box = CGRect(x: margin, y: y + 12, width: 340, height: 160)
                UIColor.lightGray.setStroke(); UIBezierPath(roundedRect: box, cornerRadius: 8).stroke()
                if let image { image.draw(in: fit(image.size, in: box.insetBy(dx: 8, dy: 8))) }
                y = box.maxY + 8
                y = text(SnagBundle.hex(c.signatureHash), at: y, font: mono(8), color: .darkGray)
            }
            // --- The last page
            newPage()
            y = margin
            y = text(ReportText.whatThisIs, at: y, font: font(18, .bold))
            for para in ReportText.whatThisIsBody { y = text(para, at: y + 8, font: font(11)) }
            y = text("\(Strings.reportId): \(id)", at: y + 12, font: mono(9), color: .darkGray)
        }
        return (data, pages)
    }

    // MARK: drawing

    static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        // Inter is bundled and registered by UIAppFonts; the variable font
        // answers to its family name. The system face only if it is missing.
        let base = UIFont(name: Type.family, size: size) ?? .systemFont(ofSize: size)
        let traits: [UIFontDescriptor.TraitKey: Any] = [.weight: weight]
        let desc = base.fontDescriptor.addingAttributes([.traits: traits])
        return UIFont(descriptor: desc, size: size)
    }
    static func mono(_ size: CGFloat) -> UIFont { .monospacedSystemFont(ofSize: size, weight: .regular) }

    private static func footer(_ n: Int, of total: Int?, address: String, id: String) {
        let y = page.height - footerHeight
        UIColor.lightGray.setStroke()
        let line = UIBezierPath(); line.move(to: CGPoint(x: margin, y: y)); line.addLine(to: CGPoint(x: page.width - margin, y: y)); line.stroke()
        _ = text("\(address) · \(id.prefix(16))…", at: y + 6, font: font(8), color: .darkGray)
        let pageText = total.map { "\(ReportText.page) \(n) \(ReportText.of) \($0)" } ?? "\(ReportText.page) \(n)"
        let attrs: [NSAttributedString.Key: Any] = [.font: font(8), .foregroundColor: UIColor.darkGray]
        let w = (pageText as NSString).size(withAttributes: attrs).width
        (pageText as NSString).draw(at: CGPoint(x: page.width - margin - w, y: y + 6), withAttributes: attrs)
    }

    @discardableResult
    private static func text(_ string: String, at y: CGFloat, x: CGFloat = margin, width: CGFloat? = nil, font: UIFont, color: UIColor = .black) -> CGFloat {
        let w = width ?? (page.width - x - margin)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let bounds = (string as NSString).boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        (string as NSString).draw(with: CGRect(x: x, y: y, width: w, height: ceil(bounds.height)), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        return y + ceil(bounds.height) + 4
    }

    private static func row(_ cells: [String], at y: CGFloat, cols: [CGFloat], font: UIFont, color: UIColor = .black) -> CGFloat {
        var bottom = y
        for (i, cell) in cells.enumerated() {
            let next = i + 1 < cols.count ? cols[i + 1] : page.width - margin
            bottom = max(bottom, text(cell, at: y, x: cols[i], width: next - cols[i] - 6, font: font, color: color))
        }
        return bottom
    }

    private static func fit(_ size: CGSize, in box: CGRect) -> CGRect {
        let s = min(box.width / size.width, box.height / size.height)
        let w = size.width * s, h = size.height * s
        return CGRect(x: box.minX + (box.width - w) / 2, y: box.minY + (box.height - h) / 2, width: w, height: h)
    }

    static func qrImage(_ payload: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let out = filter.outputImage else { return nil }
        let scaled = out.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cg = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
