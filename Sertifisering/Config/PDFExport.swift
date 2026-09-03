import Foundation
import PencilKit
import UIKit

enum InspectionPDFExporter {
    static func export(inspection: Inspection) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 24
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: makeFormat())

        let data = renderer.pdfData { context in
            drawCoverPage(in: context, inspection: inspection, pageRect: pageRect, margin: margin)

            for machine in inspection.machines {
                drawMachinePage(in: context, inspection: inspection, machine: machine, pageRect: pageRect, margin: margin)
            }
        }

        let sanitizedName = inspection.companyOwner
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
        let fallbackName = sanitizedName.isEmpty ? "kontroll" : sanitizedName
        let fileName = "sertifisering-\(fallbackName)-\(inspection.createdAt.timeIntervalSince1970).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func makeFormat() -> UIGraphicsPDFRendererFormat {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Sertifisering",
            kCGPDFContextAuthor as String: "Sertifisering App",
            kCGPDFContextTitle as String: "Sertifiseringsrapport"
        ]
        return format
    }

    private static func drawCoverPage(
        in context: UIGraphicsPDFRendererContext,
        inspection: Inspection,
        pageRect: CGRect,
        margin: CGFloat
    ) {
        context.beginPage()
        let titleAttributes = textStyle(size: 20, weight: .bold)
        let headingAttributes = textStyle(size: 12, weight: .bold)
        let bodyAttributes = textStyle(size: 11, weight: .regular)
        let smallAttributes = textStyle(size: 10, weight: .regular)

        let width = pageRect.width - margin * 2
        var y = margin

        drawOuterBox(CGRect(x: margin, y: y, width: width, height: 82))
        drawText("ML Maskin", in: CGRect(x: margin + 10, y: y + 8, width: 160, height: 22), attributes: titleAttributes)
        drawText("SV-122", in: CGRect(x: pageRect.width - 100, y: y + 10, width: 70, height: 20), attributes: titleAttributes)
        drawText("Sertifiseringsorgan: TI-Sertifisering AS", in: CGRect(x: margin + 10, y: y + 36, width: 260, height: 16), attributes: bodyAttributes)
        drawLabeledField(label: "Dato", value: formattedDate(inspection.createdAt), rect: CGRect(x: pageRect.width - 170, y: y + 34, width: 140, height: 20), labelWidth: 34, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawText("Vi sertifiserer og godkjenner maskiner og industri kjøretøy", in: CGRect(x: margin + 10, y: y + 58, width: width - 20, height: 16), attributes: smallAttributes)
        y += 96

        let ownerBlockHeight: CGFloat = 124
        drawOuterBox(CGRect(x: margin, y: y, width: width, height: ownerBlockHeight))
        drawLabeledField(label: "Firma / Eier", value: inspection.companyOwner, rect: CGRect(x: margin + 10, y: y + 10, width: width - 20, height: 22), labelWidth: 84, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Kontaktperson", value: inspection.contactPerson, rect: CGRect(x: margin + 10, y: y + 40, width: width * 0.55, height: 22), labelWidth: 84, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Telefon / Faks", value: inspection.phone, rect: CGRect(x: margin + width * 0.6, y: y + 40, width: width * 0.35 - 10, height: 22), labelWidth: 82, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Adresse", value: inspection.address, rect: CGRect(x: margin + 10, y: y + 70, width: width - 20, height: 42), labelWidth: 56, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        y += ownerBlockHeight + 12

        let metaBlockHeight: CGFloat = 162
        drawOuterBox(CGRect(x: margin, y: y, width: width, height: metaBlockHeight))
        let leftColumnWidth = width * 0.52
        drawLabeledField(label: "Prosjektnr", value: inspection.projectNumber, rect: CGRect(x: margin + 10, y: y + 10, width: leftColumnWidth - 20, height: 22), labelWidth: 64, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Sted", value: inspection.location, rect: CGRect(x: margin + 10, y: y + 40, width: leftColumnWidth - 20, height: 22), labelWidth: 64, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Kontrollør", value: inspection.inspector, rect: CGRect(x: margin + 10, y: y + 70, width: leftColumnWidth - 20, height: 22), labelWidth: 64, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Sertifikat", value: inspection.certificateNumber, rect: CGRect(x: margin + leftColumnWidth, y: y + 10, width: width - leftColumnWidth - 10, height: 22), labelWidth: 62, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Ant. maskiner", value: "\(inspection.machines.count)", rect: CGRect(x: margin + leftColumnWidth, y: y + 40, width: width - leftColumnWidth - 10, height: 22), labelWidth: 80, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Ant. vedlegg", value: inspection.attachmentsCount, rect: CGRect(x: margin + leftColumnWidth, y: y + 70, width: width - leftColumnWidth - 10, height: 22), labelWidth: 80, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawStatusRow(status: inspection.status, origin: CGPoint(x: margin + leftColumnWidth + 10, y: y + 104))
        y += metaBlockHeight + 12

        let notesHeight: CGFloat = 150
        drawOuterBox(CGRect(x: margin, y: y, width: width, height: notesHeight))
        drawText("Merknader / mangler", in: CGRect(x: margin + 10, y: y + 10, width: 200, height: 16), attributes: headingAttributes)
        drawMultilineText(inspection.overallNotes.isEmpty ? "-" : inspection.overallNotes, in: CGRect(x: margin + 10, y: y + 34, width: width - 20, height: notesHeight - 44), attributes: bodyAttributes)
        y += notesHeight + 12

        let signatureWidth = (width - 12) / 2
        drawSignatureArea(
            title: "Underskrift kontrollør",
            name: inspection.signatureInspectorName,
            drawing: inspection.inspectorSignatureDrawing,
            frame: CGRect(x: margin, y: y, width: signatureWidth, height: 110),
            bodyAttributes: bodyAttributes,
            headingAttributes: headingAttributes
        )
        drawSignatureArea(
            title: "Kundens signatur",
            name: inspection.signatureCustomerName,
            drawing: inspection.customerSignatureDrawing,
            frame: CGRect(x: margin + signatureWidth + 12, y: y, width: signatureWidth, height: 110),
            bodyAttributes: bodyAttributes,
            headingAttributes: headingAttributes
        )
    }

    private static func drawMachinePage(
        in context: UIGraphicsPDFRendererContext,
        inspection: Inspection,
        machine: Machine,
        pageRect: CGRect,
        margin: CGFloat
    ) {
        context.beginPage()
        let titleAttributes = textStyle(size: 16, weight: .bold)
        let headingAttributes = textStyle(size: 11, weight: .bold)
        let bodyAttributes = textStyle(size: 10, weight: .regular)

        var y = margin
        let width = pageRect.width - margin * 2

        drawOuterBox(CGRect(x: margin, y: y, width: width, height: 90))
        drawText("ML Maskin Kontroll & Serviceskjema - Kraner / Taljer / Løfteutstyr", in: CGRect(x: margin + 10, y: y + 8, width: width - 20, height: 20), attributes: titleAttributes)
        drawLabeledField(label: "Kunde", value: inspection.companyOwner, rect: CGRect(x: margin + 10, y: y + 34, width: width * 0.55, height: 18), labelWidth: 42, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Maskin", value: machine.name, rect: CGRect(x: margin + 10, y: y + 58, width: width * 0.55, height: 18), labelWidth: 42, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Sted", value: inspection.location, rect: CGRect(x: margin + width * 0.62, y: y + 34, width: width * 0.34, height: 18), labelWidth: 30, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Dato", value: formattedDate(inspection.createdAt), rect: CGRect(x: margin + width * 0.62, y: y + 58, width: width * 0.34, height: 18), labelWidth: 30, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        y += 102

        drawOuterBox(CGRect(x: margin, y: y, width: width, height: 208))
        drawCategoryRow(category: machine.category, annualControl: machine.annualControl, fullService: machine.fullService, origin: CGPoint(x: margin + 10, y: y + 10), width: width - 20)
        drawLabeledField(label: "Maskintype", value: machine.machineType, rect: CGRect(x: margin + 10, y: y + 86, width: width * 0.48, height: 18), labelWidth: 60, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Produsent", value: machine.manufacturer, rect: CGRect(x: margin + width * 0.52, y: y + 86, width: width * 0.44 - 10, height: 18), labelWidth: 60, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Serienr", value: machine.serialNumber, rect: CGRect(x: margin + 10, y: y + 112, width: width * 0.3, height: 18), labelWidth: 46, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Kran nr", value: machine.craneNumber, rect: CGRect(x: margin + width * 0.34, y: y + 112, width: width * 0.26, height: 18), labelWidth: 44, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Talje nr", value: machine.hoistNumber, rect: CGRect(x: margin + width * 0.62, y: y + 112, width: width * 0.32 - 10, height: 18), labelWidth: 44, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Taljetype", value: machine.hoistType, rect: CGRect(x: margin + 10, y: y + 138, width: width * 0.48, height: 18), labelWidth: 56, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Timeteller", value: machine.hourMeter, rect: CGRect(x: margin + width * 0.52, y: y + 138, width: width * 0.44 - 10, height: 18), labelWidth: 56, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Plassering", value: machine.internalLocation, rect: CGRect(x: margin + 10, y: y + 164, width: width * 0.48, height: 18), labelWidth: 56, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Lastangivelse", value: machine.loadIndicator, rect: CGRect(x: margin + width * 0.52, y: y + 164, width: width * 0.44 - 10, height: 18), labelWidth: 74, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "Evt. sert. nr", value: machine.certificateNumber, rect: CGRect(x: margin + 10, y: y + 190, width: width * 0.48, height: 18), labelWidth: 62, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        drawLabeledField(label: "SWP", value: machine.remainingLifetimeSWP, rect: CGRect(x: margin + width * 0.52, y: y + 190, width: width * 0.44 - 10, height: 18), labelWidth: 34, labelAttributes: headingAttributes, valueAttributes: bodyAttributes)
        y += 220

        drawSectionHeader("Kontrollpunkter", y: y, margin: margin, width: width)
        y += 24
        y = drawChecklistTable(
            in: context,
            machine: machine,
            startY: y,
            pageRect: pageRect,
            margin: margin,
            titleAttributes: headingAttributes,
            bodyAttributes: bodyAttributes
        )

        let safetyHeight: CGFloat = 88
        if y > pageRect.height - 200 {
            context.beginPage()
            y = margin
        }
        drawOuterBox(CGRect(x: margin, y: y, width: width, height: safetyHeight))
        drawText("Sikkerhet / dokumentasjon", in: CGRect(x: margin + 10, y: y + 10, width: 180, height: 16), attributes: headingAttributes)
        drawBooleanLine("11.1 Løse gjenstander funnet", value: machine.looseObjectsFound, origin: CGPoint(x: margin + 10, y: y + 32))
        drawBooleanLine("Fjernet", value: machine.looseObjectsRemoved, origin: CGPoint(x: margin + 250, y: y + 32))
        drawBooleanLine("12.1 Restlevetid dokumentert", value: machine.remainingLifetimeDocumented, origin: CGPoint(x: margin + 10, y: y + 54))
        drawBooleanLine("Bruksattest er gyldig", value: machine.usageCertificateValid, origin: CGPoint(x: margin + 250, y: y + 54))
        y += safetyHeight + 10

        if !machine.notes.isEmpty {
            if y > pageRect.height - 110 {
                context.beginPage()
                y = margin
            }
            drawOuterBox(CGRect(x: margin, y: y, width: width, height: 84))
            drawText("Maskinmerknader", in: CGRect(x: margin + 10, y: y + 10, width: 160, height: 16), attributes: headingAttributes)
            drawMultilineText(machine.notes, in: CGRect(x: margin + 10, y: y + 32, width: width - 20, height: 42), attributes: bodyAttributes)
        }
    }

    private static func drawSignatureArea(
        title: String,
        name: String,
        drawing: PKDrawing,
        frame: CGRect,
        bodyAttributes: [NSAttributedString.Key: Any],
        headingAttributes: [NSAttributedString.Key: Any]
    ) {
        drawOuterBox(frame)
        drawText(title, in: CGRect(x: frame.minX + 10, y: frame.minY + 10, width: frame.width - 20, height: 18), attributes: headingAttributes)
        let signatureRect = CGRect(x: frame.minX + 10, y: frame.minY + 30, width: frame.width - 20, height: 46)
        drawInnerBox(signatureRect)
        if !drawing.bounds.isEmpty {
            let image = drawing.image(from: drawing.bounds, scale: 2.0)
            image.draw(in: signatureRect.insetBy(dx: 8, dy: 8))
        }
        drawText(name.isEmpty ? "-" : name, in: CGRect(x: frame.minX + 10, y: frame.maxY - 26, width: frame.width - 20, height: 18), attributes: bodyAttributes)
    }

    private static func drawText(_ text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }

    private static func drawMultilineText(_ text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 2
        var mergedAttributes = attributes
        mergedAttributes[.paragraphStyle] = paragraph
        (text as NSString).draw(in: rect, withAttributes: mergedAttributes)
    }

    private static func drawOuterBox(_ rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        UIColor.label.setStroke()
        path.lineWidth = 1.2
        path.stroke()
    }

    private static func drawInnerBox(_ rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        UIColor.secondaryLabel.setStroke()
        path.lineWidth = 0.8
        path.stroke()
    }

    private static func drawLabeledField(
        label: String,
        value: String,
        rect: CGRect,
        labelWidth: CGFloat,
        labelAttributes: [NSAttributedString.Key: Any],
        valueAttributes: [NSAttributedString.Key: Any]
    ) {
        drawText(label, in: CGRect(x: rect.minX, y: rect.minY, width: labelWidth, height: rect.height), attributes: labelAttributes)
        let valueRect = CGRect(x: rect.minX + labelWidth + 4, y: rect.minY - 2, width: rect.width - labelWidth - 4, height: rect.height + 4)
        drawInnerBox(valueRect)
        drawText(value.isEmpty ? "-" : value, in: valueRect.insetBy(dx: 6, dy: 3), attributes: valueAttributes)
    }

    private static func drawStatusRow(status: InspectionStatus, origin: CGPoint) {
        let statuses: [InspectionStatus] = [.approved, .approvedWithRemarks, .rejected]
        for (index, item) in statuses.enumerated() {
            let rect = CGRect(x: origin.x, y: origin.y + CGFloat(index) * 18, width: 14, height: 14)
            drawInnerBox(rect)
            if item == status {
                let checkmark = UIBezierPath()
                checkmark.move(to: CGPoint(x: rect.minX + 2, y: rect.midY))
                checkmark.addLine(to: CGPoint(x: rect.minX + 6, y: rect.maxY - 3))
                checkmark.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.minY + 3))
                UIColor.label.setStroke()
                checkmark.lineWidth = 1.5
                checkmark.stroke()
            }
            drawText(item.rawValue, in: CGRect(x: rect.maxX + 6, y: rect.minY - 1, width: 150, height: 16), attributes: textStyle(size: 10, weight: .regular))
        }
    }

    private static func drawSectionHeader(_ title: String, y: CGFloat, margin: CGFloat, width: CGFloat) {
        let rect = CGRect(x: margin, y: y, width: width, height: 20)
        UIColor.systemGray6.setFill()
        UIBezierPath(rect: rect).fill()
        drawText(title, in: rect.insetBy(dx: 8, dy: 2), attributes: textStyle(size: 11, weight: .bold))
    }

    @discardableResult
    private static func drawChecklistTable(
        in context: UIGraphicsPDFRendererContext,
        machine: Machine,
        startY: CGFloat,
        pageRect: CGRect,
        margin: CGFloat,
        titleAttributes: [NSAttributedString.Key: Any],
        bodyAttributes: [NSAttributedString.Key: Any]
    ) -> CGFloat {
        var y = startY
        let width = pageRect.width - margin * 2
        let groupedItems = Dictionary(grouping: machine.checklistItems, by: \.sectionTitle)
            .map { key, items in
                let sortedItems = items.sorted { lhs, rhs in
                    if lhs.itemOrder == rhs.itemOrder {
                        return lhs.code < rhs.code
                    }
                    return lhs.itemOrder < rhs.itemOrder
                }
                return (key, sortedItems)
            }
            .sorted {
                let left = $0.1.first?.sectionOrder ?? 0
                let right = $1.1.first?.sectionOrder ?? 0
                return left < right
            }

        for group in groupedItems {
            if y > pageRect.height - 120 {
                context.beginPage()
                y = margin
            }

            drawSectionHeader(group.0, y: y, margin: margin, width: width)
            y += 22
            drawChecklistTableHeader(y: y, margin: margin, width: width)
            y += 20

            for item in group.1 {
                if y > pageRect.height - 70 {
                    context.beginPage()
                    y = margin
                    drawSectionHeader(group.0, y: y, margin: margin, width: width)
                    y += 22
                    drawChecklistTableHeader(y: y, margin: margin, width: width)
                    y += 20
                }

                let rowRect = CGRect(x: margin, y: y, width: width, height: 26)
                drawInnerBox(rowRect)
                drawText(item.code, in: CGRect(x: margin + 6, y: y + 6, width: 32, height: 14), attributes: bodyAttributes)
                drawText(item.title, in: CGRect(x: margin + 42, y: y + 4, width: 250, height: 18), attributes: bodyAttributes)
                drawChecklistMark(for: item.result, expected: .ok, rect: CGRect(x: margin + 300, y: y + 5, width: 14, height: 14))
                drawChecklistMark(for: item.result, expected: .remark, rect: CGRect(x: margin + 340, y: y + 5, width: 14, height: 14))
                drawChecklistMark(for: item.result, expected: .notApplicable, rect: CGRect(x: margin + 380, y: y + 5, width: 14, height: 14))
                drawText(item.note.isEmpty ? "-" : item.note, in: CGRect(x: margin + 410, y: y + 4, width: width - 420, height: 18), attributes: bodyAttributes)
                y += 28
            }

            y += 8
        }

        return y
    }

    private static func drawChecklistTableHeader(y: CGFloat, margin: CGFloat, width: CGFloat) {
        let headerRect = CGRect(x: margin, y: y, width: width, height: 18)
        UIColor.systemGray6.setFill()
        UIBezierPath(rect: headerRect).fill()
        drawText("Pkt", in: CGRect(x: margin + 6, y: y + 2, width: 28, height: 14), attributes: textStyle(size: 10, weight: .bold))
        drawText("Beskrivelse", in: CGRect(x: margin + 42, y: y + 2, width: 120, height: 14), attributes: textStyle(size: 10, weight: .bold))
        drawText("OK", in: CGRect(x: margin + 296, y: y + 2, width: 24, height: 14), attributes: textStyle(size: 10, weight: .bold))
        drawText("M", in: CGRect(x: margin + 338, y: y + 2, width: 20, height: 14), attributes: textStyle(size: 10, weight: .bold))
        drawText("IR", in: CGRect(x: margin + 376, y: y + 2, width: 20, height: 14), attributes: textStyle(size: 10, weight: .bold))
        drawText("Merknad", in: CGRect(x: margin + 410, y: y + 2, width: width - 420, height: 14), attributes: textStyle(size: 10, weight: .bold))
    }

    private static func drawChecklistMark(for actual: ChecklistResult, expected: ChecklistResult, rect: CGRect) {
        drawInnerBox(rect)
        if actual == expected {
            let checkmark = UIBezierPath()
            checkmark.move(to: CGPoint(x: rect.minX + 2, y: rect.midY))
            checkmark.addLine(to: CGPoint(x: rect.minX + 5, y: rect.maxY - 3))
            checkmark.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.minY + 3))
            UIColor.label.setStroke()
            checkmark.lineWidth = 1.2
            checkmark.stroke()
        }
    }

    private static func drawCategoryRow(category: MachineCategory, annualControl: Bool, fullService: Bool, origin: CGPoint, width: CGFloat) {
        drawText("Gjelder kontroll / service av:", in: CGRect(x: origin.x, y: origin.y, width: 180, height: 16), attributes: textStyle(size: 10, weight: .bold))
        let leftOptions = [MachineCategory.crane, .hoist, .monorail]
        let rightOptions = [MachineCategory.jibCrane, .chainHoist, .other]

        for (index, item) in leftOptions.enumerated() {
            drawSelectableLine(title: item.rawValue, selected: category == item, origin: CGPoint(x: origin.x, y: origin.y + 20 + CGFloat(index) * 18))
        }
        for (index, item) in rightOptions.enumerated() {
            drawSelectableLine(title: item.rawValue, selected: category == item, origin: CGPoint(x: origin.x + width * 0.42, y: origin.y + 20 + CGFloat(index) * 18))
        }

        drawSelectableLine(title: "Årlig Tilstandskontroll", selected: annualControl, origin: CGPoint(x: origin.x + width * 0.7, y: origin.y + 20))
        drawSelectableLine(title: "Full Service (FS)", selected: fullService, origin: CGPoint(x: origin.x + width * 0.7, y: origin.y + 40))
    }

    private static func drawSelectableLine(title: String, selected: Bool, origin: CGPoint) {
        let rect = CGRect(x: origin.x, y: origin.y, width: 12, height: 12)
        drawInnerBox(rect)
        if selected {
            let checkmark = UIBezierPath()
            checkmark.move(to: CGPoint(x: rect.minX + 2, y: rect.midY))
            checkmark.addLine(to: CGPoint(x: rect.minX + 5, y: rect.maxY - 2))
            checkmark.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.minY + 2))
            UIColor.label.setStroke()
            checkmark.lineWidth = 1.2
            checkmark.stroke()
        }
        drawText(title, in: CGRect(x: rect.maxX + 6, y: origin.y - 2, width: 150, height: 14), attributes: textStyle(size: 9, weight: .regular))
    }

    private static func drawBooleanLine(_ title: String, value: Bool, origin: CGPoint) {
        drawSelectableLine(title: title, selected: value, origin: origin)
    }

    private static func textStyle(size: CGFloat, weight: UIFont.Weight) -> [NSAttributedString.Key: Any] {
        [.font: UIFont.systemFont(ofSize: size, weight: weight)]
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: date)
    }
}
