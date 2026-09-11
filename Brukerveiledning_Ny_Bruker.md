# Brukerveiledning for ny bruker

Denne veiledningen beskriver hvordan tre blanke enheter settes opp for test og pilotbruk av Sertifisering-appen.

Enheter i denne planen:

- iPad 10 med Apple ID: terjemoe54@hotmail.com
- iPhone 15 Pro med Apple ID: terjemoe54@hotmail.com
- iPhone 17 simulator med Apple ID: verksted@mlmaskin.no

Målet er å teste hele arbeidsflyten: tekniker registrerer kontroll, deler firmadata, kontor henter data, lager PDF og sertifikatgrunnlag, eksporterer fakturagrunnlag og markerer saken som fakturert.

## 1. Før du starter

Kontroller dette før enhetene settes opp:

- Alle enheter har nyeste tilgjengelige iOS/simulator-runtime.
- Appen er installert eller klar til å kjøres fra Xcode på alle tre enheter.
- Begge Apple ID-er kan logge inn i iCloud.
- iCloud Drive og iCloud for appdata er aktivert.
- Nettverk virker på alle enheter.
- Du har tilgang til samme CloudKit-container: iCloud.com.terjemoe.Sertifisering.

Hvis du starter helt blankt, gjør oppsettet i rekkefølgen under. Ikke bland roller før første test er ferdig.

## 2. Rollefordeling i testen

Bruk denne rollefordelingen:

- iPad 10: Tekniker hovedenhet.
- iPhone 15 Pro: Ekstra tekniker-/kontrollenhet på samme Apple ID.
- iPhone 17 simulator: Kontorbruker med egen Apple ID.

Poenget er å teste både samme Apple ID og delt tilgang til en annen Apple ID.

## 3. Sett opp iPad 10 først

1. Start iPad 10 som blank enhet.
2. Logg inn med Apple ID: terjemoe54@hotmail.com.
3. Åpne Innstillinger på iPad.
4. Kontroller at iCloud er aktivert.
5. Installer eller kjør Sertifisering-appen.
6. Åpne appen.
7. Gå til Innstillinger i appen.
8. Velg rolle: Tekniker.
9. Kontroller at lagring står som lokal eller iCloud etter valgt testmodus.
10. Slå på iCloud/CloudKit hvis deling skal testes.
11. Lukk Innstillinger.
12. Opprett første testkontroll fra hovedlisten.

Denne iPaden skal brukes som primær tekniker ute hos kunde.

## 4. Sett opp iPhone 15 Pro

1. Start iPhone 15 Pro som blank enhet.
2. Logg inn med samme Apple ID: terjemoe54@hotmail.com.
3. Kontroller at iCloud er aktivert.
4. Installer eller kjør Sertifisering-appen.
5. Åpne appen.
6. Gå til Innstillinger i appen.
7. Velg rolle: Tekniker eller Admin.
8. Slå på iCloud/CloudKit hvis den skal se samme private iCloud-data.
9. Hent eller synk firmadata fra iCloud-menyen.
10. Kontroller at data fra iPad kan vises etter synk.

Denne enheten brukes til å teste samme Apple ID på flere enheter.

## 5. Sett opp iPhone 17 simulator

1. Start iPhone 17 simulator som blank simulator.
2. Logg inn med Apple ID: verksted@mlmaskin.no hvis simulatoren støtter iCloud-login i ditt miljø.
3. Kjør Sertifisering-appen fra Xcode på simulatoren.
4. Åpne appen.
5. Gå til Innstillinger.
6. Velg rolle: Kontor.
7. Slå på iCloud/CloudKit hvis tilgjengelig.
8. Vent med å hente data til iPad har delt firmadata.

Denne simulatoren brukes som kontorbruker.

## 6. Lag testdata på iPad 10

Opprett en ny kontroll på iPad 10 med disse verdiene.

Kunde og forside:

- Firma / Eier: ML Testkunde AS
- Kontaktperson: Kari Testkunde
- Telefon: 40000000
- Adresse: Testveien 12, 3170 Sem
- Sted: Testhall A
- Prosjektnummer: PILOT-001
- Kontroll utført av: Terje Moe
- Sertifikatnummer: La stå tomt først
- Antall vedlegg: 2
- Kontrollresultat: Godkjent med mangel
- Merknader / mangler: Pilotkontroll. Test av teknikerflyt, kontorbehandling og fakturagrunnlag.

Maskin 1:

- Navn: Traverskran A1
- Maskintype: Kran
- Serienummer: TK-A1-2026
- Produsent: Konecranes
- Kran nr: K-101
- Talje nr: T-101
- Plassering: Hall A, felt 3
- Lastangivelse: 5T
- Evt. sert. nr: SERT-GAMMEL-101
- SWP: 82 prosent

Sjekkliste på maskin 1:

- 1.1 Sprekker, rust, deform.: OK
- 1.2 Boltforbindelser: Mangel
- Merknad på 1.2: Ettertrekk bolter på venstre endebjelke før neste service.
- 2.1 Kabelforbindelse: OK
- 2.9 Nødstop: Mangel
- Merknad på 2.9: Nødstop treg ved retur. Må funksjonstestes etter utbedring.
- 8.1 WLL/SWL-Kraner/krok: OK

Maskin 2:

- Navn: Kjettingtalje B2
- Maskintype: Kjettingtalje
- Serienummer: KT-B2-2026
- Produsent: Demag
- Talje nr: T-202
- Plassering: Verksted B
- Lastangivelse: 1T

Sjekkliste på maskin 2:

- 4.1 Sprekker, rust, deform.: OK
- 4.6 Kobling - heis: Ikke relevant
- 5.5 Låseleppe: Mangel
- Merknad på 5.5: Låseleppe er slitt og bør byttes før løft over personell.

Signatur:

- Kontrollør signatur (navn): Terje Moe
- Kundens signatur (navn): Kari Testkunde
- Tegn signatur i begge signaturfelt.

## 7. Fullfør teknikerflyt på iPad

1. Kontroller at Teknikersjekk viser firma/eier, kontrollør og minst én maskin som fullført.
2. Generer PDF.
3. Åpne eller del PDF-en og kontroller at merknader har nok plass.
4. Trykk Marker ferdig fra tekniker.
5. Bruk iCloud-menyen og trykk Synk firmadata til deling.
6. Gå til Kunder og åpne ML Testkunde AS.
7. Kontroller at begge maskiner vises i historikken.
8. Start en ny kontroll fra Traverskran A1 for å sjekke at maskindata kopieres.
9. Avbryt eller la den nye kontrollen stå som utkast hvis den bare brukes til test.

Forventet resultat:

- Hovedlisten viser kontrollen som Ferdig fra tekniker.
- Kundeoversikten viser ML Testkunde AS.
- Maskinhistorikken viser Traverskran A1 og Kjettingtalje B2.

## 8. Del firmadata med kontorbruker

På iPad 10:

1. Gå til Innstillinger.
2. Kontroller at iCloud/CloudKit er aktivert.
3. Trykk Synk firmadata til iCloud hvis knappen vises.
4. Trykk Del firmadata med kontor.
5. Send delingslenken til Apple ID: verksted@mlmaskin.no.

På iPhone 17 simulator:

1. Åpne delingslenken.
2. Aksepter delt tilgang.
3. Åpne Sertifisering-appen.
4. Kontroller at rollen er Kontor.
5. Hent delte firmadata fra iCloud-menyen eller dra ned i hovedlisten.

Forventet resultat:

- Kontorbruker ser ML Testkunde AS i hovedlisten.
- Kontrollen ligger i Klar for behandling.

## 9. Kontorbehandling på simulator

1. Åpne kontrollen ML Testkunde AS.
2. Les Kontorsjekk.
3. Legg inn sertifikatnummer: S-2026-PILOT-001.
4. Generer PDF og kontroller rapporten.
5. Lag sertifikatgrunnlag.
6. Kontroller at sertifikatgrunnlaget inneholder kunde, maskiner og mangler.
7. Trykk Marker behandlet av kontor.
8. Gå tilbake til hovedlisten.
9. Åpne køen Ikke fakturert.
10. Trykk Lag fakturagrunnlag.
11. Del eller åpne CSV-filen og kontroller kolonnene.
12. Åpne kontrollen igjen og trykk Marker fakturert.
13. Synk endringer til iCloud.

Forventet resultat:

- Kontrollstatus går fra Ferdig fra tekniker til Behandlet av kontor.
- Fakturagrunnlag inneholder kontroll-ID, eksportdato, kunde, maskiner, mangelpunkt og merknader.
- Etter fakturering ligger kontrollen i Fakturert.

## 10. Kontroller synk tilbake på iPad og iPhone 15 Pro

På iPad 10:

1. Åpne appen.
2. Hent firmadata fra iCloud-menyen eller dra ned i hovedlisten.
3. Kontroller at samme kontroll nå er Behandlet av kontor eller Fakturert.
4. Åpne kontrollen og sjekk at sertifikatnummeret er synlig.

På iPhone 15 Pro:

1. Åpne appen.
2. Hent eller synk data.
3. Kontroller at samme kunde og maskiner finnes.
4. Sjekk at status er lik som på iPad og simulator.

## 11. Test uten nett

Kjør denne testen etter at hovedflyten virker.

1. Sett iPad 10 i flymodus.
2. Opprett ny kontroll for kunde: Offline Test AS.
3. Legg inn én maskin: Offline Traverskran.
4. Marker ett sjekkpunkt som Mangel.
5. Signer og marker ferdig fra tekniker.
6. Slå av flymodus.
7. Synk firmadata til iCloud.
8. Hent data på kontorbruker.

Forventet resultat:

- Kontroll kan fullføres uten nett.
- Data synker når nett er tilbake.
- Kontorbruker kan behandle kontrollen etter synk.

## 12. Testplan fremover

Kjør testene én etter én i denne rekkefølgen:

1. Oppstartstest: Appen åpner på alle tre enheter.
2. Rolle-test: Tekniker, Kontor og Admin viser riktige køer og knapper.
3. Lokal lagring: Opprett kontroll, lukk appen, åpne igjen og sjekk at data finnes.
4. PDF-test: Generer PDF med lange merknader og sjekk layout.
5. Kunde-test: Åpne Kunder og start ny kontroll fra eksisterende maskin.
6. Tekniker-test: Fullfør kontroll fra tekniker.
7. Delingstest: Del firmadata fra iPad til kontorbruker.
8. Kontor-test: Behandle kontroll, lag sertifikatgrunnlag og fakturagrunnlag.
9. Faktura-test: Marker kontroll fakturert og sjekk CSV.
10. Synk-retur: Hent status tilbake på iPad og iPhone 15 Pro.
11. Offline-test: Fullfør kontroll uten nett og synk etterpå.
12. Restore-test: Lag backup, planlegg restore og kontroller data etter omstart.

Bare gå videre til neste test når forventet resultat er bekreftet. Hvis noe feiler, noter enhet, Apple ID, rolle, tidspunkt og hvilken handling som feilet.

## 13. Feilsøking

Hvis kontorbruker ikke ser data:

- Kontroller at delingslenken er akseptert med riktig Apple ID.
- Kontroller at rollen er Kontor.
- Dra ned i hovedlisten for å hente på nytt.
- Sjekk iCloud-status i Innstillinger.
- Synk firmadata på tekniker-enheten på nytt.

Hvis status ikke oppdateres:

- Åpne kontrollen og trykk Synk endringer til iCloud.
- Hent data på den andre enheten etterpå.
- Kontroller at begge enheter har nett.

Hvis PDF eller CSV mangler data:

- Sjekk at kontrollen har minst én maskin.
- Sjekk at sertifikatnummer er lagt inn før sertifikatgrunnlag.
- Sjekk at kontrollen er Behandlet av kontor før fakturagrunnlag.

## 14. Når testen er godkjent

Når alle tester er passert:

- Lag backup fra Innstillinger.
- Lagre PDF, sertifikatgrunnlag og fakturagrunnlag fra piloten.
- Noter hvilke Apple ID-er og enheter som skal brukes fast.
- Avklar hvem som eier kontorbehandling og fakturering.
- Avklar om kontoret skal kunne redigere kontrollinnhold eller bare behandle og eksportere.

Da er appen klar for mer realistisk pilot med faktiske kunder og maskiner.
