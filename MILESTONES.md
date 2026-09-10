# Milepæler mot kontorbruk

Dette dokumentet beskriver en praktisk vei fra dagens Sertifisering-app til en løsning der tekniker kan utføre kontroller ute hos kunde, og kontorbruker kan hente inn data for sertifikater, fakturering og oppfølging.

Planen er en viderebygging av dagens app. Den tar utgangspunkt i filene som allerede finnes i prosjektet, og foreslår hvor nye felter, visninger og arbeidsflyt bør legges inn.

## Dagens utgangspunkt

Eksisterende filer som bør bygges videre på:

- `Sertifisering/Models/InspectionModels.swift`: hovedsted for kunde-, maskin-, inspeksjons- og sjekklistedata.
- `Sertifisering/Config/PersistenceController.swift`: lokal lagring og senere overgang til iCloud/CloudKit-synk.
- `Sertifisering/Config/PDFExport.swift`: PDF-rapport, sertifikatgrunnlag og dokumentasjon.
- `Sertifisering/Views/InspectionListView.swift`: liste over inspeksjoner, filtrering og senere kontoroversikt.
- `Sertifisering/Views/InspectionDetailView.swift`: gjennomføring og fullføring av inspeksjon.
- `Sertifisering/Views/MachineDetailView.swift`: maskinhistorikk og startpunkt for ny inspeksjon.
- `Sertifisering/Views/SettingsView.swift`: rollevalg, iCloud-status og firma-/brukerinnstillinger.
- `Sertifisering/Views/SignatureEditor.swift`: signaturflyt før rapport og sertifikat.
- `Sertifisering/Views/HelpGuideView.swift`: enkel bruksanvisning for tekniker og kontorbruker.
- `Sertifisering/SertifiseringApp.swift`: oppsett av appens miljø, lagring og globale avhengigheter.

## Målbilde

Appen skal støtte en enkel arbeidsflyt:

1. Tekniker oppretter eller velger kunde og maskin.
2. Tekniker gjennomfører inspeksjon ute hos kunde.
3. Inspeksjonen lagres lokalt og kan fullføres uten nett.
4. Ferdig inspeksjon synkroniseres til sky.
5. Kontorbruker ser ferdige inspeksjoner.
6. Kontorbruker lager sertifikat, fakturagrunnlag og markerer saken som behandlet.

## Milepæl 1: Rydde og stabilisere dagens datamodell

**Formål:** Gjøre modellen trygg nok til videre utvikling før synk og kontorfunksjoner bygges på.

Bygges videre på:

- `InspectionModels.swift`
- spesielt eksisterende modell rundt `MachineChecklistItem`

Leveranser:

- Gå gjennom eksisterende modeller i `InspectionModels.swift`.
- Skille tydelig mellom kunde, maskin, inspeksjon og sjekklistepunkter.
- Legge inn stabile ID-er på sentrale objekter.
- Legge inn datoer for opprettet, endret og fullført.
- Sørge for at inspeksjoner kan lagres som utkast.
- Sikre at `MachineChecklistItem` har nok struktur til senere rapportering og sertifikat.
- Legge inn status på inspeksjon, slik at tekniker- og kontorarbeid kan skilles.

Forslag til statuser:

```swift
enum InspectionStatus: String, Codable, CaseIterable {
    case draft
    case completedByTechnician
    case readyForOffice
    case processedByOffice
    case invoiced
}
```

Ferdig når:

- En inspeksjon kan være under arbeid, fullført og senere behandlet av kontoret.
- Modellene er klare for lokal lagring og senere sky-synk.

## Milepæl 2: Lokal lagring som tåler reell bruk

**Formål:** Tekniker skal kunne bruke appen ute hos kunde uten å være avhengig av nett.

Bygges videre på:

- `PersistenceController.swift`
- `SertifiseringApp.swift`
- modellene i `InspectionModels.swift`

Leveranser:

- Sikre at alle inspeksjoner lagres lokalt.
- Støtte redigering av utkast.
- Støtte visning av tidligere inspeksjoner per maskin.
- Lagre signatur og relevante PDF-data på en stabil måte.
- Håndtere app-lukking uten datatap.
- Lage en enkel strategi for migrering når modellene endres.

Ferdig når:

- Tekniker kan starte, lukke og åpne appen igjen uten å miste pågående inspeksjon.
- Ferdige inspeksjoner ligger trygt lokalt frem til synk er på plass.

## Milepæl 3: Klargjøre arbeidsflyt for tekniker

**Formål:** Gjøre appen effektiv for én tekniker som gjør én eller flere kontroller per dag.

Bygges videre på:

- `InspectionListView.swift`
- `InspectionDetailView.swift`
- `MachineDetailView.swift`
- `SignatureEditor.swift`

Leveranser:

- Kundeoversikt.
- Maskinoversikt per kunde.
- Ny inspeksjon fra maskindetalj.
- Tydelig skille mellom utkast og ferdige inspeksjoner.
- Signaturflyt før ferdigstilling.
- Kontroll på at nødvendige felter er fylt ut før inspeksjonen fullføres.
- En tydelig handling for å markere inspeksjonen som ferdig fra tekniker.

Ferdig når:

- Tekniker kan gjennomføre en komplett inspeksjon uten manuelle steg utenfor appen.
- Appen viser hva som mangler før inspeksjonen kan markeres som ferdig.

## Milepæl 4: PDF og sertifikatgrunnlag

**Formål:** Gjøre inspeksjonsdata klare for dokumentasjon og kontorbehandling.

Bygges videre på:

- `PDFExport.swift`
- `InspectionDetailView.swift`
- `SignatureEditor.swift`
- `InspectionModels.swift`

Leveranser:

- Standardisere PDF-eksporten i `PDFExport.swift`.
- Sørge for at rapporten inneholder kunde, maskin, dato, tekniker, sjekkliste, avvik og signatur.
- Lage et tydelig datagrunnlag for sertifikat.
- Legge inn sertifikatnummer eller felt som kan fylles inn senere.
- Vurdere egen modell for `CertificateDraft`.
- Sørge for at PDF bruker de samme dataene som kontorvisningen, slik at rapport og behandling ikke spriker.

Ferdig når:

- En ferdig inspeksjon kan eksporteres som PDF.
- Kontoret kan bruke samme inspeksjonsdata til å lage eller ferdigstille sertifikat.

## Milepæl 5: Status og kontorbehandling i appen

**Formål:** Gjøre det mulig å se hvilke inspeksjoner kontoret må behandle.

Bygges videre på:

- `InspectionListView.swift`
- `InspectionDetailView.swift`
- `MachineDetailView.swift`
- `InspectionModels.swift`

Leveranser:

- Legge inn statusfelt på inspeksjoner.
- Lage filtrering for ferdige inspeksjoner.
- Lage en enkel kontorvisning: `Klar for kontor`.
- Legge inn handlinger for kontorbruker:
  - Marker som behandlet.
  - Marker som fakturert.
  - Eksporter PDF.
  - Åpne kunde og maskinhistorikk.
- Vise tydelig forskjell på teknikerens utkast og kontorets behandlingskø.

Ferdig når:

- Kontorbruker kan se hva som er klart til behandling.
- Kontorbruker kan markere inspeksjoner som behandlet eller fakturert.

## Milepæl 6: iCloud/CloudKit-synk

**Formål:** Tekniker og kontorbruker skal kunne dele inspeksjonsdata uten manuell eksport.

Bygges videre på:

- `PersistenceController.swift`
- `SertifiseringApp.swift`
- modellene i `InspectionModels.swift`
- eventuelle entitlements/capabilities i Xcode-prosjektet

Anbefalt retning:

- Bruk lokal lagring først.
- Koble lokal lagring til iCloud/CloudKit når modellene er stabile.
- Behold appen offline-first, slik at tekniker kan jobbe uten dekning.

Leveranser:

- Aktivere iCloud/CloudKit capability i Xcode.
- Definere hvilke data som skal synkroniseres.
- Teste synk mellom to Apple-enheter eller simulatorer med ulike brukere.
- Håndtere konflikter ved endringer fra flere brukere.
- Synliggjøre synkstatus i appen.
- Avklare om dette skal være felles firmadata, delt CloudKit-database eller senere egen backend.

Ferdig når:

- Tekniker kan fullføre en inspeksjon på én enhet.
- Kontorbruker kan se samme inspeksjon på en annen enhet.
- Appen håndterer midlertidig manglende nett uten datatap.

Status nå:

- iCloud/CloudKit kan slås på i `SettingsView`.
- Appen er testet med synk mellom iPad og simulator på samme Apple ID.
- Egen CloudKit-delingssone for firmadata er lagt inn.
- `SettingsView` og hovedlisten har knapp for å synke firmadata til iCloud.
- `SettingsView` har knapp for å dele firmadata med kontorbruker via CloudKit Sharing.
- Kontorbruker kan akseptere deling og hente data fra `sharedCloudDatabase`.
- Toveis manuell synk er testet mellom iPad og simulator med ulike Apple ID-er.
- Hovedlisten har iCloud-meny, dra-ned-for-å-hente og automatisk første henting for kontor/admin.
- Detaljbildet forsøker automatisk iCloud-synk når arbeidsstatus endres.

## Milepæl 7: Brukerroller

**Formål:** Skille teknikerfunksjoner fra kontorfunksjoner uten å gjøre appen unødvendig komplisert.

Bygges videre på:

- `SettingsView.swift`
- `InspectionListView.swift`
- `InspectionDetailView.swift`
- `HelpGuideView.swift`

Leveranser:

- Enkel rolleinnstilling i starten:
  - Tekniker
  - Kontor
  - Admin
- Tilpasse visninger basert på valgt rolle.
- Skjule eller nedprioritere irrelevante handlinger for hver rolle.
- Vise relevant hjelpetekst for valgt rolle.

Ferdig når:

- Tekniker får en arbeidsflate for inspeksjon.
- Kontorbruker får en arbeidsflate for behandling, sertifikat og fakturering.

## Milepæl 8: Fakturagrunnlag

**Formål:** Kontoret skal kunne bruke ferdige inspeksjoner som grunnlag for fakturering.

Bygges videre på:

- `InspectionModels.swift`
- `InspectionListView.swift`
- `PDFExport.swift`
- eventuell ny eksporthjelper, for eksempel `BillingExport.swift`

Leveranser:

- Legge inn fakturastatus.
- Legge inn kundeinformasjon som trengs til faktura.
- Legge inn prislinjer eller tjenestetype hvis relevant.
- Eksportere fakturagrunnlag som CSV eller PDF.
- Vurdere senere integrasjon mot regnskapssystem.

Ferdig når:

- Kontorbruker kan finne alle inspeksjoner som ikke er fakturert.
- Kontorbruker kan eksportere et ryddig fakturagrunnlag.

Status nå:

- Kontorvisningen viser egen kø for `Ikke fakturert`.
- Kontorbruker kan lage og dele CSV-basert fakturagrunnlag fra behandlede kontroller.
- CSV-eksporten ligger i egen eksporthjelper og er dekket av en enkel enhetstest.

## Milepæl 9: Test og pilotbruk

**Formål:** Prøve appen i ekte arbeid før den brukes fast.

Bygges videre på:

- `SertifiseringTests.swift`
- `SertifiseringUITests.swift`
- `SertifiseringUITestsLaunchTests.swift`

Leveranser:

- Test med realistiske kunder og maskiner.
- Test uten nett.
- Test med dårlig nett og senere synk.
- Test PDF og signatur.
- Test arbeidsflyten mellom tekniker og kontor.
- Legge inn enkle tester for statusendringer og PDF-grunnlag.
- Rette feil som dukker opp i faktisk bruk.

Ferdig når:

- Minst noen reelle inspeksjoner er gjennomført fra start til slutt.
- Kontoret kan behandle disse uten manuell rydding i dataene.

Status nå:

- Statusflyt og fakturagrunnlag har enhetstester.
- PDF-eksport har en røyk-test som bekrefter at dagens PDF-oppsett fortsatt genererer en gyldig fil.
- `HelpGuideView` har en steg-for-steg pilot-sjekkliste for test med tekniker-iPad og kontor/simulator.

## Milepæl 10: Klargjøring for fast kontorbruk

**Formål:** Gjøre løsningen klar nok til daglig bruk av tekniker og kontor.

Bygges videre på:

- `SettingsView.swift`
- `HelpGuideView.swift`
- `InspectionListView.swift`
- `PDFExport.swift`
- `PersistenceController.swift`

Leveranser:

- Stabil datasynk.
- Enkel backup- og gjenopprettingsstrategi.
- Tydelig kontorvisning.
- Ferdig PDF- eller sertifikatflyt.
- Fakturagrunnlag klart for eksport.
- Grunnleggende dokumentasjon i `HelpGuideView`.
- Avklart rutine for hvem som behandler og fakturerer inspeksjoner.

Ferdig når:

- Tekniker kan bruke appen ute hos kunde.
- Kontoret kan hente ferdige inspeksjoner.
- Kontoret kan lage sertifikat og fakturagrunnlag.
- Data flyter uten manuell kopiering mellom enheter.

Status nå:

- `SettingsView` viser driftsstatus med valgt rolle, lagringsmodus, totalt antall kontroller og kontorkøer.
- `HelpGuideView` beskriver daglig kontorrutine og ansvarsdeling mellom tekniker og kontor.
- Kontorbehandling krever sertifikatnummer før kontrollen kan markeres som behandlet.
- Hovedlisten varsler når en kontroll i kontorkøen mangler sertifikatnummer.
- Detaljbildet viser en egen `Kontorsjekk` for kontor/admin før behandling og fakturering.
- Hovedlisten og `Kontorsjekk` viser antall sjekkpunkt som er merket med `Mangel`.
- Fakturagrunnlag i CSV inkluderer `Antall mangler`.

## Anbefalt rekkefølge nå

1. Fullfør og stabiliser datamodellen i `InspectionModels.swift`.
2. Gjør lokal lagring trygg i `PersistenceController.swift`.
3. Legg inn inspeksjonsstatus og bruk den i `InspectionListView.swift` og `InspectionDetailView.swift`.
4. Rydd PDF-eksport og sertifikatgrunnlag i `PDFExport.swift`.
5. Lag enkel kontorvisning basert på dagens `InspectionListView.swift`.
6. Legg på iCloud/CloudKit-synk når modellene er stabile.
7. Test med én tekniker og én kontorbruker.

## Viktige valg før CloudKit bygges inn

Disse bør avklares tidlig:

- Skal alle firmaets data ligge på én delt database, eller per bruker?
- Skal kontorbruker kunne redigere inspeksjoner, eller bare behandle dem?
- Skal sertifikat opprettes automatisk eller godkjennes manuelt av kontoret?
- Skal faktura lages i appen, eller bare eksporteres til regnskapssystem?
- Skal appen kun brukes på Apple-enheter, eller trengs webtilgang senere?

## Teknisk anbefaling

For første versjon anbefales denne retningen:

- Offline-first lokal lagring.
- CloudKit/iCloud for synk mellom tekniker og kontor.
- Tydelige statuser på inspeksjoner.
- Egen kontorvisning for ferdige inspeksjoner.
- PDF- og fakturagrunnlag basert på samme inspeksjonsdata.

Dette gir en enkel vei videre uten å bygge en full backend for tidlig.
