import PackagePlugin

@main 
struct Main:CommandPlugin
{
    func performCommand(context:PluginContext, arguments:[String]) throws 
    {
        if  arguments.isEmpty 
        {
            return 
        }

        let graph:PackageGraph = .init(context.package)
        var consumers:[Target.ID: [Target.ID: Module<any Target>]] = [:]
        var identifiers:[String: [Target.ID]] = [:]
        var seen:Set<Target.ID> = []
        for target:any Target in context.package.targets 
        {
            graph.walk(target)
            {
                guard case nil = seen.update(with: $0.target.id)
                else 
                {
                    return 
                }
                identifiers[$0.target.name, default: []].append($0.target.id)
                for dependency:TargetDependency in $0.target.dependencies 
                {
                    switch dependency 
                    {
                    case .target(let target): 
                        consumers[target.id, default: [:]][$0.target.id] = 
                            .init($0.target, in: $0.package)
                    
                    case .product(let product): 
                        for target:any Target in product.targets 
                        {
                            consumers[target.id, default: [:]][$0.target.id] = 
                                .init($0.target, in: $0.package)
                        }
                    }
                }
            }
        }
        for argument:String in arguments 
        {
            guard let identifiers:[Target.ID] = identifiers[argument]
            else 
            {
                throw MissingTargetError.init(name: argument)
            }
            for target:Target.ID in identifiers 
            {
                let modules:[Module<any Target>] = consumers[target, default: [:]].values.sorted
                {
                    $0.target.name < $1.target.name
                }
                print("direct consumers of \(argument):")
                for (i, module):(Int, Module<any Target>) in modules.enumerated()
                {
                    print("\(i). \(module.target.name) (in '\(module.package)')")
                }
            }
        }
    }
}
