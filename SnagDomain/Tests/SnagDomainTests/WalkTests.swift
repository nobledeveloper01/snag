import Testing
@testable import SnagDomain

@Suite("The walk")
struct WalkTests {
    @Test("every template names at least a place to sleep, cook and wash, and none names a room twice by accident")
    func templates() {
        for t in RoomTemplate.allCases {
            #expect(t.rooms.contains(.kitchen), "\(t.word) has no kitchen")
            #expect(t.rooms.contains(.bathroom), "\(t.word) has no bathroom")
            #expect(!t.rooms.contains(.other))
            #expect(t.rooms.count >= 3 && t.rooms.count <= 12)
        }
        #expect(RoomTemplate.twoBed.rooms.filter { $0 == .bedroom }.count == 2)
        #expect(RoomTemplate.threeBed.rooms.filter { $0 == .bedroom }.count == 3)
    }

    @Test("one photograph is one item")
    func duplicate() {
        let r = Sample.report
        #expect(r.contains(photoHash: Sample.hash(5)))
        #expect(!r.contains(photoHash: Sample.hash(200)))
        #expect(!Report(kind: .moveIn, address: "x", createdAt: 0).contains(photoHash: Sample.hash(1)))
    }

    @Test("the timeline is the first photograph to the last, and nothing before one exists")
    func timeline() {
        let r = Sample.report
        #expect(r.walked?.first == 1_789_000_100)
        #expect(r.walked?.last == 1_789_000_500)
        #expect(r.minutesWalked == 6)
        #expect(Report(kind: .moveIn, address: "x", createdAt: 0).walked == nil)
        var one = Report(kind: .moveIn, address: "x", createdAt: 0, rooms: [Room(name: .kitchen, items: [Item(state: .fine, photoHash: Sample.hash(1), caption: "", takenAt: 50)])])
        #expect(one.minutesWalked == 0)
        one.rooms[0].items.append(Item(state: .fine, photoHash: Sample.hash(2), caption: "", takenAt: 50 + 179))
        #expect(one.minutesWalked == 2, "whole minutes, rounded down")
    }

    @Test("rooms that share a name are numbered; the rest are not")
    func labels() {
        var r = Report(kind: .moveIn, address: "x", createdAt: 0)
        r.rooms = RoomTemplate.twoBed.rooms.map { Room(name: $0) } + [Room(name: .other, custom: "Boys' quarters")]
        #expect(r.roomLabels == ["living room", "bedroom 1", "bedroom 2", "kitchen", "bathroom", "toilet", "balcony", "Boys' quarters"])
        #expect(Sample.report.roomLabels == ["living room", "Boys' quarters"])
    }
}
