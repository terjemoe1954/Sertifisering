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
    @State private var selectedFilter: InspectionListFilter = .all

    private var filteredInspections: [Inspection] {
        inspections.filter { inspection in
            selectedFilter.includes(inspection)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if inspections.isEmpty {
                    ContentUnavailableView(
                        "Ingen kontroller ennå",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Opprett første kontroll og registrer maskiner direkte hos kunde.")
                    )
                } else if filteredInspections.isEmpty {
                    ContentUnavailableView(
                        "Ingen kontroller i dette filteret",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Velg et annet filter for å se flere kontroller.")
                    )
                } else {
                    ForEach(filteredInspections) { inspection in
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
                    Menu {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(InspectionListFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    } label: {
                        Label(selectedFilter.rawValue, systemImage: "line.3.horizontal.decrease.circle")
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
            modelContext.delete(filteredInspections[index])
        }
    }
}

private enum InspectionListFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case draft = "Utkast"
    case readyForOffice = "Klar for kontor"
    case processedByOffice = "Behandlet"
    case invoiced = "Fakturert"

    var id: String { rawValue }

    func includes(_ inspection: Inspection) -> Bool {
        switch self {
        case .all:
            true
        case .draft:
            inspection.workflowStatus == .draft
        case .readyForOffice:
            inspection.workflowStatus == .completedByTechnician || inspection.workflowStatus == .readyForOffice
        case .processedByOffice:
            inspection.workflowStatus == .processedByOffice
        case .invoiced:
            inspection.workflowStatus == .invoiced
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
            HStack(alignment: .bottom) {
                Label("\(inspection.machines.count) maskiner", systemImage: "wrench.and.screwdriver")
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(inspection.workflowStatus.rawValue)
                    Text(inspection.status.rawValue)
                }
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
