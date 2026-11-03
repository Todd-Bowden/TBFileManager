import Foundation
import XCTest
@testable import TBFileManager

final class AtomicWriteTests: XCTestCase {
    private struct Sample: Codable, Equatable {
        let value: String
    }

    // Only for exercising the encryption path; not intended to be cryptographically secure.
    private struct TestEncryptionProvider: TBFileManagerEncryptionProviderProtocol {
        func encrypt(data: Data, key: Data?) throws -> (key: Data, encryptedData: Data) {
            let key = key ?? Data([0x5A])
            let byte = key.first ?? 0x5A
            return (key, Data(data.map { $0 ^ byte }))
        }

        func decrypt(data: Data, key: Data) throws -> Data {
            let byte = key.first ?? 0x5A
            return Data(data.map { $0 ^ byte })
        }
    }

    private func makeManager(doNotBackUp: Bool = false) -> TBFileManager {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TBFileManagerAtomic-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return TBFileManager(baseURL: url, doNotBackUp: doNotBackUp)
    }

    func testAtomicDataWriteAndReplacement() throws {
        let manager = makeManager(doNotBackUp: true)
        try manager.write(file: "nested/file", data: Data("first".utf8), options: .atomic)
        try manager.write(file: "nested/file", data: Data("second".utf8), options: .atomic)
        let data: Data = try manager.read(file: "nested/file")
        XCTAssertEqual(data, Data("second".utf8))
        let url = try manager.fullUrl("nested/file")
        let excluded = try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        XCTAssertEqual(excluded, true)
    }

    func testAtomicStringWriteAndReplacement() throws {
        let manager = makeManager()
        try manager.write(file: "message", string: "first", options: .atomic)
        try manager.write(file: "message", string: "updated", options: .atomic)
        let read: String = try manager.read(file: "message")
        XCTAssertEqual(read, "updated")
    }

    func testAtomicCodableWriteAndReplacement() throws {
        let manager = makeManager()
        try manager.write(file: "sample", object: Sample(value: "first"), options: .atomic)
        try manager.write(file: "sample", object: Sample(value: "updated"), options: .atomic)
        let read: Sample = try manager.read(file: "sample")
        XCTAssertEqual(read, Sample(value: "updated"))
    }

    func testAtomicEncryptedDataCanBeReadAfterReplacement() throws {
        let manager = makeManager()
        manager.encryptionProvider = TestEncryptionProvider()
        let initial = Data("confidential-one".utf8)
        let updated = Data("confidential-two".utf8)
        try manager.write(file: "secure", data: initial, encrypt: true, options: .atomic)
        XCTAssertEqual(try manager.readData(file: "secure"), initial)
        try manager.write(file: "secure", data: updated, encrypt: true, options: .atomic)
        XCTAssertEqual(try manager.readData(file: "secure"), updated)
        XCTAssertTrue(manager.isEncrypted(file: "secure"))
        XCTAssertNotEqual(try Data(contentsOf: manager.fullUrl("secure")), updated)
    }

    func testOriginalMethodsStillWorkAsFunctionReferences() throws {
        let manager = makeManager()
        let writeData: (String, Data, Bool?, Data?) throws -> Void =
            manager.write(file:data:encrypt:key:)
        let writeString: (String, String, Bool, Data?) throws -> Void =
            manager.write(file:string:encrypt:key:)
        let writeObject: (String, Sample, Bool, Data?) throws -> Void =
            manager.write(file:object:encrypt:key:)
        try writeData("legacyData", Data("ok".utf8), nil, nil)
        try writeString("legacyString", "ok", false, nil)
        try writeObject("legacyObject", Sample(value: "ok"), false, nil)
        XCTAssertEqual(try manager.readData(file: "legacyData"), Data("ok".utf8))
        XCTAssertEqual(try manager.readString(file: "legacyString"), "ok")
        let object: Sample = try manager.readObject(file: "legacyObject")
        XCTAssertEqual(object, Sample(value: "ok"))
        // Existing default arguments also retain their old call syntax.
        try manager.write(file: "defaultWrite", data: Data("ok".utf8))
        XCTAssertEqual(try manager.readData(file: "defaultWrite"), Data("ok".utf8))
    }
}
