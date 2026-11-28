import Foundation

/// What the cache did since it was created.
public struct SmartCacheStatistics: Sendable, Equatable{
    /// Lookups served from memory.
    public var memoryHits = 0
    /// Refetch time avoided by hits, in seconds.
    public var secondsSaved: TimeInterval = 0
    /// Bytes currently held in memory.
    public var memoryBytes = 0

    /// Creates empty statistics.
    public init(){}
}
