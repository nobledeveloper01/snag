// Every string the app shows. One enum, so the copy gate and the tests read
// one list. Voice: plain, present tense, second person, no exclamation
// marks. Nothing here claims proof — ADR-0003 — and `make copy-check` reads
// this file for the words that would.
enum Strings {
    static var appName: String { t("Snag") }
    static var reports: String { t("Reports") }
    static var emptyTitle: String { t("Start with the flat you're standing in.") }
    static var emptyHint: String { t("Walk it room by room. Photograph what's wrong. Seal it before the boxes are in.") }
    static var newReport: String { t("New report") }
    static var address: String { t("Address") }
    static var addressPlaceholder: String { t("14 Admiralty Way, Lekki") }
    static var kind: String { t("Kind") }
    static var moveIn: String { t("Move-in") }
    static var moveOut: String { t("Move-out") }
    static var startWalk: String { t("Walk the flat") }
    static var addRoom: String { t("Add a room") }
    static var room: String { t("Room") }
    static var roomNamePlaceholder: String { t("What is this room called?") }
    static var nextRoom: String { t("Next room") }
    static var takePhoto: String { t("Photograph") }
    static var caption: String { t("What's wrong, in a sentence") }
    static var snag: String { t("Snag") }
    static var fine: String { t("Fine") }
    static var review: String { t("Review") }
    static var seal: String { t("Seal") }
    static var sealed: String { t("Sealed") }
    static var unaltered: String { t("Unaltered since signing") }
    static var altered: String { t("Altered") }
    static var alteredHint: String { t("This bundle has been changed since it was sealed. The report shown below may not be what was signed.") }
    static var datedByPhone: String { t("dated by the phone that made it") }
    static var items: String { t("items") }
    static var snags: String { t("snags") }
    static var done: String { t("Done") }
    static var cancel: String { t("Cancel") }
    static var tierPhotographed: String { t("photographed") }
    static var tierMeasured: String { t("measured") }
    static var tierScanned: String { t("scanned") }
    static var skip: String { t("Skip") }
    static var measureRoom: String { t("Measure this room") }
    static var measureHint: String { t("Tap each corner of the floor.") }
    static var scanRoom: String { t("Scan this room") }
    static var amend: String { t("Measure or scan later") }
    static var amendHint: String { t("Numbers can be added after the seal, on a phone that has the sensor. Nothing else changes: not a photograph, not a word, not the first signature. The amendment is sealed as its own layer beside it.") }
    static var noMeasurement: String { t("Photographed only") }
    static var sealAmendment: String { t("Seal the amendment") }
    static var amendedOn: String { t("Amended on") }
    static var scanHint: String { t("Walk the room slowly with the camera pointed at the walls. It stops when the room is closed.") }
    static var noSensor: String { t("This phone cannot do this. Photographed is the tier it has, and nothing is missing from the report because of it.") }
    static var fixtureCorners: String { t("Use the fixture room") }
    static var findingFloor: String { t("Finding the floor. Point the camera at it.") }
    static var corners: String { t("corners") }
    static var useMeasurement: String { t("Use this measurement") }
    static var undoCorner: String { t("Undo a corner") }
    static var useScan: String { t("Use this scan") }
    static var scanning: String { t("Scanning") }
    static var scanDone: String { t("Room closed.") }
    static var plan: String { t("Floor plan") }
    static var measuredLine: String { t("measured by tapping the corners") }
    static var scannedLine: String { t("scanned") }
    static var inProgress: String { t("In progress") }
    static var item: String { t("Item") }
    static var photograph: String { t("Photograph") }
    static var noCaption: String { t("No caption") }
    static var noItems: String { t("Nothing recorded in this room.") }
    static var roomEmptyHint: String { t("Photograph what's wrong. Photograph what's fine, too. A report that only lists faults reads as a complaint.") }
    static var sealHint: String { t("Sealing signs the report with a key that never leaves this phone. Nothing can be added or changed after.") }
    static var sealFailed: String { t("This phone could not sign the report. Try again.") }
    static var reportId: String { t("Report id") }
    static var sharePDF: String { t("Share PDF") }
    static var shareBundle: String { t("Share sealed bundle") }
    static var checking: String { t("Checking") }
    static var verifyTitle: String { t("Opened report") }
    static var counterSigned: String { t("Counter-signed by") }
    static var startWith: String { t("Start with") }
    static var emptyFlat: String { t("No rooms yet") }
    static var edit: String { t("Edit") }
    static var delete: String { t("Delete") }
    static var rename: String { t("Rename") }
    static var reorder: String { t("Reorder rooms") }
    static var doneReordering: String { t("Done reordering") }
    static var alreadyPhotographed: String { t("Already in the report") }
    static var alreadyPhotographedHint: String { t("Already in the report. One photograph is one item.") }
    static var reading: String { t("Reading") }
    static var units: String { t("units") }
    static var cubicMetres: String { t("cubic metres") }
    static var keysHandedOver: String { t("Keys handed over") }
    static var howMany: String { t("How many") }
    static var ok: String { t("OK") }
    static var lookAt: String { t("Look at") }
    static var torch: String { t("Torch") }
    static var walkedIn: String { t("Walked in") }
    static var settings: String { t("Settings") }
    static var language: String { t("Language") }
    static var translationDraft: String { t("This translation is a draft by the developer, not yet read by a native speaker. The English is the one the report was written in.") }
    static var lockTitle: String { t("Lock Snag") }
    static var lockHint: String { t("Face ID, Touch ID or the passcode before the reports are shown.") }
    static var lockUnavailable: String { t("This phone has no passcode, so there is nothing to lock with.") }
    static var locked: String { t("Snag is locked.") }
    static var unlock: String { t("Unlock") }
    static var unlockReason: String { t("Snag shows your reports after you unlock.") }
    static var unlockFailed: String { t("Not unlocked. Try again.") }
    static var nudgeTitle: String { t("Seal it before the boxes are in") }
    static var nudgeBody: String { t("this report is still a draft. Walk the last rooms and seal it.") }
    static var nudgeSetting: String { t("One quiet note if a report is still a draft a day later.") }
    static var backupHeader: String { t("Backup") }
    static var cloudHeader: String { t("iCloud") }
    static var cloudTitle: String { t("Keep a copy in my iCloud") }
    static var cloudHint: String { t("Every sealed report, in your own iCloud and on your other iPhones. Nobody else's server; each copy is checked before it is kept.") }
    static var syncNow: String { t("Sync now") }
    static var cloudSignIn: String { t("Sign in to iCloud on this phone first.") }
    static var cloudUp: String { t("Sent") }
    static var cloudDown: String { t("Received") }
    static var cloudFailed: String { t("iCloud did not answer. Try again later.") }
    static var backupHint: String { t("Every sealed report in one file, to Files or a drive of yours. On the way back each one is checked before it is kept.") }
    static var backup: String { t("Back up all reports") }
    static var nothingToBackUp: String { t("Nothing sealed yet to back up.") }
    static var restore: String { t("Restore from a backup") }
    static var restored: String { t("Restored") }
    static var refused: String { t("refused") }
    static var search: String { t("Find by address") }
    static var cannotBeRead: String { t("Cannot be read") }
    static var hideKeyboard: String { t("Hide keyboard") }
    static var matchesBroken: String { t("Matches a report on this phone that can no longer be read") }
    static var counterSign: String { t("Counter-sign") }
    static var counterSignHint: String { t("The other party signs on this phone, in front of you. Their name and number go with the signature, into the same sealed bundle.") }
    static var name: String { t("Name") }
    static var phone: String { t("Phone number") }
    static var signHere: String { t("Sign here") }
    static var clear: String { t("Clear") }
    static var sinceMoveIn: String { t("Since move-in") }
    static var linkMoveIn: String { t("Link to the move-in report") }
    static var noLink: String { t("No move-in report") }
    static var atMoveIn: String { t("At move-in") }
    static var sameView: String { t("Same view") }
    static var changeSame: String { t("same") }
    static var changeChanged: String { t("changed") }
    static var changeAdded: String { t("new") }
    static var changeMissing: String { t("not photographed this time") }
    static var remind: String { t("Remind me to walk out with Snag") }
    static var remindHint: String { t("A note in your own calendar for the day the tenancy ends, so the move-out walk happens before the keys go back.") }
    static var tenancyEnds: String { t("Tenancy ends") }
    static var addReminder: String { t("Add to my calendar") }
    static var reminderAdded: String { t("In your calendar.") }
    static var reminderDenied: String { t("Snag was not allowed to write to the calendar. You can allow it in Settings.") }
    static var checkPaper: String { t("Check a paper copy") }
    static var checkPaperHint: String { t("Point the camera at the square code on the cover, or type what it says.") }
    static var codeSays: String { t("What the code says") }
    static var check: String { t("Check") }
    static var scanner: String { t("Camera") }
    static var matches: String { t("Matches the report at") }
    static var keyDiffers: String { t("The id matches but the key does not. This paper was not made from the bundle on this phone.") }
    static var notHere: String { t("No report with this id on this phone.") }
    static var notACode: String { t("That is not a Snag code.") }
    static var shareMessage: String { t("A Snag condition report. Open it in Snag to check it has not changed since it was sealed. Report id:") }
    static var minutes: String { t("minutes") }
    static var on: String { t("On") }
    static var off: String { t("Off") }
    static var tooDark: String { t("Too dark to read later. Try the torch and take it again.") }
    static var blurred: String { t("Blurred. Hold still and take it again.") }
}
