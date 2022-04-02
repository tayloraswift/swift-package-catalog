import PackagePlugin

enum DocumentationExtractionError:Error, CustomStringConvertible
{
    case missingTarget(String)
    
    var description:String 
    {
        switch self 
        {
        case .missingTarget(let target): 
            return "target '\(target)' is not a swift source module in this package"
        }
    }
}

extension Target 
{
    func gather(dependencies:inout [String: SwiftSourceModuleTarget])
    {
        if let target:SwiftSourceModuleTarget = self as? SwiftSourceModuleTarget 
        {
            dependencies[target.id] = target
        }
        for dependency:TargetDependency in self.dependencies 
        {
            switch dependency 
            {
            case .target(let target):
                target.gather(dependencies: &dependencies)
            case .product(let product):
                for target:any Target in product.targets 
                {
                    target.gather(dependencies: &dependencies)
                }
            }
        }
    }
}
extension Package
{
    func gather(nationalities:inout [String: Package])
    {
        for dependency:PackageDependency in self.dependencies 
        {
            dependency.package.gather(nationalities: &nationalities)
        }
        for target:any Target in self.targets
        {
            nationalities[target.id] = self
        }
    }
}
@main 
struct Main:CommandPlugin
{
    func performCommand(context:PluginContext, arguments:[String]) throws 
    {
        // determine which targets belong to which packages 
        var nationalities:[String: Package] = [:]
        context.package.gather(nationalities: &nationalities)
        
        var targets:[String: SwiftSourceModuleTarget] = [:]
        for target:any Target in context.package.targets
        {
            target.gather(dependencies: &targets)
        }
        
        var invited:Set<String> = .init(arguments)
        let filtered:[SwiftSourceModuleTarget] = targets.values.filter
        {
            arguments.isEmpty || invited.contains($0.name)
        }
        
        let options:PackageManager.SymbolGraphOptions = .init(
            minimumAccessLevel: .public,
            includeSynthesized: true,
            includeSPI: true)
        
        var packages:[String: [String: [String]]] = [:]
        for target:SwiftSourceModuleTarget in filtered
        {
            guard let package:Package = nationalities[target.id] 
            else 
            {
                fatalError("unreachable")
            }
            for file:File in target.sourceFiles
            {
                if  case .unknown = file.type, 
                    case "docc"?  = file.path.extension?.lowercased()
                {
                    packages[package.id, default: [:]][target.name, default: []].append(file.path.string)
                }
            }
            let graphs:PackageManager.SymbolGraphResult = try self.packageManager.getSymbolGraph(for: target, options: options)
            packages[package.id, default: [:]][target.name, default: []].append(graphs.directoryPath.string)
            invited.remove(target.name)
        }
        for missing:String in invited
        {
            throw DocumentationExtractionError.missingTarget(missing)
        }
        // we’re not escaping these strings properly, but nobody should 
        // be including newlines or backslashes in a module name anyway
        let index:String = 
        """
        [
        \(packages.sorted { $0.key < $1.key }.map 
        {
        """
            {
                "format": "entrapta",
                "package": "\($0.key)", 
                "modules": [\($0.value.keys.sorted().map { "\"\($0)\"" }.joined(separator: ", "))],
                "include": [\($0.value.values.joined().sorted().map { "\"\($0)\"" }.joined(separator: ", "))]
            }
        """
        }.joined(separator: ",\n"))
        ]
        """
        print(index)
    }
}

/* extension SourceModuleTarget 
{
    var catalog:String? 
    {
        return self.sourceFiles.first { sourceFile in
            $0.path.extension?.lowercased() == "docc"
        }?.path.string
    }
} */
