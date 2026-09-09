//
//  SertifiseringTests.swift
//  SertifiseringTests
//
//  Created by Terje Moe on 03/09/2026.
//

import Foundation
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

    @Test func workflowStatusRoundtripUsesStoredRawValueAndDates() async throws {
        let inspection = Inspection(workflowStatus: .draft)

        inspection.workflowStatus = .readyForOffice

        #expect(inspection.workflowStatus == .readyForOffice)
        #expect(inspection.workflowStatusRawValue == "Klar for kontor")
        #expect(inspection.completedAt != nil)
        #expect(inspection.updatedAt >= inspection.createdAt)
    }

    @Test func officeWorkflowStatusSetsProcessingAndInvoiceDates() async throws {
        let inspection = Inspection(workflowStatus: .completedByTechnician)

        inspection.workflowStatus = .processedByOffice
        inspection.workflowStatus = .invoiced

        #expect(inspection.workflowStatus == .invoiced)
        #expect(inspection.completedAt != nil)
        #expect(inspection.processedAt != nil)
        #expect(inspection.invoicedAt != nil)
    }

    @Test func appUserRolesHaveStableTitles() async throws {
        #expect(AppUserRole.technician.title == "Tekniker")
        #expect(AppUserRole.office.title == "Kontor")
        #expect(AppUserRole.admin.title == "Admin")
    }

    @Test func modelsHaveStableIdentifiers() async throws {
        let inspectionID = UUID()
        let machineID = UUID()
        let checklistItemID = UUID()
        let inspection = Inspection(id: inspectionID)
        let machine = Machine(id: machineID)
        let checklistItem = MachineChecklistItem(
            id: checklistItemID,
            sectionOrder: 1,
            sectionTitle: "Seksjon",
            itemOrder: 1,
            code: "1.1",
            title: "Kontrollpunkt"
        )

        #expect(inspection.id == inspectionID)
        #expect(machine.id == machineID)
        #expect(checklistItem.id == checklistItemID)
    }

    @Test func machineAndChecklistChangesUpdateTimestamps() async throws {
        let machine = Machine(updatedAt: .distantPast)
        let checklistItem = MachineChecklistItem(
            updatedAt: .distantPast,
            sectionOrder: 1,
            sectionTitle: "Seksjon",
            itemOrder: 1,
            code: "1.1",
            title: "Kontrollpunkt"
        )

        machine.name = "Oppdatert maskin"
        checklistItem.result = .remark

        #expect(machine.updatedAt > .distantPast)
        #expect(checklistItem.updatedAt > .distantPast)
    }
}
