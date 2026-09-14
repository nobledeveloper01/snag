// What a Lagos flat has and a tenant forgets to look at. One tap on a
// prompt photographs with the caption started; the tenant finishes the
// sentence or does not. Two of them — the meter and the keys — ask for a
// number, and the number goes in the caption, which is the tenant's word
// and not one the app made. Read by the copy gate.
import SnagDomain

enum Prompts {
    static var meter: String { t("Prepaid meter") }
    static var waterMeter: String { t("Water meter") }
    static var keys: String { t("Keys") }

    static func forRoom(_ name: RoomName) -> [String] {
        let own: [String] = switch name {
        case .livingRoom: ["Ceiling", "Paint", "Sockets", "Windows", "Curtain rail", "Door lock", "AC"]
        case .bedroom: ["Wardrobe", "AC", "Window nets", "Burglary bars", "Ceiling", "Paint", "Sockets"]
        case .kitchen: ["Tap", "Sink", "Sockets", "Tiles", "Cabinets", "Gas point", "Drain"]
        case .bathroom: ["Shower", "Water heater", "Tiles", "Flush", "Wash basin", "Drain"]
        case .toilet: ["Flush", "Seat", "Drain", "Door lock", "Tiles"]
        case .balcony: ["Railing", "Floor", "Drain", "Door"]
        case .corridor: ["Light", "Paint", "Floor", "Door lock"]
        case .store: ["Shelves", "Door", "Damp"]
        case .other: []
        }
        return own.map(t) + [meter, waterMeter, keys]
    }

    /// The prompts that ask for a number, and what the number is.
    enum Kind: Equatable {
        case plain, meter, keys
        static func of(_ prompt: String?) -> Kind {
            switch prompt {
            case Prompts.meter?, Prompts.waterMeter?: .meter
            case Prompts.keys?: .keys
            default: .plain
            }
        }
    }
}
