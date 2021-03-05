
import Foundation

class TBFileManager {
    
    enum Error: Swift.Error {
        case invalidURL
        case stringEncodingError
    }
        
    let baseURL: URL?
    let doNotBackUp: Bool
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(baseURL: URL, doNotBackUp: Bool = false) {
        self.baseURL = baseURL
        self.doNotBackUp = doNotBackUp
    }
    
    init(appGroup: String, directory: String, doNotBackUp: Bool = false) {
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
        self.baseURL = appGroupURL?.appendingPathComponent(directory)
        self.doNotBackUp = doNotBackUp
    }
    
    init(_ baseDirectory: FileManager.SearchPathDirectory, directory: String, doNotBackUp: Bool = false) {
        let basePath = FileManager.default.urls(for: baseDirectory, in: .userDomainMask).first
        self.baseURL = basePath?.appendingPathComponent(directory)
        self.doNotBackUp = doNotBackUp
    }
    
    func fullUrl(_ file: String) throws -> URL {
        if let url = self.baseURL?.appendingPathComponent(file)  {
            return url
        } else {
            throw Error.invalidURL
        }
    }
    
    // MARK: Directories
    
    func create(directory: String)  throws {
        let url = try fullUrl(directory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
    
    private func createIntermediate(directory: String)  throws {
        let url = try fullUrl(directory)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
    }
    
    func contents(directory: String) throws -> [String] {
        let url = try fullUrl(directory)
        do {
            return try FileManager.default.contentsOfDirectory(atPath: url.path)
        } catch {
            return [String]()
        }
    }
    
    
    // MARK: Write

    func write(file: String, data: Data) throws {
        let url = try fullUrl(file)
        try createIntermediate(directory: file)
        try data.write(to: url)
        if doNotBackUp {
            try excludeFromBackup(file: file)
        }
    }
    
    func write(file: String, string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw Error.stringEncodingError
        }
        try write(file: file, data: data)
    }
    
    func write<T:Codable>(file: String, object: T) throws {
        let data = try encoder.encode(object)
        try write(file: file, data: data)
    }
    
    func excludeFromBackup(file: String) throws {
        var url = try fullUrl(file)
        var rv = URLResourceValues()
        rv.isExcludedFromBackup = true
        try url.setResourceValues(rv)
    }
    
    
    // MARK: Read
    
    func read(file: String) throws -> Data {
        let url = try fullUrl(file)
        return try Data(contentsOf: url)
    }
    
    func read(file: String, encoding: String.Encoding = .utf8) throws -> String {
        let url = try fullUrl(file)
        let data = try Data(contentsOf: url)
        if let string = String(data: data, encoding: encoding) {
            return string
        } else {
            throw Error.stringEncodingError
        }
    }
    
    func read<T:Codable>(file: String) throws -> T {
        let data = try read(file: file)
        return try decoder.decode(T.self, from: data)
    }
    
    
    // MARK: Delete
    
    func delete(file: String) throws {
        let url = try fullUrl(file)
        try FileManager.default.removeItem(at: url)
    }
    
    // MARK: Attributes
    
    func getAttributes(file: String) throws -> [FileAttributeKey:Any] {
        let url = try fullUrl(file)
        return try FileManager.default.attributesOfItem(atPath: url.path)
    }
    

}
