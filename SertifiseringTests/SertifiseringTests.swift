//
//  SertifiseringTests.swift
//  SertifiseringTests
//
//  Created by Terje Moe on 03/09/2026.
//

import Foundation
import SwiftData
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

    @Test func inMemoryModelContainerCanStoreInspection() async throws {
        let container = try PersistenceController.makeModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let inspection = Inspection(companyOwner: "Testkunde AS")

        context.insert(inspection)
        try context.save()

        #expect(inspection.companyOwner == "Testkunde AS")
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

    @Test func officeProcessingRequirementsListMissingFields() async throws {
        let inspection = Inspection(certificateNumber: "", workflowStatus: .draft)

        #expect(inspection.canProcessByOffice == false)
        #expect(inspection.missingOfficeProcessingRequirements == ["Ferdig fra tekniker", "Sertifikatnummer", "Minst én maskin"])

        inspection.workflowStatus = .completedByTechnician
        inspection.certificateNumber = "S-2026-006"
        inspection.machines = [Machine.makeDefault()]

        #expect(inspection.missingOfficeProcessingRequirements.isEmpty)
        #expect(inspection.canProcessByOffice == true)
    }

    @Test func exportsRequireRequiredOfficeData() async throws {
        let inspection = Inspection(certificateNumber: "", workflowStatus: .readyForOffice)

        #expect(inspection.canExportPDF == false)
        #expect(inspection.canExportCertificateBasis == false)

        inspection.certificateNumber = "S-2026-005"
        #expect(inspection.canExportPDF == false)
        #expect(inspection.canExportCertificateBasis == false)

        inspection.machines = [Machine.makeDefault()]
        #expect(inspection.canExportPDF == true)
        #expect(inspection.canExportCertificateBasis == true)
    }

    @Test func technicianCompletionRequirementsListMissingFields() async throws {
        let draft = Inspection(companyOwner: "  ", inspector: "")

        #expect(draft.canCompleteByTechnician == false)
        #expect(draft.missingTechnicianCompletionRequirements == ["Firma/eier", "Kontrollør", "Minst én maskin"])

        draft.companyOwner = "Kunde AS"
        draft.inspector = "Tekniker Test"
        draft.machines = [Machine.makeDefault()]

        #expect(draft.missingTechnicianCompletionRequirements.isEmpty)
        #expect(draft.canCompleteByTechnician == true)
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

    @Test func machineCopyForNewInspectionKeepsIdentityAndResetsChecklist() async throws {
        let sourceMachine = Machine(
            name: "Traverskran",
            category: .crane,
            machineType: "Kran",
            serialNumber: "KR-42",
            annualControl: true,
            fullService: true,
            manufacturer: "Konecranes",
            hoistType: "Talje",
            craneNumber: "K-10",
            hoistNumber: "T-20",
            internalLocation: "Hall A",
            hourMeter: "1200",
            loadIndicator: "5T",
            certificateNumber: "OLD-1",
            notes: "Gammel merknad",
            looseObjectsFound: true,
            looseObjectsRemoved: true,
            remainingLifetimeDocumented: true,
            remainingLifetimeSWP: "900",
            usageCertificateValid: false
        )
        sourceMachine.checklistItems = [
            MachineChecklistItem(sectionOrder: 1, sectionTitle: "Seksjon", itemOrder: 1, code: "1.1", title: "Kontrollpunkt", result: .remark, note: "Gammel mangel")
        ]

        let copiedMachine = sourceMachine.copyForNewInspection()
        let copiedChecklistItems = copiedMachine.checklistItems ?? []

        #expect(copiedMachine.id != sourceMachine.id)
        #expect(copiedMachine.name == "Traverskran")
        #expect(copiedMachine.serialNumber == "KR-42")
        #expect(copiedMachine.manufacturer == "Konecranes")
        #expect(copiedMachine.internalLocation == "Hall A")
        #expect(copiedMachine.notes.isEmpty)
        #expect(copiedMachine.looseObjectsFound == false)
        #expect(copiedMachine.usageCertificateValid == true)
        #expect(copiedChecklistItems.count == InspectionTemplates.craneSections.reduce(0) { $0 + $1.items.count })
        #expect(copiedChecklistItems.allSatisfy { $0.result == .ok && $0.note.isEmpty })
    }

    @Test func customerOverviewGroupsInspectionsByCustomerName() async throws {
        let firstInspection = Inspection(
            companyOwner: " Kunde AS ",
            location: "Verksted",
            workflowStatus: .readyForOffice
        )
        firstInspection.machines = [Machine(name: "Traverskran", serialNumber: "KR-42")]

        let secondInspection = Inspection(
            companyOwner: "Kunde AS",
            location: "Lager",
            workflowStatus: .processedByOffice
        )
        secondInspection.machines = [
            Machine(name: "Traverskran", serialNumber: "KR-42"),
            Machine(name: "Lettbane", serialNumber: "LB-7")
        ]

        let missingCustomer = Inspection(companyOwner: "   ")

        let entries = CustomerOverviewEntry.makeEntries(from: [missingCustomer, secondInspection, firstInspection])

        #expect(entries.count == 1)
        #expect(entries.first?.name == "Kunde AS")
        #expect(entries.first?.inspections.count == 2)
        #expect(entries.first?.machineCount == 2)
        #expect(entries.first?.machineSummaries.first(where: { $0.title == "Traverskran" })?.inspections.count == 2)
        #expect(entries.first?.readyForOfficeCount == 1)
        #expect(entries.first?.billingQueueCount == 1)
    }

    @Test func billingCSVExporterBuildsOfficeInvoiceRows() async throws {
        let inspectionID = try #require(UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
        let exportedAt = Date(timeIntervalSince1970: 1_800_100_000)
        let createdAt = Date(timeIntervalSince1970: 1_799_800_000)
        let updatedAt = Date(timeIntervalSince1970: 1_799_900_000)
        let invoicedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let inspection = Inspection(
            id: inspectionID,
            createdAt: createdAt,
            updatedAt: updatedAt,
            certificateNumber: "S-2026-001",
            companyOwner: "Kunde \"Nord\"; AS",
            contactPerson: "Ola Nordmann",
            phone: "40000000",
            address: "Industriveien 1",
            inspector: "Tekniker Test",
            location: "Verksted A",
            projectNumber: "P-1001",
            overallNotes: "Avklar pris; \"ekstra\" arbeid",
            attachmentsCount: "3",
            status: .approvedWithRemarks,
            workflowStatus: .invoiced
        )
        inspection.invoicedAt = invoicedAt
        let crane = Machine(name: "Traverskran", machineType: "Kran", serialNumber: "KR-42")
        crane.checklistItems = [
            MachineChecklistItem(sectionOrder: 1, sectionTitle: "Seksjon", itemOrder: 1, code: "1.1", title: "Kontrollpunkt", result: .remark),
            MachineChecklistItem(sectionOrder: 1, sectionTitle: "Seksjon", itemOrder: 2, code: "1.2", title: "OK-punkt", result: .ok)
        ]
        let hoist = Machine(name: "A-lofter", machineType: "Talje", serialNumber: "AL-1")
        hoist.checklistItems = [
            MachineChecklistItem(sectionOrder: 2, sectionTitle: "Seksjon", itemOrder: 1, code: "2.1", title: "Taljemangel", result: .remark)
        ]
        inspection.machines = [crane, hoist]

        let csv = BillingCSVExporter.makeCSV(inspections: [inspection], exportedAt: exportedAt)
        let exportedURL = try BillingCSVExporter.export(inspections: [inspection], exportedAt: exportedAt)
        let exportedData = try Data(contentsOf: exportedURL)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "nb_NO")
        let expectedExportedDate = dateFormatter.string(from: exportedAt)
        let expectedCreatedDate = dateFormatter.string(from: createdAt)
        let expectedUpdatedDate = dateFormatter.string(from: updatedAt)
        let expectedInvoicedDate = dateFormatter.string(from: invoicedAt)

        #expect(exportedURL.lastPathComponent.hasPrefix("fakturagrunnlag-"))
        #expect(exportedURL.lastPathComponent.hasSuffix(".csv"))
        #expect(exportedData.starts(with: [0xEF, 0xBB, 0xBF]))
        #expect(csv.contains("\r\n\"11111111-2222-3333-4444-555555555555\""))
        #expect(csv.contains("\"Kontroll-ID\";\"Eksportert\";\"Opprettet\";\"Sist endret\";\"Kunde\""))
        #expect(csv.contains("\"11111111-2222-3333-4444-555555555555\";\"\(expectedExportedDate)\";\"\(expectedCreatedDate)\";\"\(expectedUpdatedDate)\";\"Kunde \"\"Nord\"\"; AS\""))
        #expect(csv.contains("\"Arbeidsstatus\";\"Fakturastatus\";\"Fullført\";\"Behandlet\";\"Fakturert\""))
        #expect(csv.contains("\"Antall vedlegg\";\"Antall maskiner\";\"Antall mangler\";\"Mangelpunkter\";\"Maskiner\";\"Merknader\""))
        #expect(csv.contains("\"Godkjent med mangel\";\"Fakturert\";\"Fakturert\""))
        #expect(csv.contains("\"\(expectedInvoicedDate)\";\"3\";\"2\";\"2\";\"A-lofter: 2.1 Taljemangel | Traverskran: 1.1 Kontrollpunkt\";\"A-lofter Talje AL-1 | Traverskran Kran KR-42\";\"Avklar pris; \"\"ekstra\"\" arbeid\""))
    }

    @Test func certificateBasisExporterBuildsOfficeSummary() async throws {
        let inspection = Inspection(
            certificateNumber: "S-2026-004",
            companyOwner: "Testkunde AS",
            contactPerson: "Kari Test",
            phone: "41111111",
            address: "Testveien 2",
            inspector: "Tekniker Test",
            location: "Testhall",
            projectNumber: "P-1004",
            overallNotes: "Kontroller før sertifikat.",
            signatureCustomerName: "Kari Test",
            signatureInspectorName: "Tekniker Test",
            status: .approvedWithRemarks,
            workflowStatus: .processedByOffice
        )
        let machine = Machine(
            name: "Traverskran test",
            machineType: "Kran",
            serialNumber: "KR-99",
            manufacturer: "Konecranes",
            craneNumber: "K-99",
            internalLocation: "Hall B",
            loadIndicator: "5T"
        )
        machine.checklistItems = [
            MachineChecklistItem(sectionOrder: 1, sectionTitle: "Seksjon", itemOrder: 1, code: "1.1", title: "Sprekker", result: .remark, note: "Utbedres")
        ]
        inspection.machines = [machine]

        let text = CertificateBasisExporter.makeText(inspection: inspection)

        #expect(text.contains("Sertifikatgrunnlag"))
        #expect(text.contains("Sertifikatnummer: S-2026-004"))
        #expect(text.contains("Kunde: Testkunde AS"))
        #expect(text.contains("- Traverskran test / KR-99"))
        #expect(text.contains("Produsent: Konecranes"))
        #expect(text.contains("Antall mangler: 1"))
        #expect(text.contains("1.1 Sprekker - Utbedres"))
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
        machine.checklistItems?.first?.result = .remark
        machine.checklistItems?.first?.note = "Dette er en lengre merknad som skal få bedre plass i rapporten og brytes over flere linjer uten at resten av tabellen blir unødvendig bred."
        inspection.machines = [machine]

        let url = try InspectionPDFExporter.export(inspection: inspection)
        let data = try Data(contentsOf: url)
        let signature = String(decoding: data.prefix(4), as: UTF8.self)

        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(data.count > 1_000)
        #expect(signature == "%PDF")
    }
}
