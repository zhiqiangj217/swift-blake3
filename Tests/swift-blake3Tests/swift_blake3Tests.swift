import Testing
import Foundation

@testable import swift_blake3

extension Data {
    var hexString: String {
        return map {String(format: "%02hhx", $0)}.joined()
    }
}

struct Case: Codable {
    let input_len: Int
    let hash: String
    let keyed_hash: String
    let derive_key: String
}

struct TestVectors: Codable {
    let _comment: String
    let key: String
    let context_string: String
    let cases: [Case]
}

@Test func `test_vectors.json from https://github.com/BLAKE3-team/BLAKE3`() async throws {
    guard let url = Bundle.module.url(forResource: "test_vectors", withExtension: "json") else {
        return
    }
    let data = try Data(contentsOf: url)
    let vectors = try JSONDecoder().decode(TestVectors.self, from: data)
    
    
    for c in vectors.cases {
        var inputData = Data(count: c.input_len)
        for i in 0..<c.input_len {
            inputData[i] = UInt8(i % 251)
        }
        var b = try Blake3.hash(inputData, outputLength: 131)
        #expect(b.hexString == c.hash)
        
        b = try Blake3.hash(inputData)
        let i64 = c.hash.index(c.hash.startIndex, offsetBy: 64)
        #expect(b.hexString == String(c.hash[..<i64]))
        
        b = Blake3.deriveKey(context: vectors.context_string, material: inputData, outputLength: 131)
        #expect(b.hexString == c.derive_key)
        
        b = Blake3.deriveKey(context: vectors.context_string, material: inputData)
        #expect(b.hexString == String(c.derive_key[..<i64]))
    }
}
