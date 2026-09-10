import Foundation

@MainActor
enum CertificateBasisExporter {
    static func export(inspection: Inspection) throws -> URL {
        let text = makeText(inspection: inspection)
        let fileName = "sertifikatgrunnlag-\(safeFileName(from: inspection.companyOwner))-\(fileTimestamp()).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func makeText(inspection: Inspection) -> String {
        var lines: [String] = [
            "Sertifikatgrunnlag",
            "",
            "Kunde: \(valueOrDash(inspection.companyOwner))",
            "Kontaktperson: \(valueOrDash(inspection.contactPerson))",
            "Telefon: \(valueOrDash(inspection.phone))",
            "Adresse: \(valueOrDash(inspection.address))",
            "Sted: \(valueOrDash(inspection.location))",
            "Prosjektnummer: \(valueOrDash(inspection.projectNumber))",
            "Sertifikatnummer: \(valueOrDash(inspection.certificateNumber))",
            "Kontrollør: \(valueOrDash(inspection.inspector))",
            "Kontrollstatus: \(inspection.status.rawValue)",
            "Arbeidsstatus: \(inspection.workflowStatus.rawValue)",
            "Fullført: \(formattedDate(inspection.completedAt))",
            "Behandlet: \(formattedDate(inspection.processedAt))",
            "Antall maskiner: \((inspection.machines ?? []).count)",
            "Antall mangler: \(inspection.checklistRemarkCount)",
            "",
            "Maskiner"
        ]

        let machines = inspection.machines ?? []
        if machines.isEmpty {
            lines.append("- Ingen maskiner registrert")
        } else {
            for machine in machines {
                lines.append("- \(machineTitle(machine))")
                appendMachineLine("  Type", value: machine.machineType, to: &lines)
                appendMachineLine("  Serienummer", value: machine.serialNumber, to: &lines)
                appendMachineLine("  Produsent", value: machine.manufacturer, to: &lines)
                appendMachineLine("  Kran nr", value: machine.craneNumber, to: &lines)
                appendMachineLine("  Talje nr", value: machine.hoistNumber, to: &lines)
                appendMachineLine("  Plassering", value: machine.internalLocation, to: &lines)
                appendMachineLine("  Lastangivelse", value: machine.loadIndicator, to: &lines)
                appendMachineLine("  Evt. sertifikatnr", value: machine.certificateNumber, to: &lines)
                appendMachineLine("  SWP", value: machine.remainingLifetimeSWP, to: &lines)

                let remarks = (machine.checklistItems ?? []).filter { $0.result == .remark }
                if !remarks.isEmpty {
                    lines.append("  Mangler:")
                    for item in remarks {
                        let note = item.note.trimmingCharacters(in: .whitespacesAndNewlines)
                        let suffix = note.isEmpty ? "" : " - \(note)"
                        lines.append("  - \(item.code) \(item.title)\(suffix)")
                    }
                }
            }
        }

        lines.append("")
        lines.append("Merknader: \(valueOrDash(inspection.overallNotes))")
        lines.append("Kundens signatur: \(valueOrDash(inspection.signatureCustomerName))")
        lines.append("Kontrollør signatur: \(valueOrDash(inspection.signatureInspectorName))")

        return lines.joined(separator: "\n")
    }

    private static func appendMachineLine(_ label: String, value: String, to lines: inout [String]) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return
        }
        lines.append("\(label): \(trimmedValue)")
    }

    private static func machineTitle(_ machine: Machine) -> String {
        let values = [machine.name, machine.serialNumber]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return values.isEmpty ? "Uten navn" : values.joined(separator: " / ")
    }

    private static func valueOrDash(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "-" : trimmedValue
    }

    private static func formattedDate(_ date: Date?) -> String {
        guard let date else {
            return "-"
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

    private static func safeFileName(from value: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .map { allowedCharacters.contains($0) ? Character($0) : "-" }

        let fileName = String(normalized).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return fileName.isEmpty ? "kontroll" : fileName
    }
}
