import Foundation
import PencilKit
import SwiftData

enum InspectionStatus: String, CaseIterable, Identifiable, Codable {
    case approved = "Godkjent"
    case approvedWithRemarks = "Godkjent med mangel"
    case rejected = "Ikke godkjent"

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
    var createdAt: Date
    var certificateNumber: String
    var companyOwner: String
    var contactPerson: String
    var phone: String
    var address: String
    var inspector: String
    var location: String
    var projectNumber: String
    var overallNotes: String
    var signatureCustomerName: String
    var signatureInspectorName: String
    var attachmentsCount: String
    @Attribute(.externalStorage) var customerSignatureData: Data
    @Attribute(.externalStorage) var inspectorSignatureData: Data
    var statusRawValue: String

    @Relationship(deleteRule: .cascade, inverse: \Machine.inspection)
    var machines: [Machine]

    init(
        createdAt: Date = .now,
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
        status: InspectionStatus = .approved
    ) {
        self.createdAt = createdAt
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
        self.machines = []
    }

    var status: InspectionStatus {
        get { InspectionStatus(rawValue: statusRawValue) ?? .approved }
        set { statusRawValue = newValue.rawValue }
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

@Model
final class Machine {
    var name: String
    var categoryRawValue: String
    var machineType: String
    var serialNumber: String
    var annualControl: Bool
    var fullService: Bool
    var manufacturer: String
    var hoistType: String
    var craneNumber: String
    var hoistNumber: String
    var internalLocation: String
    var hourMeter: String
    var loadIndicator: String
    var certificateNumber: String
    var notes: String
    var looseObjectsFound: Bool
    var looseObjectsRemoved: Bool
    var remainingLifetimeDocumented: Bool
    var remainingLifetimeSWP: String
    var usageCertificateValid: Bool

    var inspection: Inspection?

    @Relationship(deleteRule: .cascade, inverse: \MachineChecklistItem.machine)
    var checklistItems: [MachineChecklistItem]

    init(
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
        set { categoryRawValue = newValue.rawValue }
    }
}

@Model
final class MachineChecklistItem {
    var sectionOrder: Int
    var sectionTitle: String
    var itemOrder: Int
    var code: String
    var title: String
    var resultRawValue: String
    var note: String

    var machine: Machine?

    init(
        sectionOrder: Int,
        sectionTitle: String,
        itemOrder: Int,
        code: String,
        title: String,
        result: ChecklistResult = .ok,
        note: String = ""
    ) {
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
        set { resultRawValue = newValue.rawValue }
    }
}

extension Machine {
    static func makeDefault() -> Machine {
        let machine = Machine(name: "Ny maskin")
        machine.checklistItems = InspectionTemplates.craneSections.flatMap { section in
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
        return machine
    }
}
