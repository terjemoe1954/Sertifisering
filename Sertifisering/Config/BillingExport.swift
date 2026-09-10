import Foundation

@MainActor
enum BillingCSVExporter {
    static func export(inspections: [Inspection]) throws -> URL {
        let csv = makeCSV(inspections: inspections)
        let fileName = "fakturagrunnlag-\(fileTimestamp()).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func makeCSV(inspections: [Inspection]) -> String {
        let rows = [headers] + inspections.map(row(for:))

        return rows.map { row in
            row.map(escapedCSVValue).joined(separator: ";")
        }
        .joined(separator: "\n")
    }

    private static let headers = [
        "Kunde",
        "Kontaktperson",
        "Telefon",
        "Adresse",
        "Sted",
        "Prosjektnummer",
        "Sertifikatnummer",
        "Kontrollør",
        "Kontrollstatus",
        "Arbeidsstatus",
        "Fullført",
        "Behandlet",
        "Antall maskiner",
        "Antall mangler",
        "Maskiner"
    ]

    private static func row(for inspection: Inspection) -> [String] {
        [
            inspection.companyOwner,
            inspection.contactPerson,
            inspection.phone,
            inspection.address,
            inspection.location,
            inspection.projectNumber,
            inspection.certificateNumber,
            inspection.inspector,
            inspection.status.rawValue,
            inspection.workflowStatus.rawValue,
            formattedDate(inspection.completedAt),
            formattedDate(inspection.processedAt),
            String((inspection.machines ?? []).count),
            String(inspection.checklistRemarkCount),
            machineSummary(for: inspection)
        ]
    }

    private static func machineSummary(for inspection: Inspection) -> String {
        (inspection.machines ?? []).map { machine in
            [machine.name, machine.machineType, machine.serialNumber]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
        .filter { !$0.isEmpty }
        .joined(separator: " | ")
    }

    private static func escapedCSVValue(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static func formattedDate(_ date: Date?) -> String {
        guard let date else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: date)
    }

    private static func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter.string(from: .now)
    }
}
