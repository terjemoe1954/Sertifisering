//
//  SertifiseringApp.swift
//  Sertifisering
//
//  Created by Terje Moe on 03/09/2026.
//

import SwiftUI
import SwiftData

@main
struct SertifiseringApp: App {
    @UIApplicationDelegateAdaptor(CloudKitSharingAppDelegate.self) private var cloudKitSharingAppDelegate
    private let modelContainer: ModelContainer
    @AppStorage("app.appearance.mode") private var appearanceModeRawValue = AppAppearance.system.rawValue

    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))

        do {
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                Self.prepareUITestingDefaults()
                modelContainer = try PersistenceController.makeModelContainer(isStoredInMemoryOnly: true)
                Self.seedUITestingData(in: modelContainer.mainContext)
            } else {
                PersistenceController.registerMigrationBaselineIfNeeded()
                _ = try? PersistenceController.applyPendingRestoreIfNeeded()
                modelContainer = try PersistenceController.makeModelContainer()
            }
        } catch {
            fatalError("Kunne ikke opprette lokal database: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            InspectionListView()
                .preferredColorScheme(currentAppearance.colorScheme)
        }
        .modelContainer(modelContainer)
    }

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceModeRawValue) ?? .system
    }

    private static func prepareUITestingDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(AppAppearance.system.rawValue, forKey: "app.appearance.mode")
        defaults.set(AppUserRole.technician.rawValue, forKey: "app.user.role")
        defaults.set(false, forKey: PersistenceController.cloudKitEnabledDefaultsKey)
        defaults.removeObject(forKey: PersistenceController.cloudKitContainerDefaultsKey)
        defaults.removeObject(forKey: PersistenceController.pendingRestoreBackupNameKey)
        defaults.removeObject(forKey: "cloudkit.company.lastSyncStatus")
        defaults.removeObject(forKey: CloudKitSharingSupport.shareAcceptanceMessageDefaultsKey)
    }

    @MainActor
    private static func seedUITestingData(in modelContext: ModelContext) {
        let inspection = Inspection(
            certificateNumber: "UI-2026-001",
            companyOwner: "UI Testkunde AS",
            contactPerson: "Kari Test",
            phone: "40000000",
            address: "Testveien 1",
            inspector: "Tekniker Test",
            location: "Testhall",
            projectNumber: "UI-1001",
            status: .approvedWithRemarks,
            workflowStatus: .completedByTechnician
        )
        let machine = Machine(
            name: "UI Traverskran",
            machineType: "Kran",
            serialNumber: "UI-KR-1",
            manufacturer: "Konecranes",
            internalLocation: "Hall A",
            loadIndicator: "5T"
        )
        machine.checklistItems = [
            MachineChecklistItem(
                sectionOrder: 1,
                sectionTitle: "1 TEST",
                itemOrder: 1,
                code: "1.1",
                title: "Testpunkt",
                result: .remark,
                note: "UI-test mangel"
            )
        ]
        machine.inspection = inspection
        inspection.machines = [machine]

        modelContext.insert(inspection)
        modelContext.insert(machine)
        try? modelContext.save()
    }
}


 
