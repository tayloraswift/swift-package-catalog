// swift-tools-version:5.6
import PackageDescription

let package:Package = .init(
    name: "swift-package-catalog",
    products: 
    [
        // .library(name: "PackageGraphs", targets: ["PackageGraphs"]),
        .plugin(name: "blame", targets: ["Blame"]),
        .plugin(name: "catalog", targets: ["Catalog"]),
    ],
    dependencies: 
    [
    ],
    targets: 
    [
        // .target(name: "PackageGraphs", dependencies: 
        // [
        // ]),
        
        .plugin(name: "Blame",
            capability: .command(intent: .custom(verb: "blame", description: "list consumers of a dependency")),
            dependencies: 
            [
                // .target(name: "PackageGraphs")
            ]),
        .plugin(name: "Catalog",
            capability: .command(intent: .custom(verb: "catalog", description: "extract symbolgraphs and documentation")),
            dependencies: 
            [
                //.target(name: "PackageGraphs")
            ]),
    ]
)
