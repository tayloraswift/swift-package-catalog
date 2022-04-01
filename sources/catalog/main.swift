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

@main 
struct Main:CommandPlugin
{
    func performCommand(context:PluginContext, arguments:[String]) throws 
    {
        var invitations:Set<String> = .init(arguments)
        
        let options:PackageManager.SymbolGraphOptions = .init(
            minimumAccessLevel: .public,
            includeSynthesized: true,
            includeSPI: true)
        
        var modules:[String] = [], 
            include:[String] = []
        for target:any Target in context.package.targets
        {
            guard let target:SwiftSourceModuleTarget = target as? SwiftSourceModuleTarget
            else 
            {
                continue 
            }
            if case nil = invitations.remove(target.name), !arguments.isEmpty
            {
                continue 
            }
            for file:File in target.sourceFiles
            {
                if  case .unknown = file.type, 
                    case "docc"?  = file.path.extension?.lowercased()
                {
                    include.append(file.path.string)
                }
            }
            let graphs:PackageManager.SymbolGraphResult = try self.packageManager.getSymbolGraph(for: target, options: options)
            include.append(graphs.directoryPath.string)
            modules.append(target.name)
        }
        for missing:String in invitations
        {
            throw DocumentationExtractionError.missingTarget(missing)
        }
        // we’re not escaping these strings properly, but nobody should 
        // be including newlines or backslashes in a module name anyway
        let index:String = 
        """
        [
            {
                "format": "entrapta",
                "package": "\(context.package.id)", 
                "modules": [\(modules.map { "\"\($0)\"" }.joined(separator: ", "))],
                "include": [\(include.map { "\"\($0)\"" }.joined(separator: ", "))]
            }
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
