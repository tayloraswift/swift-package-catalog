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

struct LinkableTarget:Identifiable, Comparable
{
    struct ID:Hashable 
    {
        let target:Target.ID
        let product:Product.ID
    }
    
    let target:SwiftSourceModuleTarget
    let product:Product.ID
    
    static 
    func == (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.target.id == rhs.target.id
    }
    static 
    func < (lhs:Self, rhs:Self) -> Bool 
    {
        lhs.target.id < rhs.target.id
    }
    
    var id:ID 
    {
        .init(target: self.target.id, product: self.product)
    }
}
extension Package
{
    // does not preserve the order 
    func targets(named names:[String]) -> [LinkableTarget]
    {
        let filter:Set<String> = .init(names)
        var targets:[Target.ID: LinkableTarget] = [:]
        for product:any Product in self.products 
        {
            product.gather(targets: &targets)
        }
        let all:[LinkableTarget] = targets.values.sorted()
        return names.isEmpty ? all : all.filter { filter.contains($0.target.name) }
    }
    private
    func gather(targets:inout [Target.ID: LinkableTarget])
    {
        for dependency:PackageDependency in self.dependencies 
        {
            dependency.package.gather(targets: &targets)
        }
        for product:any Product in self.products 
        {
            product.gather(targets: &targets)
        }
    }
    private 
    func gather(nationalities:inout [Product.ID: Package])
    {
        for dependency:PackageDependency in self.dependencies 
        {
            dependency.package.gather(nationalities: &nationalities)
        }
        for product:any Product in self.products
        {
            nationalities[product.id] = self
        }
    }
    func nationalities() -> [Product.ID: Package]
    {
        var nationalities:[Product.ID: Package] = [:]
        self.gather(nationalities: &nationalities)
        return nationalities
    }
}
extension Product 
{
    func gather(targets:inout [Target.ID: LinkableTarget])
    {
        for target:any Target in self.targets 
        {
            target.gather(dependencies: &targets, product: self.id)
            if let target:SwiftSourceModuleTarget = target as? SwiftSourceModuleTarget 
            {
                targets[target.id] = .init(target: target, product: self.id)
            }
        }
    }
}
extension Target 
{
    func dependencies(product:Product.ID) -> [LinkableTarget]
    {
        var dependencies:[Target.ID: LinkableTarget] = [:]
        self.gather(dependencies: &dependencies, product: product)
        return dependencies.values.sorted()
    }
    func gather(dependencies:inout [Target.ID: LinkableTarget], product:Product.ID)
    {
        for dependency:TargetDependency in self.dependencies 
        {
            switch dependency 
            {
            case .product(let product):
                product.gather(targets: &dependencies)
            
            case .target(let target as SwiftSourceModuleTarget):
                dependencies[target.id] = .init(target: target, product: product)
                
            case .target(_):
                break
            }
        }
    }
}

@main 
struct Main:CommandPlugin
{
    func performCommand(context:PluginContext, arguments:[String]) throws 
    {
        // determine which products belong to which packages 
        let nationalities:[Product.ID: Package] = context.package.nationalities()
        let modules:[LinkableTarget] = context.package.targets(named: arguments)
        
        let missing:Set<String> = Set<String>.init(arguments).subtracting(modules.map(\.target.name))
        if let missing:String = missing.first 
        {
            throw DocumentationExtractionError.missingTarget(missing)
        }
        
        let options:PackageManager.SymbolGraphOptions = .init(
            minimumAccessLevel: .public,
            includeSynthesized: true,
            includeSPI: true)
        
        var packages:[Package.ID: [String]] = [:]
        for module:LinkableTarget in modules 
        {
            guard let package:Package = nationalities[module.product] 
            else 
            {
                fatalError("unreachable")
            }
            
            var dependencies:[Package.ID: [String]] = [:]
            for dependency:LinkableTarget in module.target.dependencies(product: module.product)
            {
                guard let package:Package = nationalities[dependency.product]
                else 
                {
                    fatalError("could not find package containing dependency '\(dependency.product)'")
                }
                // package.origin is always set to .root, and never contains 
                // useful version information.
                dependencies[package.id, default: []].append(dependency.target.name)
            }
            
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
            
            let object:String =
            """
            
                        {
                            "module": "\(module.target.name)",
                            "dependencies": [\(dependencies.sorted { $0.key < $1.key }.map 
                            { 
                                """
                                {"package": "\($0.key)", "modules": [\($0.value.sorted().map { "\"\($0)\"" }.joined(separator: ", "))]}
                                """
                            }.joined(separator: ", "))],
                            "include": 
                            [\(include.sorted().map 
                            { 
                                """
                                
                                                    "\($0)"
                                """
                            }.joined(separator: ", "))
                            ]
                        }
            """
            packages[package.id, default: []].append(object)
        }
        let object:String =
        """
        [\(packages.sorted { $0.key < $1.key }.map 
        { 
            """
            
                {
                    "catalog_tools_version": 2,
                    "package": "\($0.key)", 
                    "modules": 
                    [\($0.value.joined(separator: ", "))
                    ]
                }
            """
        }.joined(separator: ", "))
        ]
        """
        print(object)
    }
}
