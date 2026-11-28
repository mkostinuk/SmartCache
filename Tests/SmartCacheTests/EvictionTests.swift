import Foundation
import Testing
@testable import SmartCache

@Suite("Eviction")
struct EvictionTests{

    @Test("The budget is enforced on every insert")
    func budgetIsEnforced() async{
        let cache = SmartCache<String, Blob>(configuration: SmartCacheConfiguration(memoryLimit: 10 * kilobyte))
        for index in 0..<5{
            await cache.insert(Blob(byteSize: 4 * kilobyte, marker: UInt8(index)), for: "k\(index)")
        }

        #expect(await cache.statistics.memoryBytes <= 10 * kilobyte)
        #expect(await cache.count < 5)
        #expect(await cache.statistics.evictions > 0)
    }

    @Test("GDSF drops the big cheap entry and keeps the small expensive one")
    func gdsfKeepsTheExpensiveEntry() async{
        let cache = SmartCache<String, Blob>(configuration: SmartCacheConfiguration(memoryLimit: 18 * kilobyte))

        await cache.insert(Blob(byteSize: 4 * kilobyte, marker: 1), for: "expensive", cost: CacheCost(seconds: 2))
        await cache.insert(Blob(byteSize: 16 * kilobyte, marker: 2), for: "cheap", cost: CacheCost(seconds: 0.01))

        #expect(await cache.contains("expensive"))
        #expect(await cache.contains("cheap") == false)
    }

    @Test("The same two inserts under LRU drop the expensive one instead")
    func lruDropsTheExpensiveEntry() async{
        let configuration = SmartCacheConfiguration(memoryLimit: 18 * kilobyte, policy: .leastRecentlyUsed)
        let cache = SmartCache<String, Blob>(configuration: configuration)

        await cache.insert(Blob(byteSize: 4 * kilobyte, marker: 1), for: "expensive", cost: CacheCost(seconds: 2))
        try? await Task.sleep(for: .milliseconds(5))
        await cache.insert(Blob(byteSize: 16 * kilobyte, marker: 2), for: "cheap", cost: CacheCost(seconds: 0.01))

        #expect(await cache.contains("expensive") == false)
        #expect(await cache.contains("cheap"))
    }

    @Test("Frequency decides between entries of the same size and cost")
    func frequencyDecides() async{
        let cache = SmartCache<String, Blob>(configuration: SmartCacheConfiguration(memoryLimit: 13 * kilobyte))

        await cache.insert(Blob(byteSize: 6 * kilobyte, marker: 1), for: "read", cost: CacheCost(seconds: 1))
        await cache.insert(Blob(byteSize: 6 * kilobyte, marker: 2), for: "unread", cost: CacheCost(seconds: 1))
        _ = await cache.value(for: "read")
        _ = await cache.value(for: "read")
        await cache.insert(Blob(byteSize: 2 * kilobyte, marker: 3), for: "newcomer", cost: CacheCost(seconds: 10))

        #expect(await cache.contains("read"))
        #expect(await cache.contains("unread") == false)
        #expect(await cache.contains("newcomer"))
    }

    @Test("A metered fetch is worth more than the same fetch over wifi")
    func meteredEntriesAreWorthMore() async{
        let cache = SmartCache<String, Blob>(configuration: SmartCacheConfiguration(memoryLimit: 10 * kilobyte))

        await cache.insert(Blob(byteSize: 6 * kilobyte, marker: 1), for: "cellular", cost: CacheCost(seconds: 0.5, isMetered: true))
        await cache.insert(Blob(byteSize: 6 * kilobyte, marker: 2), for: "wifi", cost: CacheCost(seconds: 0.5))

        #expect(await cache.contains("cellular"))
        #expect(await cache.contains("wifi") == false)
    }

    @Test("A custom policy decides on its own terms")
    func customPolicyWins() async{
        let bySize = EvictionPolicy.custom{ candidate in Double(candidate.byteSize) }
        let cache = SmartCache<String, Blob>(configuration: SmartCacheConfiguration(memoryLimit: 10 * kilobyte, policy: bySize))

        await cache.insert(Blob(byteSize: 2 * kilobyte, marker: 1), for: "small")
        await cache.insert(Blob(byteSize: 3 * kilobyte, marker: 2), for: "medium")
        await cache.insert(Blob(byteSize: 8 * kilobyte, marker: 3), for: "big")

        #expect(await cache.contains("big"))
        #expect(await cache.contains("small") == false)
        #expect(await cache.contains("medium") == false)
    }

    @Test("Inflation eventually takes the slot away from a stale favourite")
    func inflationAgesOutAStaleFavourite() async{
        let cache = SmartCache<String, Blob>(configuration: SmartCacheConfiguration(memoryLimit: 10 * kilobyte))
        await cache.insert(Blob(byteSize: kilobyte, marker: 0), for: "favourite", cost: CacheCost(seconds: 10))

        var fillers = 0
        while await cache.contains("favourite"), fillers < 500{
            await cache.insert(Blob(byteSize: kilobyte, marker: 1), for: "filler\(fillers)", cost: CacheCost(seconds: 1))
            fillers += 1
        }

        #expect(fillers > 10)
        #expect(fillers < 500)
    }
}
