//
//  swift_blake3.swift
//
//  Created by 姜志强 on 1/4/26.
//

import CBlake3
import Foundation


/// Blake3
public class Blake3 {
    
    private var hasher = blake3_hasher()
    
    private let key: Data?
    
    /// Creates a BLAKE3 hasher instance.
    ///
    /// If no key is provided, the hasher operates in **unkeyed mode** (standard hashing).
    /// If a key is provided, it operates in **keyed mode** (acts like a message authentication code).
    ///
    /// - Parameter key: Optional 32-byte key for keyed hashing. If `nil`, unkeyed hashing is used.
    /// - Throws: `Blake3Error.invalidKeySize` if the provided key is not exactly 32 bytes long.
    public init(key: Data? = nil) throws(Blake3Error) {
        self.key = key
        if let key, key.count != 32 {
            throw Blake3Error.invalidKeySize
        }
        reset()
    }
    
    /// Creates a BLAKE3 hasher instance in **key derivation mode**.
    ///
    /// This mode uses the given context string to derive a key from input material via BLAKE3's
    /// built-in key derivation function (KDF). It is suitable for domain-separated key derivation.
    ///
    /// - Parameter context: A  context string that defines the purpose of the derived key.
    public init(context: String) {
        self.key = nil
        reset()
        context.withCString { cString in
            blake3_hasher_init_derive_key(&hasher, cString)
        }
    }
    
    /// Updates the hash state with new input data.
    ///
    /// This method can be called multiple times to incrementally process large inputs.
    ///
    /// - Parameter message: The data to be hashed. Any type conforming to `DataProtocol` is accepted
    ///                      (e.g., `Data`, `Array<UInt8>`, etc.).
    public func update<Plaintext: DataProtocol>(_ message: Plaintext) {
        message.withContiguousStorageIfAvailable { buffer in
            if let ptr = buffer.baseAddress {
                blake3_hasher_update(&hasher, ptr, message.count)
            }
        }
    }
    
    /// Resets the hasher to its initial state.
    ///
    /// After calling this, the hasher behaves as if newly initialized (in unkeyed mode).
    public func reset() {
        if let key {
            key.withUnsafeBytes { rawBuffer in
                if let ptr = rawBuffer.baseAddress {
                    let uint8Ptr = ptr.bindMemory(to: UInt8.self, capacity: 32)
                    blake3_hasher_init_keyed(&hasher, uint8Ptr)
                }
            }
        } else {
            blake3_hasher_init(&hasher)
        }
    }
    
    /// Finalizes the hash computation and returns the digest.
    ///
    /// The hasher cannot be reused after finalization unless `reset()` is called.
    ///
    /// - Parameter outputLength: The desired length of the output digest in bytes.
    ///                           Default is 32 bytes (256 bits). BLAKE3 supports outputs up to 2^64 - 1 bytes.
    /// - Returns: A `Data` object containing the computed hash digest.
    public func finalize(outputLength: Int = 32) -> Data {
        var output = Data(count: outputLength)
        output.withUnsafeMutableBytes { rawBuffer in
            if let ptr = rawBuffer.baseAddress {
                let uint8Ptr = ptr.bindMemory(to: UInt8.self, capacity: outputLength)
                blake3_hasher_finalize(&hasher, uint8Ptr, outputLength)
            }
        }
        return output
    }
    
    /// Computes a BLAKE3 hash of the given message in one shot.
    ///
    /// - Parameters:
    ///   - message: The input data to hash.
    ///   - key: Optional 32-byte key for keyed hashing. If `nil`, standard unkeyed hashing is performed.
    ///   - outputLength: Desired output length in bytes (default: 32).
    /// - Returns: The resulting hash digest as `Data`.
    /// - Throws: `Blake3Error.invalidKeySize` if a provided key is not exactly 32 bytes.
    public static func hash<Plaintext: DataProtocol>(_ message: Plaintext, key: Data? = nil, outputLength: Int = 32) throws(Blake3Error) -> Data {
        let hasher = try Blake3(key: key)
        hasher.update(message)
        return hasher.finalize(outputLength: outputLength)
    }
    
    /// Derives a key from input material using BLAKE3's key derivation function (KDF).
    ///
    /// This is equivalent to initializing a hasher with `init(context:)` and then hashing the material.
    /// It provides domain separation via the context string, which is critical for security in key derivation.
    ///
    /// - Parameters:
    ///   - context: A descriptive string that identifies the purpose of the derived key
    ///              (e.g., "MyApp Encryption Key").
    ///   - material: Input key material (IKM) used to derive the output key.
    ///   - outputLength: Desired length of the derived key in bytes (default: 32).
    /// - Returns: The derived key as `Data`.
    public static func deriveKey<Material: DataProtocol>(context: String , material: Material, outputLength: Int = 32) -> Data {
        let kdf = Blake3(context: context)
        kdf.update(material)
        return kdf.finalize(outputLength: outputLength)
    }
}

public enum Blake3Error: Error {
    
    /// Thrown when a provided key does not have the required length of 32 bytes.
    case invalidKeySize
}
