import XCTest
@testable import TBFileManager

final class TBFileManagerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TBFileManager().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
