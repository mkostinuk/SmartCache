import Testing
import SmartCache

@Suite("Vocabulary")
struct VocabularyTests{

    @Test("Tiers run from the fastest to the slowest")
    func tierOrder(){
        #expect(StorageTier.memory < StorageTier.compressed)
        #expect(StorageTier.compressed < StorageTier.disk)
        #expect(StorageTier.allCases.count == 3)
    }

    @Test("Only the disk tier is outside the memory budget")
    func memoryBudgetMembership(){
        #expect(StorageTier.memory.usesMemoryBudget)
        #expect(StorageTier.compressed.usesMemoryBudget)
        #expect(!StorageTier.disk.usesMemoryBudget)
    }

    @Test("A negative refetch time is clamped to zero")
    func costClamping(){
        #expect(CacheCost(seconds: -1).seconds == 0)
        #expect(CacheCost(seconds: 0.2).isMetered == false)
        #expect(CacheCost.unknown.seconds == 0.05)
    }
}
