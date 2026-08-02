# Leben in Deutschland – Testtrainer

Mobile-first PWA zum Lernen für den Test **„Leben in Deutschland“** (Niederlassungserlaubnis) bzw. den **Einbürgerungstest** — alle 300 allgemeinen Fragen plus die 10 Fragen deines Bundeslandes, mit Bildern, englischen Erklärungen und Spaced Repetition.

**Kein Backend, kein Konto, kein Tracking.** Der gesamte Lernfortschritt liegt im `localStorage` deines Geräts. Nach dem ersten Besuch funktioniert die App vollständig offline (Service Worker).

## Features

- **Lernen** – Spaced-Repetition (Leitner, auf kurze Vorbereitungszeit optimiert): Fragen, die du kennst, verschwinden; Fehler kommen wieder.
- **Testsimulation** – 33 Fragen (30 allgemein + 3 Bundesland), 60-Minuten-Timer, Auswertung gegen beide Bestehensgrenzen (15 = Leben in Deutschland, 17 = Einbürgerung).
- **Fragenkatalog** – alle 460 Fragen durchsuchen, nach Thema/Status filtern, gezielt üben.
- **Merkhilfen** – die Zahlen, Daten und Fangfragen, die immer wieder drankommen.
- **Export/Import** – Fortschritt als JSON-Datei sichern und auf ein anderes Gerät mitnehmen.

## Deployment (GitHub Pages)

Die App ist reines statisches HTML/CSS/JS — kein Build-Schritt.

```bash
gh repo create leben-in-deutschland --public --source . --push
gh api repos/{owner}/leben-in-deutschland/pages -X POST \
  -f 'source[branch]=main' -f 'source[path]=/'
```

Oder über die Web-UI: Repo pushen → **Settings → Pages → Deploy from a branch → main / (root)**. Die App läuft dann unter `https://<user>.github.io/leben-in-deutschland/`.

Auf dem iPhone: Seite in Safari öffnen → Teilen → **„Zum Home-Bildschirm“**. Auf Android bietet Chrome die Installation automatisch an.

## Lokal starten

```bash
python3 -m http.server 8000
# http://localhost:8000
```

(Ein Server ist nötig, weil ES-Module und Service Worker nicht über `file://` laufen.)

## Daten

Fragenkatalog: BAMF „Gesamtfragenkatalog zum Test Leben in Deutschland und zum Einbürgerungstest“ (Stand 05/2025). Aufbereitet und kreuzvalidiert aus zwei unabhängigen Open-Source-Quellen:

- [flexsurfer/einburgerungstest](https://github.com/flexsurfer/einburgerungstest) (MIT) — Reihenfolge, Antworten, Kategorien, Bilder
- [leben-in-deutschland/leben-in-deutschland-scrapper](https://github.com/leben-in-deutschland/leben-in-deutschland-scrapper) (MIT) — englische Erklärungen und Übersetzungen, weitere Bilder

Die Lösungen beider Quellen wurden programmatisch gegeneinander geprüft; Abweichungen wurden gegen den aktuellen offiziellen Katalog verifiziert.

**Ohne Gewähr:** maßgeblich ist allein der offizielle Fragenkatalog des BAMF.

## Lizenz

MIT — siehe [LICENSE](LICENSE).
