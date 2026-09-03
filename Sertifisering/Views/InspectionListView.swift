//
//  InspectionListView.swift
//  Sertifisering
//
//  Created by Terje Moe on 03/09/2026.
//

import SwiftUI
import SwiftData

struct InspectionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Inspection.createdAt, order: .reverse) private var inspections: [Inspection]
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            List {
                if inspections.isEmpty {
                    ContentUnavailableView(
                        "Ingen kontroller ennå",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Opprett første kontroll og registrer maskiner direkte hos kunde.")
                    )
                } else {
                    ForEach(inspections) { inspection in
                        NavigationLink {
                            InspectionDetailView(inspection: inspection)
                        } label: {
                            InspectionRow(inspection: inspection)
                        }
                    }
                    .onDelete(perform: deleteInspection)
                }
            }
            .navigationTitle("Sertifisering")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Innstillinger", systemImage: "gearshape") {
                        isShowingSettings = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ny kontroll", systemImage: "plus", action: addInspection)
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }

    private func addInspection() {
        let inspection = Inspection()
        modelContext.insert(inspection)
    }

    private func deleteInspection(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(inspections[index])
        }
    }
}

private struct InspectionRow: View {
    let inspection: Inspection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(inspection.companyOwner.isEmpty ? "Ny kontroll" : inspection.companyOwner)
                .font(.headline)
            Text(inspection.location.isEmpty ? "Ingen lokasjon" : inspection.location)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(inspection.machines.count) maskiner", systemImage: "wrench.and.screwdriver")
                Spacer()
                Text(inspection.status.rawValue)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InspectionListView()
        .modelContainer(for: [Inspection.self, Machine.self, MachineChecklistItem.self], inMemory: true)
}
