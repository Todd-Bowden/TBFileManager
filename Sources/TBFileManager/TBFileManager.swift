
import Foundation

public protocol TBFileManagerEncryptionProvider {
    func encrypt(data: Data, key: Data?) throws -> (key: Data, encryptedData: Data)
    func decrypt(data: Data, key: Data) throws -> Data
}

public class TBFileManager {
    
    public enum Error: Swift.Error {
        case invalidURL
        case stringEncodingError
        case invalidExtendedAttribute
        case encryptionProviderNotSet
        case writeNotEnabled
        case writeExtendedAttributeError
    }
    
    public enum ExtendedAttribute: String {
       case encryptionKey = "EncryptionKey"
       case lastAccessDate = "LastAccessDate"
   }
        
    public let baseURL: URL?
    public var doNotBackUp: Bool
    
    public var writeEnabled = true
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let dateformatter = ISO8601DateFormatter()
    
    public var encryptionProvider: TBFileManagerEncryptionProvider?
    
    public init(baseURL: URL, doNotBackUp: Bool = false) {
        self.baseURL = baseURL
        self.doNotBackUp = doNotBackUp
    }
    
    public init(appGroup: String, directory: String = "", doNotBackUp: Bool = false) {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
        self.baseURL = appGroupURL?.appendingPathComponent(directory)
        self.doNotBackUp = doNotBackUp
    }
    
    public init(_ baseDirectory: FileManager.SearchPathDirectory, directory: String = "", doNotBackUp: Bool = false) {
        let basePath = FileManager.default.urls(for: baseDirectory, in: .userDomainMask).first
        self.baseURL = basePath?.appendingPathComponent(directory)
        self.doNotBackUp = doNotBackUp
    }
    
    public func fullUrl(_ file: String) throws -> URL {
        if let url = self.baseURL?.appendingPathComponent(file)  {
            return url
        } else {
            throw Error.invalidURL
        }
    }
    
    // MARK: Directories
    
    public func create(directory: String)  throws {
        let url = try fullUrl(directory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
    
    private func createIntermediate(directory: String)  throws {
        let url = try fullUrl(directory)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
    }
    
    public func contents(directory: String = "") throws -> [String] {
        let url = try fullUrl(directory)
        do {
            return try FileManager.default.contentsOfDirectory(atPath: url.path)
        } catch {
            return [String]()
        }
    }
    
    
    // MARK: Write

    public func write(file: String, data: Data, encrypt: Bool? = nil, key: Data? = nil) throws {
        guard writeEnabled else { throw Error.writeNotEnabled }
        let encrypt = encrypt ?? (encryptionProvider != nil)
        let url = try fullUrl(file)
        try createIntermediate(directory: file)
        if encrypt {
            guard let encryptionProvider = encryptionProvider else { throw Error.encryptionProviderNotSet }
            let kd = try encryptionProvider.encrypt(data: data, key: key)
            try kd.encryptedData.write(to: url)
            try setExtendedAttribute(.encryptionKey, value: kd.key, file: file)
        } else {
            try data.write(to: url)
        }
        if doNotBackUp {
            try excludeFromBackup(file: file)
        }
        try? setLastAccessDate(file: file)
    }
    
    public func write(file: String, string: String, encrypt: Bool = false, key: Data? = nil) throws {
        guard writeEnabled else { throw Error.writeNotEnabled }
        guard let data = string.data(using: .utf8) else {
            throw Error.stringEncodingError
        }
        try write(file: file, data: data, encrypt: encrypt, key: key)
    }
    
    public func write<T:Codable>(file: String, object: T, encrypt: Bool = false, key: Data? = nil) throws {
        guard writeEnabled else { throw Error.writeNotEnabled }
        let data = try encoder.encode(object)
        try write(file: file, data: data, encrypt: encrypt, key: key)
    }
    
    public func excludeFromBackup(file: String) throws {
        var url = try fullUrl(file)
        var rv = URLResourceValues()
        rv.isExcludedFromBackup = true
        try url.setResourceValues(rv)
    }
    
    
    // MARK: Read
    
    public func read(file: String) throws -> Data {
        let url = try fullUrl(file)
        if let key = try? extendedAttribute(.encryptionKey, file: file) {
            guard let encryptionProvider = encryptionProvider else { throw Error.encryptionProviderNotSet }
            let encryptedData = try Data(contentsOf: url)
            let data = try encryptionProvider.decrypt(data: encryptedData, key: key)
            try? setLastAccessDate(file: file)
            return data
        } else {
            let data = try Data(contentsOf: url)
            try? setLastAccessDate(file: file)
            return data
        }
    }
    
    public func read(file: String, encoding: String.Encoding = .utf8) throws -> String {
        let url = try fullUrl(file)
        let data = try Data(contentsOf: url)
        if let string = String(data: data, encoding: encoding) {
            try? setLastAccessDate(file: file)
            return string
        } else {
            throw Error.stringEncodingError
        }
    }
    
    public func read<T:Codable>(file: String) throws -> T {
        let data = try read(file: file)
        let object = try decoder.decode(T.self, from: data)
        try? setLastAccessDate(file: file)
        return object
    }
    
    
    // MARK: Delete
    
    public func delete(file: String) throws {
        let url = try fullUrl(file)
        try FileManager.default.removeItem(at: url)
    }
    
    // MARK: Attributes
    
    public func attributes(file: String) throws -> [FileAttributeKey:Any] {
        let url = try fullUrl(file)
        return try FileManager.default.attributesOfItem(atPath: url.path)
    }
    
    public func extendedAttributeList(file: String) throws -> [String] {
        let url = try fullUrl(file)
        let list = try url.withUnsafeFileSystemRepresentation({ (path) -> [String] in
            let size = listxattr(path, nil, 0, 0)
            guard size > 0 else { return [String]() }
            var buffer = Array<Int8>(repeating: 0, count: size)
            let r = listxattr(path, &buffer, size, 0)
            guard size == r else { throw Error.invalidExtendedAttribute }
            let bufferUInt8: Array<UInt8> = buffer.map { (int8) -> UInt8 in
                return UInt8(int8)
            }
            let list = Data(bufferUInt8).split(separator: 0).map { (attribute) -> String in
                return String(data: attribute, encoding: .utf8) ?? ""
            }
            return list
        })
        return list
    }
    
    public func extendedAttributes(file: String) throws -> [String:Data] {
        let list = try extendedAttributeList(file: file)
        var attributes = [String:Data]()
        for att in list {
            let value = try extendedAttribute(att, file: file)
            attributes[att] = value
        }
        return attributes
    }
    
    
    public func extendedAttribute(_ name: ExtendedAttribute, file: String) throws -> Data {
          return try extendedAttribute(name.rawValue, file: file)
      }
    
    public func extendedAttribute(_ name: String, file: String) throws -> Data {
        let url = try fullUrl(file)
        let data = try url.withUnsafeFileSystemRepresentation({ (path) -> Data in
            let size = getxattr(path, name, nil, 0, 0, 0)
            guard size > 0 else { throw Error.invalidExtendedAttribute }
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
            let r = getxattr(path, name, buffer, size, 0, 0)
            guard size == r else { throw Error.invalidExtendedAttribute }
            let data = Data(bytes: buffer, count: size)
            buffer.deallocate()
            return data
        })
        return data
    }
    
    
    public func setExtendedAttribute(_ name: ExtendedAttribute, value: Data, file: String) throws {
        try setExtendedAttribute(name.rawValue, value: value, file: file)
    }
    
    public func setExtendedAttribute(_ name: String, value: Data, file: String) throws {
        guard writeEnabled else { throw Error.writeNotEnabled }
        let url = try fullUrl(file)
        var result: Int32 = 0
        let _ = url.withUnsafeFileSystemRepresentation { path in
            result = setxattr(path, name, (value as NSData).bytes, value.count, 0, 0)
        }
        guard result == 0 else {
            throw Error.writeExtendedAttributeError
        }
    }

    
    public func removeExtendedAttribute(_ name: ExtendedAttribute, file: String) throws {
          try removeExtendedAttribute(name.rawValue, file: file)
    }

    public func removeExtendedAttribute(_ name: String, file: String) throws {
        let url = try fullUrl(file)
        let _ = url.withUnsafeFileSystemRepresentation { path in
            let _ = removexattr(path, name, 0)
        }
    }
    
    
    // MARK: Convenience Extended Attributes
    
    public func setLastAccessDate(_ date: Date? = nil, file: String) throws {
        let date = date ?? Date()
        let string = String(dateformatter.string(from: date))
        guard let data = string.data(using: .utf8) else { throw Error.stringEncodingError }
        try setExtendedAttribute(.lastAccessDate, value: data, file: file)
    }
    
    public func lastAccessDate(file: String) -> Date? {
        guard let data = try? extendedAttribute(.lastAccessDate, file: file) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        return dateformatter.date(from: string)
    }
    
    

}
