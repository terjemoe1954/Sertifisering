import SwiftUI

private let helpGuideMarkdown = """
# Brukerveiledning

## Velg rolle
Åpne `Innstillinger` og velg `Tekniker`, `Kontor` eller `Admin`.

`Tekniker` brukes ute hos kunde. `Kontor` brukes til behandling, PDF, sertifikatgrunnlag og fakturering. `Admin` kan gjøre begge deler.

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

## Ferdigstilling hos tekniker
Når kontrollen er klar, trykk `Marker ferdig fra tekniker`.

Hvis iCloud er aktivert, forsøker appen å synke endringen automatisk. Du kan også bruke iCloud-menyen i hovedlisten og trykke `Synk firmadata til deling`.

## iCloud og delt tilgang
Før deling må `Bruk iCloud/CloudKit` være slått på i `Innstillinger`.

På teknikerens enhet:

1. Trykk `Synk firmadata til deling`.
2. Trykk `Del firmadata med kontor`.
3. Send delingslenke til Apple ID-en som kontorbrukeren bruker.

På kontorbrukerens enhet:

1. Åpne delingslenken og aksepter tilgang.
2. Sett rollen til `Kontor`.
3. Hent data fra iCloud-menyen eller dra ned i hovedlisten.

## Kontorbehandling
Som kontorbruker åpner appen normalt køen `Klar for kontor`.

Åpne en kontroll og bruk:

- `Marker behandlet av kontor`
- `Marker fakturert`
- `Generer PDF`

Når status endres forsøker appen å synke automatisk til iCloud. Du kan også trykke `Synk endringer til iCloud` inne på kontrollen.

I hovedlisten viser `Ikke fakturert` kontroller som er behandlet av kontor, men ikke markert som fakturert. `Fakturert` viser ferdig fakturerte kontroller.

## Daglig kontorrutine
Bruk denne rekkefølgen når appen tas i bruk på kontoret:

1. Åpne appen med rollen `Kontor`.
2. Hent delte firmadata eller dra ned i hovedlisten.
3. Start i køen `Klar for behandling`.
4. Åpne hver kontroll og sjekk kunde, maskin, status, merknader og signatur.
5. Generer PDF hvis rapporten skal arkiveres eller sendes videre.
6. Legg inn eller kontroller sertifikatnummer før saken behandles ferdig.
7. Trykk `Marker behandlet av kontor` når dokumentasjonen er kontrollert.
8. Gå til `Ikke fakturert` og lag fakturagrunnlag.
9. Når faktura er sendt eller registrert i regnskapssystemet, trykk `Marker fakturert`.
10. Synk firmadata etter endt kontorøkt.

Anbefalt ansvarsdeling er at tekniker eier registrering og signatur ute hos kunde, mens kontoret eier sertifikatnummer, PDF-arkivering, fakturagrunnlag og fakturert-status.

## Konflikter ved henting
Hvis samme kontroll finnes lokalt og i iCloud, beholder appen den nyeste versjonen basert på sist endret-tidspunkt.

## Pilot-test før fast bruk
Bruk denne sjekklisten med én iPad som tekniker og én simulator eller enhet som kontorbruker:

1. Sett iPad til rollen `Tekniker`.
2. Opprett én kontroll med realistisk kunde, kontaktperson, sted, prosjekt og kontrollør.
3. Legg inn minst én maskin med serienummer, krannummer eller intern plassering.
4. Fyll ut flere kontrollpunkter, inkludert minst én `Mangel` med merknad.
5. Legg inn navn og signaturer.
6. Generer PDF og kontroller at arket ser riktig ut.
7. Marker kontrollen som ferdig fra tekniker.
8. Synk firmadata til iCloud.
9. Sett kontorenheten til rollen `Kontor`.
10. Hent delte firmadata og åpne kontrollen.
11. Generer PDF på kontorenheten og sammenlign med teknikerens PDF.
12. Marker kontrollen som behandlet av kontor.
13. Lag fakturagrunnlag fra hovedlisten.
14. Marker kontrollen som fakturert.
15. Synk på begge enheter og kontroller at statusene er like.

Test også én kontroll uten nett. Gjør kontrollen ferdig lokalt, slå på nett igjen og synk etterpå.

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
