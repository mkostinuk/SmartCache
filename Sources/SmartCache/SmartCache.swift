import Foundation

/// A cache that keeps track of what each value cost to obtain.
///
/// Every entry carries a ``CacheCost`` — how long a refetch would take — and
/// the number of times it has been read. When the cache runs out of budget it
/// ranks entries by cost, size and use through an ``EvictionPolicy``, so an
/// image that takes two seconds to download again outlives one that takes five
/// milliseconds to read from disk.
///
/// ```swift
/// let cache = SmartCache<String, Data>()
/// await cache.insert(payload, for: "profile", cost: CacheCost(seconds: 0.4))
/// let cached = await cache.value(for: "profile")
/// ```
///
/// The type is an `actor`, so concurrent lookups and inserts are safe without
/// any locking on the caller's side.
public actor SmartCache<Key: Hashable & Sendable, Value: SmartCacheValue>{
    /// Limits and rules this instance runs by.
    public let configuration: SmartCacheConfiguration

    var entries: [Key: CacheEntry<Value>] = [:]
    var counters = SmartCacheStatistics()
    var inflation: Double = 0
    var memoryBytes = 0

    /// Creates a cache.
    /// - Parameter configuration: Limits and rules; ``SmartCacheConfiguration/default`` allows 32 MB in memory.
    public init(configuration: SmartCacheConfiguration = .default){
        self.configuration = configuration
    }

    // MARK: - Reading

    /// Returns the cached value, or `nil` on a miss.
    /// - Parameter key: Key to look up.
    public func value(for key: Key) -> Value?{
        read(key)
    }

    /// Whether the key is cached.
    /// - Parameter key: Key to look up.
    public func contains(_ key: Key) -> Bool{
        entries[key] != nil
    }

    /// How many entries are cached.
    public var count: Int{
        entries.count
    }

    /// Whether the cache holds nothing at all.
    public var isEmpty: Bool{
        entries.isEmpty
    }

    /// The tier the key currently sits on, or `nil` if it is not cached.
    /// - Parameter key: Key to look up.
    public func tier(of key: Key) -> StorageTier?{
        entries[key]?.tier
    }

    /// What the cache did since it was created, or since the last ``resetStatistics()``.
    public var statistics: SmartCacheStatistics{
        var snapshot = counters
        snapshot.memoryBytes = memoryBytes
        return snapshot
    }

    /// Zeroes the counters without touching the cached values.
    public func resetStatistics(){
        counters = SmartCacheStatistics()
    }

    // MARK: - Writing

    /// Caches a value you already have.
    /// - Parameters:
    ///   - value: Value to cache.
    ///   - key: Key to cache it under.
    ///   - cost: What a refetch would cost; ``SmartCacheConfiguration/defaultCost`` when omitted.
    public func insert(_ value: Value, for key: Key, cost: CacheCost? = nil){
        remove(key, countingAsEviction: false)

        let size = max(1, value.cacheByteSize)
        entries[key] = CacheEntry(
            value: value,
            tier: .memory,
            memoryBytes: size,
            cost: cost ?? configuration.defaultCost,
            frequency: 1,
            lastAccess: Date(),
            inflation: inflation
        )
        memoryBytes += size

        enforceLimits()
    }

    /// Drops the entry for a key.
    /// - Parameter key: Key to drop.
    public func remove(_ key: Key){
        remove(key, countingAsEviction: false)
    }

    /// Drops every entry.
    public func removeAll(){
        entries.removeAll()
        memoryBytes = 0
        inflation = 0
    }

    // MARK: - Hits

    private func read(_ key: Key) -> Value?{
        guard var entry = entries[key] else{
            return nil
        }

        entry.frequency += 1
        entry.lastAccess = Date()
        entry.inflation = inflation
        entries[key] = entry

        counters.memoryHits += 1
        counters.secondsSaved += entry.cost.seconds
        return entry.value
    }
}
