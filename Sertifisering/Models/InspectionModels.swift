import Foundation
import PencilKit
import SwiftData

enum InspectionStatus: String, CaseIterable, Identifiable, Codable {
    case approved = "Godkjent"
    case approvedWithRemarks = "Godkjent med mangel"
    case rejected = "Ikke godkjent"

    var id: String { rawValue }
}

enum InspectionWorkflowStatus: String, CaseIterable, Identifiable, Codable {
    case draft = "Utkast"
    case completedByTechnician = "Ferdig fra tekniker"
    case readyForOffice = "Klar for kontor"
    case processedByOffice = "Behandlet av kontor"
    case invoiced = "Fakturert"

    var id: String { rawValue }
}

enum ChecklistResult: String, CaseIterable, Identifiable, Codable {
    case ok = "OK"
    case remark = "Mangel"
    case notApplicable = "Ikke relevant"

    var id: String { rawValue }
}

enum MachineCategory: String, CaseIterable, Identifiable, Codable {
    case crane = "Kran"
    case hoist = "Heisemask. / Talje"
    case monorail = "Lettbane"
    case jibCrane = "Svingkran"
    case chainHoist = "Kjettingtalje"
    case other = "Annet"

    var id: String { rawValue }
}

struct ChecklistTemplate {
    let order: Int
    let title: String
    let items: [ChecklistTemplateItem]
}

struct ChecklistTemplateItem {
    let order: Int
    let code: String
    let title: String
}

enum InspectionTemplates {
    static let craneSections: [ChecklistTemplate] = [
        ChecklistTemplate(
            order: 1,
            title: "1 KRANBRO / HJULKASSER",
            items: [
                .init(order: 1, code: "1.1", title: "Sprekker, rust, deform."),
                .init(order: 2, code: "1.2", title: "Boltforbindelser"),
                .init(order: 3, code: "1.3", title: "Motor - børster"),
                .init(order: 4, code: "1.4", title: "Gearkasse / Oljenivå"),
                .init(order: 5, code: "1.5", title: "Kobling"),
                .init(order: 6, code: "1.6", title: "Brems"),
                .init(order: 7, code: "1.7", title: "Drivhj. / Styrer. smøring"),
                .init(order: 8, code: "1.8", title: "Løpehjul - smøring"),
                .init(order: 9, code: "1.9", title: "Endebryter"),
                .init(order: 10, code: "1.10", title: "Antikollisjonsutstyr"),
                .init(order: 11, code: "1.11", title: "Tannkranser - smøring")
            ]
        ),
        ChecklistTemplate(
            order: 2,
            title: "2 ELEKTRISK ANLEGG",
            items: [
                .init(order: 1, code: "2.1", title: "Kabelforbindelse"),
                .init(order: 2, code: "2.2", title: "Jordingsforbindelser"),
                .init(order: 3, code: "2.3", title: "Strekkavlastning"),
                .init(order: 4, code: "2.4", title: "Spenning (+/- 5 %)"),
                .init(order: 5, code: "2.5", title: "Kontaktorer"),
                .init(order: 6, code: "2.6", title: "Hovedbryter"),
                .init(order: 7, code: "2.7", title: "Strømtilførsel"),
                .init(order: 8, code: "2.8", title: "Tablå"),
                .init(order: 9, code: "2.9", title: "Nødstop")
            ]
        ),
        ChecklistTemplate(
            order: 3,
            title: "3 OVERLASTBRYTER",
            items: [
                .init(order: 1, code: "3.1", title: "Sprekker, rust, deform"),
                .init(order: 2, code: "3.2", title: "Innfestninger"),
                .init(order: 3, code: "3.3", title: "Funksjon")
            ]
        ),
        ChecklistTemplate(
            order: 4,
            title: "4 HEISEMASK. / KATT",
            items: [
                .init(order: 1, code: "4.1", title: "Sprekker, rust, deform."),
                .init(order: 2, code: "4.2", title: "Boltforbindelser"),
                .init(order: 3, code: "4.3", title: "Heisemotor - børster"),
                .init(order: 4, code: "4.4", title: "Kjøremotor - børster"),
                .init(order: 5, code: "4.5", title: "Geark. / Oljenivå - heis"),
                .init(order: 6, code: "4.6", title: "Kobling - heis"),
                .init(order: 7, code: "4.7", title: "Brems - heis"),
                .init(order: 8, code: "4.8", title: "Ståltauinnfestninger"),
                .init(order: 9, code: "4.9", title: "Ståltauskiver - smøring"),
                .init(order: 10, code: "4.10", title: "Ståltau - smøring"),
                .init(order: 11, code: "4.11", title: "Endebryter opp / ned"),
                .init(order: 12, code: "4.12", title: "Wireføring"),
                .init(order: 13, code: "4.13", title: "Trommel"),
                .init(order: 14, code: "4.14", title: "Slurekobling"),
                .init(order: 15, code: "4.15", title: "Drivhj./Styrer - smøring"),
                .init(order: 16, code: "4.16", title: "Endebryter - katt"),
                .init(order: 17, code: "4.17", title: "Gearkasse / olje - katt"),
                .init(order: 18, code: "4.18", title: "Kobling - katt"),
                .init(order: 19, code: "4.19", title: "Bremse - katt")
            ]
        ),
        ChecklistTemplate(
            order: 5,
            title: "5 KROKBLOKK",
            items: [
                .init(order: 1, code: "5.1", title: "Sprekker, rust, deform"),
                .init(order: 2, code: "5.2", title: "Boltforbindelser"),
                .init(order: 3, code: "5.3", title: "Ståltauskiver"),
                .init(order: 4, code: "5.4", title: "Svivel"),
                .init(order: 5, code: "5.5", title: "Låseleppe"),
                .init(order: 6, code: "5.6", title: "Krokgap / Slitasje")
            ]
        ),
        ChecklistTemplate(
            order: 6,
            title: "6 ADKOMST / RØMNING",
            items: [
                .init(order: 1, code: "6.1", title: "Trapp / Leider"),
                .init(order: 2, code: "6.2", title: "Gangvei / Platform / Luke"),
                .init(order: 3, code: "6.3", title: "Gelender / Rekkverk")
            ]
        ),
        ChecklistTemplate(
            order: 7,
            title: "7 FUNKSJONSPRØVING",
            items: [
                .init(order: 1, code: "7.1", title: "Alle maskinerier"),
                .init(order: 2, code: "7.2", title: "Endebrytere"),
                .init(order: 3, code: "7.3", title: "Bremser"),
                .init(order: 4, code: "7.4", title: "Anti-kollisjon"),
                .init(order: 5, code: "7.5", title: "Ned / Oppstoppsbryter")
            ]
        ),
        ChecklistTemplate(
            order: 8,
            title: "8 MERKING / DOKUM",
            items: [
                .init(order: 1, code: "8.1", title: "WLL/SWL-Kraner/krok"),
                .init(order: 2, code: "8.2", title: "Skilt: produsent, type, år"),
                .init(order: 3, code: "8.3", title: "Sertifikater")
            ]
        ),
        ChecklistTemplate(
            order: 9,
            title: "9 SVINGKRAN VEGG/SØYLE",
            items: [
                .init(order: 1, code: "9.1", title: "Kjøreprofil"),
                .init(order: 2, code: "9.2", title: "Høyde"),
                .init(order: 3, code: "9.3", title: "Boltfester")
            ]
        ),
        ChecklistTemplate(
            order: 10,
            title: "10 SPESIELT FOR LETTBANE",
            items: [
                .init(order: 1, code: "10.1", title: "Oppheng låsing / lager"),
                .init(order: 2, code: "10.2", title: "Kran"),
                .init(order: 3, code: "10.3", title: "Kranbane"),
                .init(order: 4, code: "10.4", title: "Endeplater")
            ]
        ),
        ChecklistTemplate(
            order: 11,
            title: "11 LØSE GJENSTANDER",
            items: [
                .init(order: 1, code: "11.1", title: "Finnes det løse gjenstander på løfteinnretningen")
            ]
        ),
        ChecklistTemplate(
            order: 12,
            title: "12 RESTLEVETID",
            items: [
                .init(order: 1, code: "12.1", title: "Er restlevetid dokumentert")
            ]
        )
    ]
}

@Model
final class Inspection {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date?
    var processedAt: Date?
    var invoicedAt: Date?
    var certificateNumber: String = "" { didSet { touch() } }
    var companyOwner: String = "" { didSet { touch() } }
    var contactPerson: String = "" { didSet { touch() } }
    var phone: String = "" { didSet { touch() } }
    var address: String = "" { didSet { touch() } }
    var inspector: String = "" { didSet { touch() } }
    var location: String = "" { didSet { touch() } }
    var projectNumber: String = "" { didSet { touch() } }
    var overallNotes: String = "" { didSet { touch() } }
    var signatureCustomerName: String = "" { didSet { touch() } }
    var signatureInspectorName: String = "" { didSet { touch() } }
    var attachmentsCount: String = "" { didSet { touch() } }
    @Attribute(.externalStorage) var customerSignatureData: Data = Data() { didSet { touch() } }
    @Attribute(.externalStorage) var inspectorSignatureData: Data = Data() { didSet { touch() } }
    var statusRawValue: String = InspectionStatus.approved.rawValue
    var workflowStatusRawValue: String = InspectionWorkflowStatus.draft.rawValue

    @Relationship(deleteRule: .cascade, inverse: \Machine.inspection)
    var machines: [Machine]? = []

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        completedAt: Date? = nil,
        processedAt: Date? = nil,
        invoicedAt: Date? = nil,
        certificateNumber: String = "",
        companyOwner: String = "",
        contactPerson: String = "",
        phone: String = "",
        address: String = "",
        inspector: String = "",
        location: String = "",
        projectNumber: String = "",
        overallNotes: String = "",
        signatureCustomerName: String = "",
        signatureInspectorName: String = "",
        attachmentsCount: String = "",
        customerSignatureData: Data = Data(),
        inspectorSignatureData: Data = Data(),
        status: InspectionStatus = .approved,
        workflowStatus: InspectionWorkflowStatus = .draft
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.processedAt = processedAt
        self.invoicedAt = invoicedAt
        self.certificateNumber = certificateNumber
        self.companyOwner = companyOwner
        self.contactPerson = contactPerson
        self.phone = phone
        self.address = address
        self.inspector = inspector
        self.location = location
        self.projectNumber = projectNumber
        self.overallNotes = overallNotes
        self.signatureCustomerName = signatureCustomerName
        self.signatureInspectorName = signatureInspectorName
        self.attachmentsCount = attachmentsCount
        self.customerSignatureData = customerSignatureData
        self.inspectorSignatureData = inspectorSignatureData
        self.statusRawValue = status.rawValue
        self.workflowStatusRawValue = workflowStatus.rawValue
        self.machines = []
    }

    var status: InspectionStatus {
        get { InspectionStatus(rawValue: statusRawValue) ?? .approved }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = .now
        }
    }

    var workflowStatus: InspectionWorkflowStatus {
        get { InspectionWorkflowStatus(rawValue: workflowStatusRawValue) ?? .draft }
        set {
            workflowStatusRawValue = newValue.rawValue
            updatedAt = .now

            switch newValue {
            case .draft:
                break
            case .completedByTechnician, .readyForOffice:
                completedAt = completedAt ?? .now
            case .processedByOffice:
                completedAt = completedAt ?? .now
                processedAt = processedAt ?? .now
            case .invoiced:
                completedAt = completedAt ?? .now
                processedAt = processedAt ?? .now
                invoicedAt = invoicedAt ?? .now
            }
        }
    }

    var customerSignatureDrawing: PKDrawing {
        get { (try? PKDrawing(data: customerSignatureData)) ?? PKDrawing() }
        set { customerSignatureData = newValue.dataRepresentation() }
    }

    var inspectorSignatureDrawing: PKDrawing {
        get { (try? PKDrawing(data: inspectorSignatureData)) ?? PKDrawing() }
        set { inspectorSignatureData = newValue.dataRepresentation() }
    }
}

extension Inspection {
    var isReadyForOfficeQueue: Bool {
        workflowStatus == .completedByTechnician || workflowStatus == .readyForOffice
    }

    var isBillingQueue: Bool {
        workflowStatus == .processedByOffice
    }

    var isInvoicedQueue: Bool {
        workflowStatus == .invoiced
    }

    var hasOfficeProcessingData: Bool {
        !certificateNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canExportPDF: Bool {
        !(machines ?? []).isEmpty
    }

    var canExportCertificateBasis: Bool {
        hasOfficeProcessingData && canExportPDF
    }

    var canProcessByOffice: Bool {
        missingOfficeProcessingRequirements.isEmpty
    }

    var missingOfficeProcessingRequirements: [String] {
        var missingRequirements: [String] = []

        if !isReadyForOfficeQueue {
            missingRequirements.append("Ferdig fra tekniker")
        }

        if !hasOfficeProcessingData {
            missingRequirements.append("Sertifikatnummer")
        }

        if !canExportPDF {
            missingRequirements.append("Minst én maskin")
        }

        return missingRequirements
    }

    var canCompleteByTechnician: Bool {
        missingTechnicianCompletionRequirements.isEmpty
    }

    var missingTechnicianCompletionRequirements: [String] {
        var missingRequirements: [String] = []

        if companyOwner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingRequirements.append("Firma/eier")
        }

        if inspector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingRequirements.append("Kontrollør")
        }

        if (machines ?? []).isEmpty {
            missingRequirements.append("Minst én maskin")
        }

        return missingRequirements
    }

    var checklistRemarkCount: Int {
        (machines ?? []).reduce(0) { count, machine in
            count + (machine.checklistItems ?? []).filter { $0.result == .remark }.count
        }
    }
}

@Model
final class Machine {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var name: String = "" { didSet { touch() } }
    var categoryRawValue: String = MachineCategory.crane.rawValue
    var machineType: String = "Kran" { didSet { touch() } }
    var serialNumber: String = "" { didSet { touch() } }
    var annualControl: Bool = true { didSet { touch() } }
    var fullService: Bool = false { didSet { touch() } }
    var manufacturer: String = "" { didSet { touch() } }
    var hoistType: String = "" { didSet { touch() } }
    var craneNumber: String = "" { didSet { touch() } }
    var hoistNumber: String = "" { didSet { touch() } }
    var internalLocation: String = "" { didSet { touch() } }
    var hourMeter: String = "" { didSet { touch() } }
    var loadIndicator: String = "" { didSet { touch() } }
    var certificateNumber: String = "" { didSet { touch() } }
    var notes: String = "" { didSet { touch() } }
    var looseObjectsFound: Bool = false { didSet { touch() } }
    var looseObjectsRemoved: Bool = false { didSet { touch() } }
    var remainingLifetimeDocumented: Bool = false { didSet { touch() } }
    var remainingLifetimeSWP: String = "" { didSet { touch() } }
    var usageCertificateValid: Bool = true { didSet { touch() } }

    var inspection: Inspection?

    @Relationship(deleteRule: .cascade, inverse: \MachineChecklistItem.machine)
    var checklistItems: [MachineChecklistItem]? = []

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        name: String = "",
        category: MachineCategory = .crane,
        machineType: String = "Kran",
        serialNumber: String = "",
        annualControl: Bool = true,
        fullService: Bool = false,
        manufacturer: String = "",
        hoistType: String = "",
        craneNumber: String = "",
        hoistNumber: String = "",
        internalLocation: String = "",
        hourMeter: String = "",
        loadIndicator: String = "",
        certificateNumber: String = "",
        notes: String = "",
        looseObjectsFound: Bool = false,
        looseObjectsRemoved: Bool = false,
        remainingLifetimeDocumented: Bool = false,
        remainingLifetimeSWP: String = "",
        usageCertificateValid: Bool = true
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
        self.categoryRawValue = category.rawValue
        self.machineType = machineType
        self.serialNumber = serialNumber
        self.annualControl = annualControl
        self.fullService = fullService
        self.manufacturer = manufacturer
        self.hoistType = hoistType
        self.craneNumber = craneNumber
        self.hoistNumber = hoistNumber
        self.internalLocation = internalLocation
        self.hourMeter = hourMeter
        self.loadIndicator = loadIndicator
        self.certificateNumber = certificateNumber
        self.notes = notes
        self.looseObjectsFound = looseObjectsFound
        self.looseObjectsRemoved = looseObjectsRemoved
        self.remainingLifetimeDocumented = remainingLifetimeDocumented
        self.remainingLifetimeSWP = remainingLifetimeSWP
        self.usageCertificateValid = usageCertificateValid
        self.checklistItems = []
    }

    var category: MachineCategory {
        get { MachineCategory(rawValue: categoryRawValue) ?? .crane }
        set {
            categoryRawValue = newValue.rawValue
            touch()
        }
    }

    private func touch() {
        updatedAt = .now
        inspection?.updatedAt = .now
    }
}

@Model
final class MachineChecklistItem {
    var id: UUID = UUID()
    var updatedAt: Date = Date()
    var sectionOrder: Int = 0
    var sectionTitle: String = ""
    var itemOrder: Int = 0
    var code: String = ""
    var title: String = ""
    var resultRawValue: String = ChecklistResult.ok.rawValue
    var note: String = "" { didSet { touch() } }

    var machine: Machine?

    init(
        id: UUID = UUID(),
        updatedAt: Date = .now,
        sectionOrder: Int,
        sectionTitle: String,
        itemOrder: Int,
        code: String,
        title: String,
        result: ChecklistResult = .ok,
        note: String = ""
    ) {
        self.id = id
        self.updatedAt = updatedAt
        self.sectionOrder = sectionOrder
        self.sectionTitle = sectionTitle
        self.itemOrder = itemOrder
        self.code = code
        self.title = title
        self.resultRawValue = result.rawValue
        self.note = note
    }

    var result: ChecklistResult {
        get { ChecklistResult(rawValue: resultRawValue) ?? .ok }
        set {
            resultRawValue = newValue.rawValue
            touch()
        }
    }

    private func touch() {
        updatedAt = .now
        machine?.updatedAt = .now
        machine?.inspection?.updatedAt = .now
    }
}

extension Machine {
    static func makeDefault() -> Machine {
        let machine = Machine(name: "Ny maskin")
        machine.checklistItems = makeChecklistItems()
        return machine
    }

    func copyForNewInspection() -> Machine {
        let machine = Machine(
            name: name,
            category: category,
            machineType: machineType,
            serialNumber: serialNumber,
            annualControl: annualControl,
            fullService: fullService,
            manufacturer: manufacturer,
            hoistType: hoistType,
            craneNumber: craneNumber,
            hoistNumber: hoistNumber,
            internalLocation: internalLocation,
            hourMeter: hourMeter,
            loadIndicator: loadIndicator,
            certificateNumber: certificateNumber,
            remainingLifetimeSWP: remainingLifetimeSWP
        )
        machine.checklistItems = Self.makeChecklistItems()
        return machine
    }

    private static func makeChecklistItems() -> [MachineChecklistItem] {
        InspectionTemplates.craneSections.flatMap { section in
            section.items.map { item in
                MachineChecklistItem(
                    sectionOrder: section.order,
                    sectionTitle: section.title,
                    itemOrder: item.order,
                    code: item.code,
                    title: item.title
                )
            }
        }
    }
}
