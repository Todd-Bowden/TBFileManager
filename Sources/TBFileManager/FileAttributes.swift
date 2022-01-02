//
//  FileAttributes.swift
//  
//
//  Created by Todd Bowden on 1/2/22.
//

import Foundation

public struct FileAttributes {
    let hfsTypeCode: UInt32
    let ownerAccountID: UInt32
    let size: UInt64
    let systemFileNumber: UInt32
    let posixPermissions: UInt32
    let groupOwnerAccountName: String
    let groupOwnerAccountID: UInt32
    let protectionKey: String
    let modificationDate: Date
    let systemNumber: UInt32
    let type: String
    let ownerAccountName: String
    let hfsCreatorCode: UInt32
    let referenceCount: UInt32
    let extensionHidden: Bool
    let creationDate: Date
    
    init(dictionary: [FileAttributeKey:Any]) {
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
