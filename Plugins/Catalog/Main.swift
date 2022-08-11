import PackagePlugin

@main 
struct Main:CommandPlugin
{
    func performCommand(context:PluginContext, arguments:[String]) throws 
    {
        // determine which products belong to which packages 
        let graph:PackageGraph = .init(context.package)
        let arguments:Set<String>? = arguments.isEmpty ? nil : .init(arguments)
        #if swift(>=5.7)
        var snippets:[Module<SwiftSourceModuleTarget>] = []
        #endif
        var modules:[Module<SwiftSourceModuleTarget>] = []
        var seen:Set<Target.ID> = []
        for target:any Target in context.package.targets 
        {
            graph.walk(target)
            {
                guard   let target:SwiftSourceModuleTarget = $0.target as? SwiftSourceModuleTarget, 
                        case nil = seen.update(with: $0.target.id)
                else 
                {
                    return 
                }
                let module:Module<SwiftSourceModuleTarget> = .init(target, in: $0.package)

                #if swift(>=5.7)
                if case .snippet = target.kind 
                {
                    snippets.append(module)
                    return 
                }
                #endif
                if  arguments?.contains(target.name) ?? true
                {
                    modules.append(module)
                }
            }
        }
        
        if let missing:String = arguments?.subtracting(modules.lazy.map(\.target.name)).first 
        {
            throw MissingTargetError.init(name: missing)
        }
        
        let options:PackageManager.SymbolGraphOptions = .init(
            minimumAccessLevel: .public,
            includeSynthesized: true,
            includeSPI: true)
        
        var packages:[Package.ID: Catalog] = [:]
        for module:Module<SwiftSourceModuleTarget> in modules 
        {
            let graphs:PackageManager.SymbolGraphResult = 
                try self.packageManager.getSymbolGraph(for: module.target, options: options)
            var include:[String] = [graphs.directoryPath.string]
            for file:File in module.target.sourceFiles
            {
                if  case .unknown = file.type, 
                    case "docc"?  = file.path.extension?.lowercased()
                {
                    include.append(file.path.string)
                }
            }
            
            packages[module.package, default: .init()].append(target: module.target, 
                dependencies: graph.dependencies(of: module), 
                include: include)
        }
        #if swift(>=5.7)
        for snippet:Module<SwiftSourceModuleTarget> in snippets
        {
            let sources:[String] = snippet.target.sourceFiles.compactMap 
            {
                if case .source = $0.type 
                {
                    return $0.path.string 
                }
                else 
                {
                    return nil 
                }
            }
            packages[snippet.package, default: .init()].append(snippet: snippet.target, 
                dependencies: graph.dependencies(of: snippet), 
                sources: sources)
        }
        #endif
        let object:String =
        """
        [\(packages.sorted { $0.key < $1.key }.map 
        { 
            """
            
                {
                    "catalog_tools_version": 3,
                    "package": "\($0.key)", 
                    "modules": 
                    [\($0.value.modules.joined(separator: ", "))
                    ],
                    "snippets": 
                    [\($0.value.snippets.joined(separator: ", "))
                    ]
                }
            """
        }.joined(separator: ", "))
        ]
        """
        print(object)
    }
}
