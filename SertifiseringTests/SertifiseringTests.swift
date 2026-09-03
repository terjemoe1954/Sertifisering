//
//  SertifiseringTests.swift
//  SertifiseringTests
//
//  Created by Terje Moe on 03/09/2026.
//

import Testing
@testable import Sertifisering

@MainActor
struct SertifiseringTests {
    @Test func cloudKitConfigurationStaysLocalWithoutRealContainerIdentifier() async throws {
        #expect(PersistenceController.configuredCloudKitContainerIdentifier == nil)
        #expect(PersistenceController.isCloudKitPrepared == false)
    }

    @Test func defaultMachineContainsChecklistFromTemplate() async throws {
        let machine = Machine.makeDefault()
        let expectedCount = InspectionTemplates.craneSections.reduce(0) { $0 + $1.items.count }

        #expect(machine.checklistItems.count == expectedCount)
        #expect(machine.checklistItems.contains(where: { $0.code == "1.1" }))
        #expect(machine.checklistItems.contains(where: { $0.code == "1.10" }))
        #expect(machine.checklistItems.contains(where: { $0.code == "10.4" }))
        #expect(machine.checklistItems.contains(where: { $0.code == "12.1" }))
    }

    @Test func statusRoundtripUsesStoredRawValue() async throws {
        let inspection = Inspection(status: .approvedWithRemarks)

        #expect(inspection.status == .approvedWithRemarks)
        #expect(inspection.statusRawValue == "Godkjent med mangel")
    }
}
