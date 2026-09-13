// swift-tools-version: 6.0
//
// The domain, as a package, so that it can be tested with `swift test` on
// macOS in seconds and cannot import anything the app has. ADR-0002: it owns
// the bytes every signature is over.
import PackageDescription

let package = Package(
    name: "SnagDomain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SnagDomain", targets: ["SnagDomain"])],
    targets: [
        .target(name: "SnagDomain"),
        .testTarget(name: "SnagDomainTests", dependencies: ["SnagDomain"], resources: [.copy("Fixtures")]),
    ]
)
