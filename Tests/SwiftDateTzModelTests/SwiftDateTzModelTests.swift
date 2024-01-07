import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SwiftDateTzModelMacros)
    import SwiftDateTzModelMacros

    let testMacros: [String: Macro.Type] = [
        "DateInRegionField": DateInRegionFieldMacro.self
    ]
#endif

final class SwiftDateTzModelTests: XCTestCase {
    func testDateField() throws {
        #if canImport(SwiftDateTzModelMacros)
            assertMacroExpansion(
                """
                @DateInRegionField("date")
                class Model {
                }
                """,
                expandedSource: """
                class Model {

                    var date: DateInRegion {
                        get {
                            let tz = TimeZone.init(secondsFromGMT: dateTZ)
                            return dateUTC.in(region: Region(zone: tz ?? TimeZone.current))
                        }
                        set {
                            dateUTC = newValue.date
                            dateTZ = newValue.region.timeZone.secondsFromGMT()
                        }
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDateFieldOptional() throws {
        #if canImport(SwiftDateTzModelMacros)
            assertMacroExpansion(
                """
                @DateInRegionField("date", nullable: true)
                class Model {
                }
                """,
                expandedSource: """
                class Model {

                    var date: DateInRegion? {
                        get {
                            if let dbTZ = dateTZ, let dbDate = dateUTC {
                                let tz = TimeZone.init(secondsFromGMT: dbTZ)
                                return dbDate.in(region: Region(zone: tz ?? TimeZone.current))
                            }
                            return nil
                        }
                        set {
                            if let newDate = newValue {
                                dateUTC = newDate.date
                                dateTZ = newDate.region.timeZone.secondsFromGMT()
                            }
                        }
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDateFieldManyFields() throws {
        #if canImport(SwiftDateTzModelMacros)
            assertMacroExpansion(
                """
                @Model
                @DateInRegionField("wakeUp")
                @DateInRegionField("bedtime", optional: true)
                class SleepLog {
                }
                """,
                expandedSource: """
                @Model
                class SleepLog {

                    var wakeUp: DateInRegion {
                        get {
                            let tz = TimeZone.init(secondsFromGMT: wakeUpTZ)
                            return wakeUpUTC.in(region: Region(zone: tz ?? TimeZone.current))
                        }
                        set {
                            wakeUpUTC = newValue.date
                            wakeUpTZ = newValue.region.timeZone.secondsFromGMT()
                        }
                    }

                    var bedtime: DateInRegion? {
                        get {
                            if let dbTZ = bedtimeTZ, let dbDate = bedtimeUTC {
                                let tz = TimeZone.init(secondsFromGMT: dbTZ)
                                return dbDate.in(region: Region(zone: tz ?? TimeZone.current))
                            }
                            return nil
                        }
                        set {
                            if let newDate = newValue {
                                bedtimeUTC = newDate.date
                                bedtimeTZ = newDate.region.timeZone.secondsFromGMT()
                            }
                        }
                    }
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
