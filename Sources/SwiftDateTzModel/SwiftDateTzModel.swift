@attached(member, names: arbitrary)
public macro DateInRegionField(_ name: String, nullable: Bool = false) = #externalMacro(
    module: "SwiftDateTzModelMacros",
    type: "DateInRegionFieldMacro"
)
