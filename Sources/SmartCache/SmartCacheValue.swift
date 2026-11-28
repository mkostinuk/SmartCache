import Foundation

/// A value that ``SmartCache`` is able to measure, encode and restore.
///
/// Conformance gives the cache the three things it needs in order to make
/// eviction decisions on its own:
///
/// - the memory footprint of the value, so a big entry is not treated like a small one;
/// - a compact representation for the ``StorageTier/compressed`` and ``StorageTier/disk`` tiers;
/// - a way back from that representation.
///
/// `Data` and every `Codable` type already conform. For images use the
/// `UIImage` conformance shipped with the package, where the compact
/// representation is JPEG data instead of a decoded bitmap.
public protocol SmartCacheValue: Sendable{
    /// Approximate size of the value while it is kept decoded in memory, in bytes.
    ///
    /// The number does not have to be exact, but it has to be comparable
    /// between values of the same type: the eviction policy divides the
    /// refetch cost by this size.
    var cacheByteSize: Int{ get }

    /// Returns the compact representation stored by the lower tiers.
    func encodedForStorage() throws -> Data

    /// Restores a value from the representation produced by ``encodedForStorage()``.
    static func decoded(from data: Data) throws -> Self
}
