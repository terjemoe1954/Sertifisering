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
    @Test func cloudKitConfigurationIsPreparedButDisabledByDefault() async throws {
        let previousCloudKitEnabledValue = UserDefaults.standard.object(forKey: PersistenceController.cloudKitEnabledDefaultsKey)
        UserDefaults.standard.removeObject(forKey: PersistenceController.cloudKitEnabledDefaultsKey)
        defer {
            if let previousCloudKitEnabledValue {
                UserDefaults.standard.set(previousCloudKitEnabledValue, forKey: PersistenceController.cloudKitEnabledDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: PersistenceController.cloudKitEnabledDefaultsKey)
            }
        }

        #expect(PersistenceController.configuredCloudKitContainerIdentifier == "iCloud.com.terjemoe.Sertifisering")
        #expect(PersistenceController.isCloudKitPrepared == true)
        #expect(PersistenceController.isCloudKitEnabledInSettings == false)
    }

    @Test func defaultMachineContainsChecklistFromTemplate() async throws {
        let machine = Machine.makeDefault()
        let expectedCount = InspectionTemplates.craneSections.reduce(0) { $0 + $1.items.count }

        let checklistItems = machine.checklistItems ?? []

        #expect(checklistItems.count == expectedCount)
        #expect(checklistItems.contains(where: { $0.code == "1.1" }))
        #expect(checklistItems.contains(where: { $0.code == "1.10" }))
        #expect(checklistItems.contains(where: { $0.code == "10.4" }))
        #expect(checklistItems.contains(where: { $0.code == "12.1" }))
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

    @Test func officeQueueFlagsMatchWorkflowStatus() async throws {
        let draft = Inspection(workflowStatus: .draft)
        let completed = Inspection(workflowStatus: .completedByTechnician)
        let ready = Inspection(workflowStatus: .readyForOffice)
        let processed = Inspection(workflowStatus: .processedByOffice)
        let invoiced = Inspection(workflowStatus: .invoiced)

        #expect(draft.isReadyForOfficeQueue == false)
        #expect(completed.isReadyForOfficeQueue == true)
        #expect(ready.isReadyForOfficeQueue == true)

        #expect(processed.isBillingQueue == true)
        #expect(invoiced.isBillingQueue == false)
        #expect(invoiced.isInvoicedQueue == true)
    }

    @Test func officeProcessingDataRequiresCertificateNumber() async throws {
        let missingCertificateNumber = Inspection(certificateNumber: "  ", workflowStatus: .readyForOffice)
        let completedCertificateNumber = Inspection(certificateNumber: "S-2026-003", workflowStatus: .readyForOffice)

        #expect(missingCertificateNumber.hasOfficeProcessingData == false)
        #expect(completedCertificateNumber.hasOfficeProcessingData == true)
    }

    @Test func checklistRemarkCountCountsMachineRemarks() async throws {
        let inspection = Inspection()
        let machine = Machine()
        machine.checklistItems = [
            MachineChecklistItem(sectionOrder: 1, sectionTitle: "Seksjon", itemOrder: 1, code: "1.1", title: "OK", result: .ok),
            MachineChecklistItem(sectionOrder: 1, sectionTitle: "Seksjon", itemOrder: 2, code: "1.2", title: "Mangel", result: .remark),
            MachineChecklistItem(sectionOrder: 1, sectionTitle: "Seksjon", itemOrder: 3, code: "1.3", title: "Ikke relevant", result: .notApplicable)
        ]
        inspection.machines = [machine]

        #expect(inspection.checklistRemarkCount == 1)
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

    @Test func machineAndChecklistChangesCanStoreUpdatedTimestamps() async throws {
        let updatedAt = Date()
        let machine = Machine(updatedAt: updatedAt)
        let checklistItem = MachineChecklistItem(
            updatedAt: updatedAt,
            sectionOrder: 1,
            sectionTitle: "Seksjon",
            itemOrder: 1,
            code: "1.1",
            title: "Kontrollpunkt"
        )

        #expect(machine.updatedAt == updatedAt)
        #expect(checklistItem.updatedAt == updatedAt)
    }

    @Test func billingCSVExporterBuildsOfficeInvoiceRows() async throws {
        let inspection = Inspection(
            certificateNumber: "S-2026-001",
            companyOwner: "Kunde \"Nord\"; AS",
            contactPerson: "Ola Nordmann",
            phone: "40000000",
            address: "Industriveien 1",
            inspector: "Tekniker Test",
            location: "Verksted A",
            projectNumber: "P-1001",
            status: .approvedWithRemarks,
            workflowStatus: .processedByOffice
        )
        let machine = Machine(name: "Traverskran", machineType: "Kran", serialNumber: "KR-42")
        machine.checklistItems = [
            MachineChecklistItem(sectionOrder: 1, sectionTitle: "Seksjon", itemOrder: 1, code: "1.1", title: "Kontrollpunkt", result: .remark)
        ]
        inspection.machines = [machine]

        let csv = BillingCSVExporter.makeCSV(inspections: [inspection])

        #expect(csv.contains("\"Kunde\";\"Kontaktperson\";\"Telefon\""))
        #expect(csv.contains("\"Antall maskiner\";\"Antall mangler\";\"Maskiner\""))
        #expect(csv.contains("\"Kunde \"\"Nord\"\"; AS\""))
        #expect(csv.contains("\"Godkjent med mangel\";\"Behandlet av kontor\""))
        #expect(csv.contains("\"1\";\"1\";\"Traverskran Kran KR-42\""))
    }

    @Test func pdfExporterCreatesReadablePDFFile() async throws {
        let inspection = Inspection(
            certificateNumber: "S-2026-002",
            companyOwner: "Testkunde AS",
            contactPerson: "Kari Test",
            phone: "41111111",
            address: "Testveien 2",
            inspector: "Tekniker Test",
            location: "Testhall",
            projectNumber: "P-1002",
            overallNotes: "Test av PDF-grunnlag.",
            signatureCustomerName: "Kari Test",
            signatureInspectorName: "Tekniker Test",
            attachmentsCount: "1",
            status: .approved,
            workflowStatus: .processedByOffice
        )
        let machine = Machine.makeDefault()
        machine.name = "Traverskran test"
        machine.machineType = "Kran"
        machine.serialNumber = "PDF-42"
        inspection.machines = [machine]

        let url = try InspectionPDFExporter.export(inspection: inspection)
        let data = try Data(contentsOf: url)
        let signature = String(decoding: data.prefix(4), as: UTF8.self)

        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(data.count > 1_000)
        #expect(signature == "%PDF")
    }
}
