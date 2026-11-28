import Foundation
@testable import SmartCache

/// A value with a size we choose and an encoded form that is always nine bytes,
/// so the compressed tier always looks like a win.
struct Blob: SmartCacheValue{
    let byteSize: Int
    let marker: UInt8

    var cacheByteSize: Int{
        byteSize
    }

    func encodedForStorage() throws -> Data{
        var data = Data()
        withUnsafeBytes(of: Int64(byteSize).littleEndian){ data.append(contentsOf: $0) }
        data.append(marker)
        return data
    }

    static func decoded(from data: Data) throws -> Blob{
        guard data.count == 9 else{
            throw SmartCacheError.decodingFailed
        }
        let raw = data.prefix(8).withUnsafeBytes{ $0.loadUnaligned(as: Int64.self) }
        return Blob(byteSize: Int(Int64(littleEndian: raw)), marker: data[data.startIndex + 8])
    }
}

let kilobyte = 1024
