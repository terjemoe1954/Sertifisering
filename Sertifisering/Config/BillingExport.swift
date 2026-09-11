import Foundation

@MainActor
enum BillingCSVExporter {
    static func export(inspections: [Inspection], exportedAt: Date = .now) throws -> URL {
        let csv = makeCSV(inspections: inspections, exportedAt: exportedAt)
        let fileName = "fakturagrunnlag-\(fileTimestamp()).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try (utf8ByteOrderMark + csv).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func makeCSV(inspections: [Inspection], exportedAt: Date = .now) -> String {
        let rows = [headers] + inspections.map { row(for: $0, exportedAt: exportedAt) }

        return rows.map { row in
            row.map(escapedCSVValue).joined(separator: ";")
        }
        .joined(separator: csvLineSeparator)
    }

    private static let utf8ByteOrderMark = "\u{FEFF}"
    private static let csvLineSeparator = "\r\n"

    private static let headers = [
        "Kontroll-ID",
        "Eksportert",
        "Opprettet",
        "Sist endret",
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
        "Fakturastatus",
        "Fullført",
        "Behandlet",
        "Fakturert",
        "Antall vedlegg",
        "Antall maskiner",
        "Antall mangler",
        "Mangelpunkter",
        "Maskiner",
        "Merknader"
    ]

    private static func row(for inspection: Inspection, exportedAt: Date) -> [String] {
        [
            inspection.id.uuidString,
            formattedDate(exportedAt),
            formattedDate(inspection.createdAt),
            formattedDate(inspection.updatedAt),
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
            billingStatus(for: inspection),
            formattedDate(inspection.completedAt),
            formattedDate(inspection.processedAt),
            formattedDate(inspection.invoicedAt),
            inspection.attachmentsCount,
            String((inspection.machines ?? []).count),
            String(inspection.checklistRemarkCount),
            remarkSummary(for: inspection),
            machineSummary(for: inspection),
            inspection.overallNotes
        ]
    }

    private static func billingStatus(for inspection: Inspection) -> String {
        if inspection.isInvoicedQueue {
            return "Fakturert"
        }

        if inspection.isBillingQueue {
            return "Ikke fakturert"
        }

        return "Ikke klar"
    }

    private static func remarkSummary(for inspection: Inspection) -> String {
        (inspection.machines ?? [])
            .sorted { lhs, rhs in
                machineSortKey(lhs) < machineSortKey(rhs)
            }
            .flatMap { machine in
                (machine.checklistItems ?? [])
                    .filter { $0.result == .remark }
                    .sorted { lhs, rhs in
                        checklistSortKey(lhs) < checklistSortKey(rhs)
                    }
                    .map { item in
                        let machineTitle = machine.name.isEmpty ? "Maskin" : machine.name
                        let itemTitle = [item.code, item.title]
                            .filter { !$0.isEmpty }
                            .joined(separator: " ")
                        return [machineTitle, itemTitle]
                            .filter { !$0.isEmpty }
                            .joined(separator: ": ")
                    }
            }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
    }

    private static func machineSummary(for inspection: Inspection) -> String {
        (inspection.machines ?? [])
            .sorted { lhs, rhs in
                machineSortKey(lhs) < machineSortKey(rhs)
            }
            .map { machine in
                [machine.name, machine.machineType, machine.serialNumber]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
    }

    private static func machineSortKey(_ machine: Machine) -> String {
        [machine.name, machine.machineType, machine.serialNumber]
            .joined(separator: " ")
            .localizedLowercase
    }

    private static func checklistSortKey(_ item: MachineChecklistItem) -> String {
        String(format: "%04d-%04d-%@-%@", item.sectionOrder, item.itemOrder, item.code, item.title)
            .localizedLowercase
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
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: .now)
    }
}
