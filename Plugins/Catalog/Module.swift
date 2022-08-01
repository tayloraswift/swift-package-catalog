import PackagePlugin

struct Module<TargetType>
{
    let target:TargetType
    let package:Package.ID

    init(_ target:TargetType, in package:Package.ID) 
    {
        self.target = target 
        self.package = package
    }
}

extension Module:Identifiable, Equatable, Comparable where TargetType:Target 
{
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
    
    var id:Target.ID 
    {
        self.target.id
    }
}