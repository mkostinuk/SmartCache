import Foundation
import Testing
@testable import SmartCache

@Suite("Memory store")
struct StoreTests{

    @Test("An inserted value comes back from the memory tier")
    func insertThenRead() async{
        let cache = SmartCache<String, Blob>()
        await cache.insert(Blob(byteSize: 10 * kilobyte, marker: 7), for: "a")

        #expect(await cache.value(for: "a")?.marker == 7)
        #expect(await cache.count == 1)
        #expect(await cache.contains("a"))
        #expect(await cache.tier(of: "a") == .memory)
    }

    @Test("A miss returns nil and counts as nothing")
    func miss() async{
        let cache = SmartCache<String, Blob>()

        #expect(await cache.value(for: "nope") == nil)
        #expect(await cache.statistics.memoryHits == 0)
        #expect(await cache.isEmpty)
    }

    @Test("Reinserting a key does not double-count its bytes")
    func reinsertKeepsCountersInSync() async{
        let cache = SmartCache<String, Blob>()
        await cache.insert(Blob(byteSize: 10 * kilobyte, marker: 1), for: "a")
        await cache.insert(Blob(byteSize: 4 * kilobyte, marker: 2), for: "a")

        #expect(await cache.count == 1)
        #expect(await cache.statistics.memoryBytes == 4 * kilobyte)
    }

    @Test("Dropping an entry gives its bytes back")
    func removeReleasesBytes() async{
        let cache = SmartCache<String, Blob>()
        await cache.insert(Blob(byteSize: 8 * kilobyte, marker: 1), for: "a")
        await cache.insert(Blob(byteSize: 2 * kilobyte, marker: 2), for: "b")

        await cache.remove("a")
        #expect(await cache.statistics.memoryBytes == 2 * kilobyte)

        await cache.removeAll()
        #expect(await cache.isEmpty)
        #expect(await cache.statistics.memoryBytes == 0)
    }

    @Test("Every read raises the frequency the policy will look at")
    func readRaisesFrequency() async{
        let cache = SmartCache<String, Blob>()
        await cache.insert(Blob(byteSize: kilobyte, marker: 1), for: "a")
        _ = await cache.value(for: "a")
        _ = await cache.value(for: "a")

        #expect(await cache.entries["a"]?.frequency == 3)
        #expect(await cache.statistics.memoryHits == 2)
    }

    @Test("Hits add up the refetch time they saved")
    func hitsAddUpSavedTime() async{
        let cache = SmartCache<String, Blob>()
        await cache.insert(Blob(byteSize: kilobyte, marker: 1), for: "a", cost: CacheCost(seconds: 0.5))
        _ = await cache.value(for: "a")
        _ = await cache.value(for: "a")

        #expect(await cache.statistics.secondsSaved == 1.0)
    }

    @Test("A value inserted without a cost gets the configured default")
    func defaultCostApplies() async{
        let cache = SmartCache<String, Blob>()
        await cache.insert(Blob(byteSize: kilobyte, marker: 1), for: "a")

        #expect(await cache.entries["a"]?.cost == .unknown)
    }
}
