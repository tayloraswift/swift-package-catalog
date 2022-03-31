// swift-tools-version:5.6
import PackageDescription

let package:Package = .init(
    name: "swift-documentation-extract",
    products: 
    [
        .plugin(name: "catalog", targets: ["Catalog"]),
    ],
    dependencies: 
    [
    ],
    targets: 
    [
        .plugin(name: "Catalog",
            capability: .command(intent: .custom(verb: "catalog", description: "extract symbolgraphs and documentation")),
            dependencies: [],
            path: "sources/catalog",
            exclude: []),
    ]
)
