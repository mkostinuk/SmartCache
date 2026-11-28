import Foundation

/// How expensive it is to produce a value again once the cache has dropped it.
///
/// The cache fills this in by itself when the value is loaded through
/// ``SmartCache/value(for:fetch:)``: it measures how long the fetch took.
/// Pass it explicitly only when you insert values by hand and already know
/// what a refetch costs.
public struct CacheCost: Sendable, Equatable{
    /// How long one refetch takes, in seconds.
    public var seconds: TimeInterval

    /// Whether the value was fetched over a metered connection.
    ///
    /// Metered entries are weighted by
    /// ``SmartCacheConfiguration/meteredCostMultiplier`` so that the cache
    /// holds on to data the user has paid for.
    public var isMetered: Bool

    /// Creates a cost.
    /// - Parameters:
    ///   - seconds: How long one refetch takes.
    ///   - isMetered: Whether the value came over a metered connection.
    public init(seconds: TimeInterval, isMetered: Bool = false){
        self.seconds = max(0, seconds)
        self.isMetered = isMetered
    }

    /// A conservative cost for values whose refetch time is unknown.
    public static let unknown = CacheCost(seconds: 0.05)
}
