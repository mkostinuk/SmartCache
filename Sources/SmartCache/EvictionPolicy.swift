import Foundation

/// Decides which entry leaves first when the cache is over budget.
///
/// The entry with the **lowest** score goes first. The built-in ``gdsf``
/// policy scores an entry as
///
/// ```
/// inflation + frequency * costSeconds / sizeInKilobytes
/// ```
///
/// so a big value that is cheap to fetch again loses to a small value that is
/// expensive to fetch again, and a rarely used entry loses to a popular one.
///
/// `inflation` is a rising floor. The cache remembers the score of every entry
/// it drops, and stamps the floor of that moment onto an entry whenever the
/// entry is written or read. An entry nobody reads any more keeps an old, low
/// stamp while the floor climbs past it, so yesterday's favourite cannot hold
/// a slot forever.
public struct EvictionPolicy: Sendable{
    /// The entry the policy is asked about.
    public struct Candidate: Sendable{
        /// Size of the entry on its current tier, in bytes.
        public let byteSize: Int
        /// Refetch time, already weighted by ``SmartCacheConfiguration/meteredCostMultiplier``.
        public let costSeconds: TimeInterval
        /// Whether the value came over a metered connection.
        public let isMetered: Bool
        /// How many times the entry has been read.
        public let frequency: Int
        /// When the entry was read last.
        public let lastAccess: Date
        /// The tier the entry is on right now.
        public let tier: StorageTier
    }

    let score: @Sendable (Candidate, Double) -> Double

    init(score: @escaping @Sendable (Candidate, Double) -> Double){
        self.score = score
    }

    /// Greedy Dual-Size Frequency: keeps what is expensive, small and popular.
    ///
    /// This is the default and the reason the package exists.
    public static let gdsf = EvictionPolicy{ candidate, inflation in
        let kilobytes = max(1, Double(candidate.byteSize) / 1024)
        return inflation + Double(candidate.frequency) * candidate.costSeconds / kilobytes
    }

    /// Plain least recently used, ignoring cost and size.
    ///
    /// Handy as a baseline when you want to measure what the cost-aware
    /// policy actually buys you.
    public static let leastRecentlyUsed = EvictionPolicy{ candidate, _ in
        candidate.lastAccess.timeIntervalSinceReferenceDate
    }

    /// Scores entries with your own formula; the lowest score leaves first.
    /// - Parameter score: Called for every candidate when the cache is over budget.
    public static func custom(_ score: @escaping @Sendable (Candidate) -> Double) -> EvictionPolicy{
        EvictionPolicy{ candidate, _ in score(candidate) }
    }
}
