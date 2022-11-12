import XCTest
@testable import TBFileManager

final class TBFileManagerTests: XCTestCase {
    
    let testData = "Data-AAABBBCCCDDD".data(using: .utf8)!
    
    let testString = "String-AAABBBCCCDDD"
    
    struct Object: Codable, Equatable {
        var hello = "World"
        var isGood = true
        var answer = 42
        var array = ["A","B","C"]
        struct SubObject: Codable, Equatable {
            var aaa = "AAA"
            var bbb = 123
            var array = [2,3,5,7,11,13]
        }
        var sub = SubObject()
    }
    
    let testObject = Object()
    
    let fileManager = TBFileManager(.documentDirectory, directory: "Test", doNotBackUp: true)
    
    
    func testDataWriteRead() {
        let file = "testDataWriteRead"
        do {
            try? fileManager.delete(file: file)
            try fileManager.write(file: file, data: testData)
            let data = try fileManager.read(file: file)
            XCTAssertEqual(testData, data)
        } catch {
            XCTFail()
        }
    }
    
    func testStringWriteRead() {
        let file = "testStringWriteRead"
        do {
            try? fileManager.delete(file: file)
            try fileManager.write(file: file, string: testString)
            let string:String = try fileManager.read(file: file)
            XCTAssertEqual(testString, string)
        } catch {
            XCTFail()
        }
    }
    
    func testObjectWriteRead() {
        let file = "testObjectWriteRead"
        do {
            try? fileManager.delete(file: file)
            try fileManager.write(file: file, object: testObject)
            let object:Object = try fileManager.read(file: file)
            XCTAssertEqual(testObject, object)
        } catch {
            XCTFail()
        }
    }
    
    func testObjectWriteRead2() {
        let file = "testObjectWriteRead"
        do {
            try? fileManager.delete(file: file)
            try fileManager.write(file: file, object: testObject)
            let object = try fileManager.read(type: Object.self, file: file)
            guard let object2 = object as? Object else { return XCTFail() }
            XCTAssertEqual(testObject, object2)
        } catch {
            XCTFail()
        }
    }
    
    func randomBytes(_ count: Int) -> Data? {
          var bytes = [UInt8](repeating: 0, count: count)
          let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
          guard status == errSecSuccess else { return nil }
          return Data(bytes)
    }
    
    func testDataAppend() {
        let file = "testDataAppend"
        var testData = Data()
        do {
            try? fileManager.delete(file: file)
            for i in 0...100 {
                print(i)
                guard let d = randomBytes(10000) else { return XCTFail() }
                testData.append(d)
                try fileManager.append(file: file, data: d)
            }
            let data = try fileManager.read(file: file)
            XCTAssertEqual(testData, data)
        } catch {
            XCTFail()
        }
    }
    
    func testExtendedAttribute() {
        let file = "testExtendedAttribute"
        do {
            try? fileManager.delete(file: file)
            try fileManager.write(file: file, data: testData)
            let testExtendedAttribute = "abcdefghijklmnopqrstuvwxyz12345678901234567890".data(using: .utf8)!
            let extendedAttributeName = "abcdefg"
            try? fileManager.removeExtendedAttribute(extendedAttributeName, file: file)
            try fileManager.setExtendedAttribute(extendedAttributeName, value: testExtendedAttribute, file: file)
            let extendedAttribute = try fileManager.extendedAttribute(extendedAttributeName, file: file)
            XCTAssertEqual(extendedAttribute, testExtendedAttribute)
        } catch {
            XCTFail()
        }
    }
    
    func testLastAccess() {
        let file = "testLastAccess"
        do {
            try? fileManager.delete(file: file)
            try fileManager.write(file: file, object: testObject)
            guard let lastAccess1 = fileManager.lastAccessDate(file: file) else { return XCTFail() }
            let exp = expectation(description: "")
            let _ = XCTWaiter.wait(for: [exp], timeout: 2.0)
            let _:Object = try fileManager.read(file: file)
            guard let lastAccess2 = fileManager.lastAccessDate(file: file) else { return XCTFail() }
            XCTAssert(lastAccess2 > lastAccess1)
        } catch {
            XCTFail()
        }
    }
    
    func testAttributesDictionary() {
        let file = "testAttributesDictionary"
        do {
            try? fileManager.delete(file: file)
            try fileManager.write(file: file, data: testData)
            let attributes = try fileManager.attributesDictionary(file: file)
            for a in attributes {
                print(a)
            }
        } catch {
            XCTFail()
        }
    }
    
    func testAttributes() {
        let file = "testAttributes"
        do {
            try? fileManager.delete(file: file)
            try fileManager.write(file: file, data: testData)
            let attributes = try fileManager.attributes(file: file)
            print(attributes)
        } catch {
            XCTFail()
        }
    }
    
}
