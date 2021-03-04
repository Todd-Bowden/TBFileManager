
import Foundation

class TBFileManager {
    
    enum Error: Swift.Error {
        case invalidURL
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
    
    func create(directory: String)  throws {
        let url = try fullUrl(directory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
    
    private func createIntermediate(directory: String)  throws {
        let url = try fullUrl(directory)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
    }

    func write(file: String, data: Data) throws {
        let url = try fullUrl(file)
        try createIntermediate(directory: file)
        try data.write(to: url)
    }

    func read(file: String) throws -> Data {
        let url = try fullUrl(file)
        return try Data(contentsOf: url)
    }
    
    func write<T:Codable>(file: String, object: T) throws {
        let data = try encoder.encode(object)
        try write(file: file, data: data)
    }
    
    func read<T:Codable>(file: String) throws -> T {
        let data = try read(file: file)
        return try decoder.decode(T.self, from: data)
    }
    
    
    
    
}
