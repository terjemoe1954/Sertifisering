import SwiftUI

private let helpGuideMarkdown = """
# Brukerveiledning

## Opprett kontroll
Trykk `Ny kontroll` fra hovedskjermen for å starte en ny registrering.

## Fyll ut forside
Legg inn kunde, kontaktperson, sted, kontrollør og status før rapporten deles.

## Legg til maskiner
Åpne kontrollen og trykk `Legg til maskin`. Hver maskin får egen sjekkliste.

## Registrer kontrollpunkter
Velg `OK`, `Mangel` eller `Ikke relevant` for hvert punkt. Legg inn merknad ved behov.

## Signatur og PDF
Fyll inn navn, signer i signaturfeltet og trykk `Generer PDF` for å dele rapporten.

## Backup og restore
Bruk `Innstillinger` for å lage backup. Restore planlegges der og fullføres ved neste oppstart av appen.
"""

struct HelpGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(attributedGuide)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
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

    private var attributedGuide: AttributedString {
        (try? AttributedString(markdown: helpGuideMarkdown)) ?? AttributedString(helpGuideMarkdown)
    }
}
