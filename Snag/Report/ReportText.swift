// The words the PDF prints that are not the tenant's own. Read by the copy
// gate; the last page is where the report says what it is and is not.
enum ReportText {
    static let title = "Condition report"
    static let whatThisIs = "What this report is"
    static let whatThisIsBody = [
        "The photographs in this report were taken by the Snag app and hashed at the moment of capture. The report was sealed by a key that never left the phone that made it, and the sealed bundle has not been altered since — the app that opens it says so, or says that it has.",
        "The date and time are the phone's own. No server was involved and none checked the clock.",
        "A counter-signature, where present, is a name, a phone number and a signature drawn on this phone in the presence of the tenant, recorded at the time shown.",
        "Every measurement carries the word for how it was made: photographed, measured, or scanned. A photographed room has no measurements.",
        "This report records the condition of the rooms as the parties saw them. It does not say what any party owes.",
    ]
}
