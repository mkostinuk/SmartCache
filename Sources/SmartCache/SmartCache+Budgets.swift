import Foundation

extension SmartCache{

    func enforceLimits(){
        while memoryBytes > configuration.memoryLimit{
            guard let key = lowestScoreKey() else{
                break
            }
            let before = memoryBytes
            evict(key)
            if memoryBytes >= before{
                break
            }
        }
    }

    func lowestScoreKey() -> Key?{
        var best: (key: Key, score: Double)?

        for (key, entry) in entries{
            guard entry.memoryBytes > 0 else{
                continue
            }
            let value = score(for: entry)
            if let current = best{
                if value < current.score{
                    best = (key, value)
                }
            } else{
                best = (key, value)
            }
        }

        return best?.key
    }

    func score(for entry: CacheEntry<Value>) -> Double{
        let weighted = entry.cost.isMetered
            ? entry.cost.seconds * configuration.meteredCostMultiplier
            : entry.cost.seconds
        let candidate = EvictionPolicy.Candidate(
            byteSize: max(1, entry.memoryBytes),
            costSeconds: weighted,
            isMetered: entry.cost.isMetered,
            frequency: entry.frequency,
            lastAccess: entry.lastAccess,
            tier: entry.tier
        )
        return configuration.policy.score(candidate, entry.inflation)
    }

    func evict(_ key: Key){
        guard let entry = entries[key] else{
            return
        }
        inflation = score(for: entry)
        remove(key, countingAsEviction: true)
    }

    func remove(_ key: Key, countingAsEviction: Bool){
        guard let entry = entries.removeValue(forKey: key) else{
            return
        }
        memoryBytes -= entry.memoryBytes

        if countingAsEviction{
            counters.evictions += 1
        }
    }
}
