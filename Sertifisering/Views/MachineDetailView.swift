import SwiftUI

struct MachineDetailView: View {
    @Bindable var machine: Machine

    private var groupedItems: [(section: String, items: [MachineChecklistItem])] {
        Dictionary(grouping: machine.checklistItems, by: \.sectionTitle)
            .map { key, items in
                let sortedItems = items.sorted { lhs, rhs in
                    if lhs.itemOrder == rhs.itemOrder {
                        return lhs.code < rhs.code
                    }
                    return lhs.itemOrder < rhs.itemOrder
                }
                return (key, sortedItems)
            }
            .sorted { lhs, rhs in
                let leftOrder = lhs.1.first?.sectionOrder ?? 0
                let rightOrder = rhs.1.first?.sectionOrder ?? 0
                return leftOrder < rightOrder
            }
    }

    var body: some View {
        Form {
            Section("Maskindata") {
                TextField("Navn / intern benevnelse", text: $machine.name)
                Picker("Kategori", selection: $machine.category) {
                    ForEach(MachineCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                TextField("Maskintype", text: $machine.machineType)
                TextField("Serienummer", text: $machine.serialNumber)
                TextField("Produsent", text: $machine.manufacturer)
                TextField("Taljetype", text: $machine.hoistType)
                TextField("Kran nr", text: $machine.craneNumber)
                TextField("Talje nr", text: $machine.hoistNumber)
                TextField("Intern plassering", text: $machine.internalLocation)
                TextField("Timeteller", text: $machine.hourMeter)
                TextField("Lastangivelse", text: $machine.loadIndicator)
                TextField("Evt. sertifikatnr", text: $machine.certificateNumber)
                Toggle("Årlig tilstandskontroll", isOn: $machine.annualControl)
                Toggle("Full service", isOn: $machine.fullService)
            }

            Section("Sikkerhet / dokumentasjon") {
                Toggle("Løse gjenstander funnet", isOn: $machine.looseObjectsFound)
                Toggle("Løse gjenstander fjernet", isOn: $machine.looseObjectsRemoved)
                Toggle("Restlevetid dokumentert", isOn: $machine.remainingLifetimeDocumented)
                TextField("Restlevetid SWP / full-last timer", text: $machine.remainingLifetimeSWP)
                Toggle("Bruksattest er gyldig", isOn: $machine.usageCertificateValid)
            }

            ForEach(groupedItems, id: \.section) { section in
                Section(section.section) {
                    ForEach(section.items) { item in
                        ChecklistItemEditor(item: item)
                    }
                }
            }

            Section("Maskinmerknader") {
                TextField("Notater", text: $machine.notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
        }
        .navigationTitle(machine.name.isEmpty ? "Maskin" : machine.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ChecklistItemEditor: View {
    @Bindable var item: MachineChecklistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(item.code) \(item.title)")
                .font(.subheadline.weight(.medium))
            Picker("Resultat", selection: $item.result) {
                ForEach(ChecklistResult.allCases) { result in
                    Text(result.rawValue).tag(result)
                }
            }
            .pickerStyle(.segmented)

            TextField("Merknad", text: $item.note)
        }
        .padding(.vertical, 4)
    }
}
