//
//  FileAttributes.swift
//  
//
//  Created by Todd Bowden on 1/2/22.
//

import Foundation

extension TBFileManager {
    
    public struct FileAttributes {
        public let hfsTypeCode: UInt32
        public let ownerAccountID: UInt32
        public let size: UInt64
        public let systemFileNumber: UInt32
        public let posixPermissions: UInt32
        public let groupOwnerAccountName: String
        public let groupOwnerAccountID: UInt32
        public let protectionKey: String
        public let modificationDate: Date
        public let systemNumber: UInt32
        public let type: String
        public let ownerAccountName: String
        public let hfsCreatorCode: UInt32
        public let referenceCount: UInt32
        public let extensionHidden: Bool
        public let creationDate: Date
        
        public init(dictionary: [FileAttributeKey:Any]) {
            hfsTypeCode = dictionary[FileAttributeKey.hfsTypeCode] as? UInt32 ?? 0
            ownerAccountID = dictionary[FileAttributeKey.ownerAccountID] as? UInt32 ?? 0
            size = dictionary[FileAttributeKey.size] as? UInt64 ?? 0
            systemFileNumber = dictionary[FileAttributeKey.systemFileNumber] as? UInt32 ?? 0
            posixPermissions = dictionary[FileAttributeKey.posixPermissions] as? UInt32 ?? 0
            groupOwnerAccountName = dictionary[FileAttributeKey.groupOwnerAccountName] as? String ?? ""
            groupOwnerAccountID = dictionary[FileAttributeKey.groupOwnerAccountID] as? UInt32 ?? 0
            protectionKey = dictionary[FileAttributeKey.protectionKey] as? String ?? ""
            modificationDate = dictionary[FileAttributeKey.modificationDate] as? Date ?? Date(timeIntervalSince1970: 0)
            systemNumber = dictionary[FileAttributeKey.systemNumber] as? UInt32 ?? 0
            type = dictionary[FileAttributeKey.type] as? String ?? ""
            ownerAccountName = dictionary[FileAttributeKey.ownerAccountName] as? String ?? ""
            hfsCreatorCode = dictionary[FileAttributeKey.hfsTypeCode] as? UInt32 ?? 0
            referenceCount = dictionary[FileAttributeKey.referenceCount] as? UInt32 ?? 0
            extensionHidden = dictionary[FileAttributeKey.extensionHidden] as? Bool ?? false
            creationDate = dictionary[FileAttributeKey.creationDate] as? Date ?? Date(timeIntervalSince1970: 0)
        }
    }
    
}
