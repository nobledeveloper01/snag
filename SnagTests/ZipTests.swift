// One file: the bundle zipped, unzipped, and verified either way.
import XCTest
import SnagDomain
@testable import Snag

@MainActor
final class ZipTests: XCTestCase {
    func testAnArchiveRoundTripsAndRefusesEscapes() throws {
        let entries = [ZipFile.Entry(name: "a/b.txt", data: Data("hello".utf8)), ZipFile.Entry(name: "z.bin", data: Data((0..<1000).map { UInt8($0 & 0xff) }))]
        let zipped = ZipFile.archive(entries)
        let back = try ZipFile.entries(zipped)
        XCTAssertEqual(back.map(\.name), ["a/b.txt", "z.bin"])
        XCTAssertEqual(back.map(\.data), entries.map(\.data))
        XCTAssertThrowsError(try ZipFile.entries(Data("not a zip at all, not even close".utf8)))
        var flipped = zipped
        flipped[40] ^= 0x01     // inside the first entry's bytes
        XCTAssertThrowsError(try ZipFile.entries(flipped), "a flipped byte fails the CRC")
        let escaping = ZipFile.archive([ZipFile.Entry(name: "../etc/passwd", data: Data())])
        XCTAssertThrowsError(try ZipFile.extract(escaping, to: FileManager.default.temporaryDirectory.appendingPathComponent("zip-\(UUID())")))
    }

    func testADeflatedZipFromAnotherToolOpens() throws {
        // `zip -X` on macOS deflated this: one entry "long.txt" holding
        // "hello snag\n" forty times, 440 bytes in 18. Bytes checked in so
        // the reader is proved against somebody else's writer, not its own.
        let hex = "504b030414000000080026102e5d66918ebc12000000b8010000080000006c6f" +
                  "6e672e747874cb48cdc9c95728ce4b4ce7ca18650e1d2600504b01021e031400" +
                  "0000080026102e5d66918ebc12000000b8010000080000000000000001000000" +
                  "a481000000006c6f6e672e747874504b05060000000001000100360000003800" +
                  "00000000"
        var data = Data()
        var i = hex.startIndex
        while i < hex.endIndex { let j = hex.index(i, offsetBy: 2); data.append(UInt8(hex[i..<j], radix: 16)!); i = j }
        let entries = try ZipFile.entries(data)
        XCTAssertEqual(entries.first?.name, "long.txt")
        XCTAssertEqual(entries.first.map { String(decoding: $0.data, as: UTF8.self) }, String(repeating: "hello snag\n", count: 40))
    }

    func testASealedBundleZipsAndVerifiesAsOneFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("zipstore-\(UUID())")
        let store = ReportStore(root: root)
        var d = store.newDraft(kind: .moveIn, address: "1 Zip Lane", now: 1_789_000_000)
        let photo = try Data(contentsOf: XCTUnwrap(Bundle.main.url(forResource: "fixture-1", withExtension: "jpg")))
        let h = store.store(photo: photo, in: d)
        d.report.rooms = [Room(name: .kitchen, items: [Item(state: .snag, photoHash: h, caption: "Tile", takenAt: 1_789_000_100)])]
        store.update(d)
        let sealed = try store.seal(d, with: try Sealer())
        let zip = try SnagBundle.zip(sealed.url)
        XCTAssertEqual(zip.pathExtension, "snagz")
        let opened = Verifier.open(zip)
        guard case .unaltered(let r, _) = opened.verdict else { return XCTFail("the one-file bundle verifies: \(opened.verdict)") }
        XCTAssertEqual(r.address, "1 Zip Lane")
        XCTAssertTrue(FileManager.default.fileExists(atPath: SnagBundle.photoURL(in: opened.dir, hash: h).path), "the photograph came out of the file")
        var bytes = try Data(contentsOf: zip)
        // Flip a byte inside report.bin's entry: the zip's CRC catches it
        // first, and the answer is still not "unaltered".
        let idx = try XCTUnwrap(bytes.range(of: Data("report.bin".utf8))?.upperBound) + 5
        bytes[idx] ^= 0x01
        let tampered = zip.deletingLastPathComponent().appendingPathComponent("t.snagz")
        try bytes.write(to: tampered)
        XCTAssertNotEqual(Verifier.open(tampered).verdict, .unaltered(r, nil))
        try? FileManager.default.removeItem(at: root)
    }
}
