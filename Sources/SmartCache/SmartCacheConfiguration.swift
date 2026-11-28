import Foundation

/// Limits and rules one ``SmartCache`` instance runs by.
public struct SmartCacheConfiguration: Sendable{
    /// How many bytes the cache may hold in memory.
    public var memoryLimit: Int

    /// Refetch cost assumed for values inserted without one.
    public var defaultCost: CacheCost

    /// Creates a configuration.
    /// - Parameters:
    ///   - memoryLimit: How many bytes the cache may hold in memory.
    ///   - defaultCost: Refetch cost assumed for values inserted without one.
    public init(memoryLimit: Int = 32 * 1024 * 1024, defaultCost: CacheCost = .unknown){
        self.memoryLimit = memoryLimit
        self.defaultCost = defaultCost
    }

    /// Thirty-two megabytes in memory.
    public static let `default` = SmartCacheConfiguration()
}
