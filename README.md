<div align="center">
  
***`package-catalog`***<br>`0.2.1`

[![swift package index versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkelvin13%2Fswift-package-catalog%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/kelvin13/swift-package-catalog)
[![swift package index platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkelvin13%2Fswift-package-catalog%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/kelvin13/swift-package-catalog)


</div>

`catalog` is a simple but powerful Swift Package Plugin for generating symbolgraphs and detecting DocC documentation resources in a project.

It’s like `swift-docc-plugin`, but it doesn’t actually build the documentation, it only generates and locates the resources required to build the documentation. This gives you all the power of the SPM’s symbolgraph and project scanning capabilities while still preserving the flexibility to use a documentation engine of your choice to document your project!

`catalog` emits its output as JSON with a fairly straightforward format. Its output is designed to be easily transformed by downstream tooling that relocates, compresses, or otherwise post-processes the resource files the catalogs reference.

## getting started

`catalog` is a normal Swift Package Plugin, and you can use it (like any other plugin) by adding it to your `Package.swift` dependency list:

```swift 
let package:Package = .init(name: "example", products: [],
    dependencies: 
    [
        .package(url: "https://github.com/kelvin13/swift-package-catalog", from: "0.2.1"),
    ],
    targets: [])
```

## running `catalog`

Running `catalog` with `swift package` will output all the documentation resources it managed to find, in JSON format. Behind the scenes, it will direct the SPM to generate the relevant symbolgraphs.

```
$ swift package catalog 
Building for debugging...
Build complete! (0.07s)
Building for debugging...
Build complete! (0.07s)
Building for debugging...
Build complete! (0.07s)
[
    {
        "catalog_tools_version": 2,
        "package": "swift-grammar", 
        "modules": 
        [
            {
                "module": "Grammar",
                "dependencies": [],
                "include": 
                [
                    ".build/x86_64-unknown-linux-gnu/extracted-symbols/swift-grammar/Grammar"
                ]
            }
        ]
    }, 
    {
        "catalog_tools_version": 2,
        "package": "swift-json", 
        "modules": 
        [
            {
                "module": "JSON",
                "dependencies": [{"package": "swift-grammar", "modules": ["Grammar"]}],
                "include": 
                [
                    ".build/x86_64-unknown-linux-gnu/extracted-symbols/swift-json/JSON", 
                    "sources/json.docc"
                ]
            }, 
            {
                "module": "JSONExamples",
                "dependencies": [{"package": "swift-json", "modules": ["JSON"]}],
                "include": 
                [
                    ".build/x86_64-unknown-linux-gnu/extracted-symbols/swift-json/JSONExamples"
                ]
            }, 
            {
                "module": "JSONBenchmarks",
                "dependencies": [{"package": "swift-json", "modules": ["JSON"]}],
                "include": 
                [
                    ".build/x86_64-unknown-linux-gnu/extracted-symbols/swift-json/JSONBenchmarks"
                ]
            }
        ]
    }
]
```

> Note: Relative paths are shown for demonstration purposes. The `catalog` plugin actually emits absolute paths.

You can filter the modules `catalog` scans by passing them as positional arguments. The order does not matter.

```
$ swift package catalog JSON 
Building for debugging...
Build complete! (0.07s)
[
    {
        "catalog_tools_version": 2,
        "package": "swift-json", 
        "modules": 
        [
            {
                "module": "JSON",
                "dependencies": [{"package": "swift-grammar", "modules": ["Grammar"]}],
                "include": 
                [
                    "/home/klossy/dev/swift-json/.build/x86_64-unknown-linux-gnu/extracted-symbols/swift-json/JSON", 
                    "/home/klossy/dev/swift-json/sources/json.docc"
                ]
            }
        ]
    }
]
```

Target filtering is case-sensitive. 

```
$ swift package catalog json
error: target 'json' is not a swift source module in this package
```

Note that multiple modules with the same name can occur in a dependency tree, as long as colliding modules are never combined into the same product. This means that the number of modules cataloged by this tool may be greater than the number of arguments passed to its invocation.
