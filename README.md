<div align="center">
  
***`documentation-extract`***<br>`0.1.0`

</div>

`catalog` is a simple but powerful Swift Package Plugin for generating symbolgraphs and detecting DocC documentation resources in a project.

It’s like `swift-docc-plugin`, but it doesn’t actually build the documentation, it only generates and locates the resources required to build the documentation. This gives you all the power of the SPM’s symbolgraph and project scanning capabilities while still preserving the flexibility to use a documentation engine of your choice to document your project!

## getting started

`catalog` is a normal Swift Package Plugin, and you can use it (like any other plugin) by adding it to your `Package.swift` dependency list:

```swift 
let package:Package = .init(name: "example", products: [],
    dependencies: 
    [
        .package(url: "https://github.com/swift-biome/swift-documentation-extract", from: "0.1.0"),
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
        "package": "swift-json", 
        "modules": ["JSONExamples", "JSONBenchmarks", "JSON"],
        "include": 
        [
            ".build/x86_64-unknown-linux-gnu/extracted-symbols/swift-json/JSONExamples", 
            ".build/x86_64-unknown-linux-gnu/extracted-symbols/swift-json/JSONBenchmarks", 
            "sources/documentation.docc", 
            ".build/x86_64-unknown-linux-gnu/extracted-symbols/swift-json/JSON"
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
        "package": "swift-json", 
        "modules": ["JSON"],
        "include": 
        [
            "sources/documentation.docc", 
            ".build/x86_64-unknown-linux-gnu/extracted-symbols/swift-json/JSON"
        ]
    }
]
```

Target filtering is case-sensitive. 

```
$ swift package catalog json
error: target 'json' is not a swift source module in this package
```
