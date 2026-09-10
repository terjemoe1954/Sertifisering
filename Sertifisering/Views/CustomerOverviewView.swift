import SwiftUI
import SwiftData

struct CustomerOverviewView: View {
    let inspections: [Inspection]

    private var customerEntries: [CustomerOverviewEntry] {
        CustomerOverviewEntry.makeEntries(from: inspections)
    }

    var body: some View {
        NavigationStack {
            List {
                if customerEntries.isEmpty {
                    ContentUnavailableView(
                        "Ingen kunder ennå",
                        systemImage: "person.3",
                        description: Text("Kunder vises her når kontroller har firma/eier fylt ut.")
                    )
                } else {
                    ForEach(customerEntries) { entry in
                        NavigationLink {
                            CustomerDetailView(entry: entry)
                        } label: {
                            CustomerOverviewRow(entry: entry)
                        }
                    }
                }
            }
            .navigationTitle("Kunder")
        }
    }
}

struct CustomerOverviewEntry: Identifiable {
    let name: String
    let inspections: [Inspection]

    var id: String { name }

    var machineSummaries: [CustomerMachineSummary] {
        CustomerMachineSummary.makeSummaries(from: inspections)
    }

    var machineCount: Int {
        machineSummaries.count
    }

    var readyForOfficeCount: Int {
        inspections.filter(\.isReadyForOfficeQueue).count
    }

    var billingQueueCount: Int {
        inspections.filter(\.isBillingQueue).count
    }

    var newestUpdate: Date? {
        inspections.map(\.updatedAt).max()
    }

    static func makeEntries(from inspections: [Inspection]) -> [CustomerOverviewEntry] {
        let groupedInspections = Dictionary(grouping: inspections) { inspection in
            normalizedCustomerName(for: inspection)
        }

        return groupedInspections
            .filter { key, _ in !key.isEmpty }
            .map { key, inspections in
                CustomerOverviewEntry(
                    name: key,
                    inspections: inspections.sorted { $0.updatedAt > $1.updatedAt }
                )
            }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private static func normalizedCustomerName(for inspection: Inspection) -> String {
        inspection.companyOwner.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct CustomerMachineSummary: Identifiable {
    let key: String
    let machine: Machine
    let inspections: [Inspection]

    var id: String { key }

    var title: String {
        if !machine.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return machine.name
        }

        if !machine.serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return machine.serialNumber
        }

        return "Uten navn"
    }

    var subtitle: String {
        [machine.machineType, machine.serialNumber]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " / ")
    }

    var latestInspection: Inspection? {
        inspections.max { $0.updatedAt < $1.updatedAt }
    }

    var latestStatusText: String {
        latestInspection?.workflowStatus.rawValue ?? "Ingen status"
    }

    static func makeSummaries(from inspections: [Inspection]) -> [CustomerMachineSummary] {
        var groupedMachines: [String: [(machine: Machine, inspection: Inspection)]] = [:]

        for inspection in inspections {
            for machine in inspection.machines ?? [] {
                groupedMachines[machineKey(for: machine), default: []].append((machine, inspection))
            }
        }

        return groupedMachines.map { key, values in
            let sortedValues = values.sorted { lhs, rhs in
                lhs.inspection.updatedAt > rhs.inspection.updatedAt
            }
            return CustomerMachineSummary(
                key: key,
                machine: sortedValues.first?.machine ?? values[0].machine,
                inspections: sortedValues.map(\.inspection)
            )
        }
        .sorted { lhs, rhs in
            lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private static func machineKey(for machine: Machine) -> String {
        let serialNumber = machine.serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if !serialNumber.isEmpty {
            return "serial:\(serialNumber.localizedLowercase)"
        }

        let name = machine.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            return "name:\(name.localizedLowercase)"
        }

        return "id:\(machine.id.uuidString)"
    }
}

private struct CustomerOverviewRow: View {
    let entry: CustomerOverviewEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.name)
                .font(.headline)

            HStack(spacing: 12) {
                Label("\(entry.inspections.count) kontroller", systemImage: "doc.text")
                Label("\(entry.machineCount) maskiner", systemImage: "wrench.and.screwdriver")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if entry.readyForOfficeCount > 0 || entry.billingQueueCount > 0 {
                HStack(spacing: 12) {
                    if entry.readyForOfficeCount > 0 {
                        Label("\(entry.readyForOfficeCount) klar", systemImage: "tray.full")
                    }

                    if entry.billingQueueCount > 0 {
                        Label("\(entry.billingQueueCount) ikke fakturert", systemImage: "doc.plaintext")
                    }
                }
                .font(.caption)
                .foregroundStyle(.orange)
            }

            if let newestUpdate = entry.newestUpdate {
                Text("Sist endret \(newestUpdate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CustomerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var createdInspection: Inspection?
    let entry: CustomerOverviewEntry

    var body: some View {
        List {
            Section("Maskiner") {
                if entry.machineSummaries.isEmpty {
                    Text("Ingen maskiner registrert")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.machineSummaries) { summary in
                        NavigationLink {
                            MachineDetailView(machine: summary.machine)
                        } label: {
                            CustomerMachineRow(summary: summary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Ny kontroll", systemImage: "plus") {
                                createInspection(from: summary)
                            }
                            .tint(.blue)
                        }
                    }
                }
            }

            Section("Kontroller") {
                ForEach(entry.inspections) { inspection in
                    NavigationLink {
                        InspectionDetailView(inspection: inspection)
                    } label: {
                        CustomerInspectionRow(inspection: inspection)
                    }
                }
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ny kontroll", systemImage: "plus") {
                    createInspection()
                }
            }
        }
        .navigationDestination(item: $createdInspection) { inspection in
            InspectionDetailView(inspection: inspection)
        }
    }

    private func createInspection(from summary: CustomerMachineSummary? = nil) {
        let sourceInspection = summary?.latestInspection ?? entry.inspections.first
        let inspection = Inspection(
            companyOwner: entry.name,
            contactPerson: sourceInspection?.contactPerson ?? "",
            phone: sourceInspection?.phone ?? "",
            address: sourceInspection?.address ?? "",
            inspector: sourceInspection?.inspector ?? "",
            location: sourceInspection?.location ?? "",
            status: .approved,
            workflowStatus: .draft
        )

        if let summary {
            inspection.machines = [summary.machine.copyForNewInspection()]
        }

        modelContext.insert(inspection)
        try? modelContext.save()
        createdInspection = inspection
    }
}

private struct CustomerMachineRow: View {
    let summary: CustomerMachineSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(summary.title)
                .font(.subheadline.weight(.medium))

            if !summary.subtitle.isEmpty {
                Text(summary.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("\(summary.inspections.count) kontroller", systemImage: "clock.arrow.circlepath")
                Spacer()
                Text(summary.latestStatusText)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct CustomerInspectionRow: View {
    let inspection: Inspection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(inspection.location.isEmpty ? "Ingen lokasjon" : inspection.location)
                .font(.subheadline.weight(.medium))

            HStack {
                Label("\((inspection.machines ?? []).count) maskiner", systemImage: "wrench.and.screwdriver")
                Spacer()
                Text(inspection.workflowStatus.rawValue)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !inspection.projectNumber.isEmpty || !inspection.certificateNumber.isEmpty {
                Text([inspection.projectNumber, inspection.certificateNumber].filter { !$0.isEmpty }.joined(separator: " / "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CustomerOverviewView(inspections: [])
}
