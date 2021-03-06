
import Foundation

public class TBFileManager {
    
    public  enum Error: Swift.Error {
        case invalidURL
        case stringEncodingError
        case invalidExtendedAttribute
    }
        
    public let baseURL: URL?
    public let doNotBackUp: Bool
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init(baseURL: URL, doNotBackUp: Bool = false) {
        self.baseURL = baseURL
        self.doNotBackUp = doNotBackUp
    }
    
    public init(appGroup: String, directory: String, doNotBackUp: Bool = false) {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
        self.baseURL = appGroupURL?.appendingPathComponent(directory)
        self.doNotBackUp = doNotBackUp
    }
    
    public init(_ baseDirectory: FileManager.SearchPathDirectory, directory: String, doNotBackUp: Bool = false) {
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
    
    public func contents(directory: String) throws -> [String] {
        let url = try fullUrl(directory)
        do {
            return try FileManager.default.contentsOfDirectory(atPath: url.path)
        } catch {
            return [String]()
        }
    }
    
    
    // MARK: Write

    public func write(file: String, data: Data) throws {
        let url = try fullUrl(file)
        try createIntermediate(directory: file)
        try data.write(to: url)
        if doNotBackUp {
            try excludeFromBackup(file: file)
        }
    }
    
    public func write(file: String, string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw Error.stringEncodingError
        }
        try write(file: file, data: data)
    }
    
    public func write<T:Codable>(file: String, object: T) throws {
        let data = try encoder.encode(object)
        try write(file: file, data: data)
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
        return try Data(contentsOf: url)
    }
    
    public func read(file: String, encoding: String.Encoding = .utf8) throws -> String {
        let url = try fullUrl(file)
        let data = try Data(contentsOf: url)
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw Error.stringEncodingError
        }
    }
    
    public func read<T:Codable>(file: String) throws -> T {
        let data = try read(file: file)
        return try decoder.decode(T.self, from: data)
    }
    
    
    // MARK: Delete
    
    public func delete(file: String) throws {
        let url = try fullUrl(file)
        try FileManager.default.removeItem(at: url)
    }
    
    // MARK: Attributes
    
    public func getAttributes(file: String) throws -> [FileAttributeKey:Any] {
        let url = try fullUrl(file)
        return try FileManager.default.attributesOfItem(atPath: url.path)
    }
    
    public func getExtendedAttributeList(file: String) throws -> [String] {
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
    
    public func getExtendedAttributes(file: String) throws -> [String:Data] {
        let list = try getExtendedAttributeList(file: file)
        var attributes = [String:Data]()
        for att in list {
            let value = try getExtendedAttribute(att, file: file)
            attributes[att] = value
        }
        return attributes
    }
    
    public func getExtendedAttribute(_ name: String, file: String) throws -> Data {
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
    
    public func setExtendedAttribute(_ name: String, value: Data, file: String) throws {
        let url = try fullUrl(file)
        var value = value
        let _ = url.withUnsafeFileSystemRepresentation { path in
            setxattr(path, name, &value, value.count, 0, 0)
         }
    }
    
    public func removeExtendedAttribute(_ name: String, file: String) throws {
        let url = try fullUrl(file)
        let _ = url.withUnsafeFileSystemRepresentation { path in
            let _ = removexattr(path, name, 0)
        }
    }

}
