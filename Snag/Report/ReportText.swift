// The words the PDF prints that are not the tenant's own. Read by the copy
// gate; the last page is where the report says what it is and is not.
enum ReportText {
    static var title: String { t("Condition report") }
    static var rooms: String { t("Rooms") }
    static var colRoom: String { t("Room") }
    static var colItems: String { t("Items") }
    static var colSnags: String { t("Snags") }
    static var colTier: String { t("Tier") }
    static var contactSheet: String { t("Every photograph") }
    static var contactSheetHint: String { t("Each photograph with the first twelve characters of its hash. The bundle names each photograph by its full hash, so a print can be matched to the file it came from.") }
    static var signaturePage: String { t("Counter-signature") }
    static var signedBy: String { t("Signed by") }
    static var signedAt: String { t("at") }
    static var sinceMoveIn: String { t("Against the move-in report") }
    static var sinceMoveInHint: String { t("Item by item, in the order of the move-in report: the same photograph and state, a change, something new, or something not photographed this time. What a change is worth is not for this page.") }
    static var amendedNote: String { t("the numbers were added after the seal, as a second signed layer; the first seal and every photograph stand as they were") }
    static var page: String { t("Page") }
    static var of: String { t("of") }
    static var whatThisIs: String { t("What this report is") }
    /// The English, always — the report was written in it — and, below it,
    /// the tenant's language when that is another.
    static var whatThisIsBodyEnglish: [String] { whatThisIsBodySource }
    static var whatThisIsBody: [String] { whatThisIsBodySource.map(t) }
    private static let whatThisIsBodySource = [
        "The photographs in this report were taken by the Snag app and hashed at the moment of capture. The report was sealed by a key that never left the phone that made it, and the sealed bundle has not been altered since — the app that opens it says so, or says that it has.",
        "The date and time are the phone's own. No server was involved and none checked the clock.",
        "A counter-signature, where present, is a name, a phone number and a signature drawn on this phone in the presence of the tenant, recorded at the time shown.",
        "Every measurement carries the word for how it was made: photographed, measured, or scanned. A photographed room has no measurements.",
        "This report records the condition of the rooms as the parties saw them. It does not say what any party owes.",
    ]
}
