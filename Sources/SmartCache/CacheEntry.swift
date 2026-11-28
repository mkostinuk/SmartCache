import Foundation

struct CacheEntry<Value: SmartCacheValue>{
    var value: Value
    var tier: StorageTier
    var memoryBytes: Int
    var cost: CacheCost
    var frequency: Int
    var lastAccess: Date
}
