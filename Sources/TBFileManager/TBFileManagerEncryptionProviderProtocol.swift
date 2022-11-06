//
//  TBFileManagerEncryptionProviderProtocol.swift
//  
//
//  Created by Todd Bowden on 11/6/22.
//

import Foundation

public protocol TBFileManagerEncryptionProviderProtocol {
    
    func encrypt(data: Data, key: Data?) throws -> (key: Data, encryptedData: Data)
    func decrypt(data: Data, key: Data) throws -> Data
    
}
