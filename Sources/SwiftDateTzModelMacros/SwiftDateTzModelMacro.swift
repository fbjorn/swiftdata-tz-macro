import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

func makeGetterSetter(_ varName: String, nullable: Bool = false) -> String {
    let varNameUTC = "\(varName)UTC"
    let varNameTZ = "\(varName)TZ"
    if nullable {
        return """
        var \(varName): DateInRegion? {
            get {
                if let dbTZ = \(varNameTZ), let dbDate = \(varNameUTC) {
                    let tz = TimeZone.init(secondsFromGMT: dbTZ)
                    return dbDate.in(region: Region(zone: tz ?? TimeZone.current))
                }
                return nil
            }
            set {
                if let newDate = newValue {
                    \(varNameUTC) = newDate.date
                    \(varNameTZ) = newDate.region.timeZone.secondsFromGMT()
                }
            }
        }
        """
    }
    return """
    var \(varName): DateInRegion {
        get {
            let tz = TimeZone.init(secondsFromGMT: \(varNameTZ))
            return \(varNameUTC).in(region: Region(zone: tz ?? TimeZone.current))
        }
        set {
            \(varNameUTC) = newValue.date
            \(varNameTZ) = newValue.region.timeZone.secondsFromGMT()
        }
    }
    """
}

public struct DateInRegionFieldMacro: MemberMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf _: some SwiftSyntax.DeclGroupSyntax,
        in _: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard
            case let .argumentList(arguments) = node.arguments,
            let memberAccessExn = arguments.first?.expression.as(StringLiteralExprSyntax.self),
            let firstArg = memberAccessExn.segments.first?.as(StringSegmentSyntax.self)
        else {
            return []
        }

        let varName = firstArg.content.text

        guard
            case let .argumentList(arguments) = node.arguments,
            arguments.count == 2,
            let secondArg = arguments.last?.expression.as(BooleanLiteralExprSyntax.self),
            secondArg.literal.text == "true"
        else {
            return [
                DeclSyntax(stringLiteral: makeGetterSetter(varName, nullable: false))
            ]
        }

        return [
            DeclSyntax(stringLiteral: makeGetterSetter(varName, nullable: true))
        ]
    }
}

@main
struct SwiftDateTzModelPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DateInRegionFieldMacro.self
    ]
}
