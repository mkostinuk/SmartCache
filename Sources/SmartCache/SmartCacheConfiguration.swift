import Foundation

/// Limits and rules one ``SmartCache`` instance runs by.
public struct SmartCacheConfiguration: Sendable{
    /// How many bytes the cache may hold in memory.
    public var memoryLimit: Int

    /// Decides which entry leaves when the cache is over budget.
    public var policy: EvictionPolicy

    /// How much more a value fetched over a metered connection is worth.
    public var meteredCostMultiplier: Double

    /// Refetch cost assumed for values inserted without one.
    public var defaultCost: CacheCost

    /// Creates a configuration.
    /// - Parameters:
    ///   - memoryLimit: How many bytes the cache may hold in memory.
    ///   - policy: Which entry leaves first; ``EvictionPolicy/gdsf`` by default.
    ///   - meteredCostMultiplier: How much more a metered fetch is worth.
    ///   - defaultCost: Refetch cost assumed for values inserted without one.
    public init(
        memoryLimit: Int = 32 * 1024 * 1024,
        policy: EvictionPolicy = .gdsf,
        meteredCostMultiplier: Double = 2,
        defaultCost: CacheCost = .unknown
    ){
        self.memoryLimit = memoryLimit
        self.policy = policy
        self.meteredCostMultiplier = meteredCostMultiplier
        self.defaultCost = defaultCost
    }

    /// Thirty-two megabytes in memory, ranked by ``EvictionPolicy/gdsf``.
    public static let `default` = SmartCacheConfiguration()
}
