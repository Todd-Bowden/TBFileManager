//
//  TBFileManagerError.swift
//  
//
//  Created by Todd Bowden on 11/6/22.
//

import Foundation

public enum TBFileManagerError: Swift.Error {
    case invalidURL
    case stringEncodingError
    case invalidExtendedAttribute
    case encryptionProviderNotSet
    case writeNotEnabled
    case writeExtendedAttributeError
    case cannotAppendToEncryptedFile
}
