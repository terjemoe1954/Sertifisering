import SwiftUI

struct HelpGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let quickStartItems = [
        GuideChecklistItem(text: "Velg rolle i Innstillinger: Tekniker, Kontor eller Admin."),
        GuideChecklistItem(text: "Opprett eller finn kunde og maskin før kontrollen starter."),
        GuideChecklistItem(text: "Fyll ut forside, maskindata, sjekkliste og signatur."),
        GuideChecklistItem(text: "Marker kontrollen ferdig fra tekniker når Teknikersjekk er grønn."),
        GuideChecklistItem(text: "Kontoret henter, behandler, lager dokumentasjon og fakturagrunnlag.")
    ]

    private let technicianSteps = [
        GuideStep(title: "Start kontroll", detail: "Trykk Ny kontroll, eller åpne Kunder og start fra en eksisterende maskin for å kopiere faste maskindata."),
        GuideStep(title: "Fyll ut forside", detail: "Legg inn firma/eier, kontaktperson, sted, prosjekt, kontrollør og kontrollresultat."),
        GuideStep(title: "Registrer maskiner", detail: "Legg til maskin, fyll ut serienummer, type, krannummer, intern plassering og andre relevante felt."),
        GuideStep(title: "Gå gjennom sjekklisten", detail: "Sett hvert punkt til OK, Mangel eller Ikke relevant. Legg inn merknad på punkter som trenger forklaring."),
        GuideStep(title: "Signer og fullfør", detail: "Fyll inn navn, signer og trykk Marker ferdig fra tekniker. Appen viser hva som mangler hvis kontrollen ikke kan fullføres.")
    ]

    private let officeSteps = [
        GuideStep(title: "Hent ferdige kontroller", detail: "Sett rollen til Kontor og hent delte firmadata fra iCloud-menyen eller dra ned i hovedlisten."),
        GuideStep(title: "Bruk køene", detail: "Klar for behandling viser teknikerferdige kontroller. Ikke fakturert viser kontroller som er behandlet av kontor."),
        GuideStep(title: "Kontroller grunnlag", detail: "Åpne kontrollen og sjekk kunde, maskin, status, signatur, merknader og eventuelle mangler."),
        GuideStep(title: "Lag dokumentasjon", detail: "Generer PDF for rapport. Legg inn sertifikatnummer og lag sertifikatgrunnlag når kontorgrunnlaget er komplett."),
        GuideStep(title: "Fakturer og synk", detail: "Lag fakturagrunnlag, marker fakturert når faktura er sendt eller registrert, og synk firmadata etterpå.")
    ]

    private let cloudSteps = [
        GuideStep(title: "På teknikerens enhet", detail: "Slå på iCloud/CloudKit i Innstillinger, synk firmadata til deling og del firmadata med kontor."),
        GuideStep(title: "På kontorets enhet", detail: "Åpne delingslenken, aksepter tilgang, sett rollen til Kontor og hent delte firmadata."),
        GuideStep(title: "Ved konflikter", detail: "Hvis samme kontroll finnes lokalt og i iCloud, beholder appen den nyeste versjonen basert på sist endret-tidspunkt.")
    ]

    private let pilotItems = [
        GuideChecklistItem(text: "Lag én realistisk kontroll med kunde, maskin, sjekkpunkter, minst én mangel og signatur."),
        GuideChecklistItem(text: "Generer PDF på tekniker-enheten og kontroller innholdet."),
        GuideChecklistItem(text: "Synk til iCloud og hent kontrollen på kontor-enheten."),
        GuideChecklistItem(text: "Legg inn sertifikatnummer, lag sertifikatgrunnlag og marker behandlet av kontor."),
        GuideChecklistItem(text: "Lag fakturagrunnlag, marker fakturert og sjekk at status synker tilbake."),
        GuideChecklistItem(text: "Test også én kontroll uten nett, og synk når nett er tilbake.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header

                    GuideSection(title: "Kom raskt i gang", systemImage: "checklist") {
                        GuideChecklist(items: quickStartItems)
                    }

                    RoleCards()

                    GuideSection(title: "Tekniker: gjennomfør kontroll", systemImage: "wrench.and.screwdriver") {
                        GuideStepList(steps: technicianSteps)
                    }

                    GuideSection(title: "Kontor: behandle og fakturer", systemImage: "tray.full") {
                        GuideStepList(steps: officeSteps)
                    }

                    GuideSection(title: "Kunder og maskinhistorikk", systemImage: "person.3") {
                        GuideParagraph("Trykk Kunder i hovedlisten for å se kontroller samlet per firma/eier. Åpne en kunde for å se maskiner og tidligere kontroller.")
                        GuideParagraph("Maskinhistorikk samles på serienummer når det finnes, ellers på maskinnavn. Sveip på en maskin og velg Ny kontroll for å starte med kopierte maskindata og ny sjekkliste.")
                    }

                    GuideSection(title: "PDF, sertifikat og fakturagrunnlag", systemImage: "doc.text") {
                        GuideInfoGrid(items: [
                            GuideInfoItem(title: "PDF", detail: "Krever minst én maskin og brukes som rapportgrunnlag."),
                            GuideInfoItem(title: "Sertifikatgrunnlag", detail: "Krever sertifikatnummer og minst én maskin."),
                            GuideInfoItem(title: "Faktura-CSV", detail: "Inneholder sporingsfelt, eksportdato, statuser, mangler, maskiner og merknader."),
                            GuideInfoItem(title: "Mangelpunkter", detail: "CSV-en viser konkrete sjekkpunkt som er markert med Mangel.")
                        ])
                    }

                    GuideSection(title: "iCloud og delt tilgang", systemImage: "icloud") {
                        GuideStepList(steps: cloudSteps)
                    }

                    GuideSection(title: "Backup og restore", systemImage: "externaldrive") {
                        GuideParagraph("Lag backup fra Innstillinger før større endringer eller pilotbruk. Backup lagres lokalt under appens Application Support-mappe.")
                        GuideParagraph("Restore planlegges i Innstillinger og fullføres ved neste oppstart av appen. Kontroller at riktig backup er valgt før appen lukkes.")
                    }

                    GuideSection(title: "Pilot-test før fast bruk", systemImage: "testtube.2") {
                        GuideChecklist(items: pilotItems)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Brukerveiledning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lukk") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sertifisering", systemImage: "checkmark.seal.fill")
                .font(.title2.bold())
                .foregroundStyle(.blue)

            Text("Brukerveiledningen følger arbeidsflyten fra tekniker ute hos kunde til kontorbehandling, dokumentasjon og fakturering.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct GuideSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct RoleCards: View {
    var body: some View {
        GuideSection(title: "Roller", systemImage: "person.crop.circle.badge.checkmark") {
            GuideInfoGrid(items: [
                GuideInfoItem(title: "Tekniker", detail: "Oppretter kontroller, registrerer maskiner, fyller sjekkliste og signerer ute hos kunde."),
                GuideInfoItem(title: "Kontor", detail: "Henter ferdige kontroller, lager PDF og sertifikatgrunnlag, behandler og fakturerer."),
                GuideInfoItem(title: "Admin", detail: "Kan utføre både tekniker- og kontoroppgaver når én bruker må gjøre alt.")
            ])
        }
    }
}

private struct GuideStepList: View {
    let steps: [GuideStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.blue))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.subheadline.bold())
                        Text(step.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct GuideChecklist: View {
    let items: [GuideChecklistItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                Label(item.text, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
}

private struct GuideInfoGrid: View {
    let items: [GuideInfoItem]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.subheadline.bold())
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct GuideParagraph: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GuideStep {
    let title: String
    let detail: String
}

private struct GuideChecklistItem: Identifiable {
    let id = UUID()
    let text: String
}

private struct GuideInfoItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}
