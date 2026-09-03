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
    private let modelContainer: ModelContainer
    @AppStorage("app.appearance.mode") private var appearanceModeRawValue = AppAppearance.system.rawValue

    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))

        do {
            PersistenceController.registerMigrationBaselineIfNeeded()
            _ = try? PersistenceController.applyPendingRestoreIfNeeded()
            modelContainer = try PersistenceController.makeModelContainer()
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
}


 
