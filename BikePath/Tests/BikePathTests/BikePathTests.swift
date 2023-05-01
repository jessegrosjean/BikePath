import XCTest
@testable import BikePath

final class BikePathTests: XCTestCase {

    func testParseAxis() throws {
        XCTAssertEqual(try axis.parse("ancestor::"), .ancestor)
        XCTAssertEqual(try axis.parse("//"), .descendantOrSelfShortcut)
        XCTAssertEqual(try axis.parse("/"), .childShortcut)
    }
    
}
