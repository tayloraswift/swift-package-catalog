// swift-tools-version:5.6
import PackageDescription

let package:Package = .init(
    name: "swift-package-catalog",
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
            exclude: []),
    ]
)
