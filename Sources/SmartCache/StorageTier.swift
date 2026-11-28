/// Where a cached value is kept.
///
/// Tiers are ordered from the fastest to the slowest, which is also the order
/// in which an entry is pushed down before it is dropped entirely.
public enum StorageTier: Int, Sendable, CaseIterable, Comparable{
    /// Decoded and ready to use.
    case memory
    /// Still in memory, but as ``SmartCacheValue/encodedForStorage()`` data, so it needs decoding.
    case compressed
    /// In a file, so it needs a read and decoding.
    case disk

    /// Compares tiers by speed: ``memory`` is the smallest.
    public static func < (lhs: StorageTier, rhs: StorageTier) -> Bool{
        lhs.rawValue < rhs.rawValue
    }

    /// Whether values on this tier take up the memory budget.
    public var usesMemoryBudget: Bool{
        self != .disk
    }
}
