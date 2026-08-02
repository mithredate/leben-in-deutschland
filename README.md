# Leben in Deutschland – Testtrainer

Mobile-first PWA zum Lernen für den Test **„Leben in Deutschland“** (Niederlassungserlaubnis) bzw. den **Einbürgerungstest** — alle 300 allgemeinen Fragen plus die 10 Fragen deines Bundeslandes, mit Bildern, englischen Erklärungen inkl. Quellenangaben und Spaced Repetition.

**Kein Backend, kein Konto, kein Tracking.** Der gesamte Lernfortschritt liegt im `localStorage` deines Geräts. Nach dem ersten Besuch funktioniert die App vollständig offline (Service Worker, alle Daten und Bilder vorgeladen).

**Live:** https://mithredate.com/leben-in-deutschland/

## Features

- **Lernrunden (30 Fragen)** – Spaced Repetition (Leitner, auf kurze Vorbereitungszeit optimiert): Bekanntes verschwindet sofort aus der Rotation, Schwaches kommt zuerst, Fehler werden noch in derselben Runde wiederholt („successive relearning“), hartnäckige Fragen (🔥) bekommen einen eigenen Filter.
- **Testsimulation** – 33 Fragen (30 allgemein + 3 Bundesland), 60-Minuten-Timer, Auswertung gegen beide Bestehensgrenzen (15 = Leben in Deutschland, 17 = Einbürgerung), Fehler direkt üben.
- **Erklärungen mit Quellen** – jede Frage hat eine englische Erklärung (warum die Antwort stimmt) mit Link auf Grundgesetz/Gesetze bzw. Wikipedia. KI-erstellt, ohne Gewähr – die Quelle ist immer verlinkt.
- **Flip-Karte** – Frage und Antworten auf Deutsch (wie in der echten Prüfung); bei Bedarf per „EN ⇄“ zur englischen Übersetzung umdrehen.
- **Fragenkatalog** – alle 460 Fragen durchsuchen, nach Thema/Status filtern, gezielt üben.
- **Export/Import** – Fortschritt als JSON-Datei sichern und auf ein anderes Gerät mitnehmen.

## Stack

Nuxt 4 (SPA, statisch generiert) · Vue 3 · Tailwind CSS 4 · @vite-pwa/nuxt (Workbox). Kein Server – `nuxi generate` erzeugt eine rein statische Seite.

## Entwicklung

```bash
npm install
npm run dev        # http://localhost:3000/leben-in-deutschland/
npm run generate   # statischer Build nach .output/public
```

## Deployment

GitHub Actions baut bei jedem Push auf `main` und deployt nach GitHub Pages (`.github/workflows/deploy.yml`). Der Fortschritt der Nutzer bleibt bei Updates erhalten (localStorage-Schema ist stabil, Fragen sind über Inhalts-Hashes identifiziert).

## Daten

Fragenkatalog: BAMF „Gesamtfragenkatalog zum Test Leben in Deutschland und zum Einbürgerungstest“ (Stand 05/2025). Aufbereitet und kreuzvalidiert aus zwei unabhängigen Open-Source-Quellen:

- [flexsurfer/einburgerungstest](https://github.com/flexsurfer/einburgerungstest) (MIT) — Reihenfolge, Antworten, Kategorien, Bilder
- [leben-in-deutschland/leben-in-deutschland-scrapper](https://github.com/leben-in-deutschland/leben-in-deutschland-scrapper) (MIT) — Übersetzungen, weitere Bilder

Die Lösungen beider Quellen wurden programmatisch gegeneinander geprüft; Abweichungen wurden gegen den aktuellen offiziellen Katalog verifiziert. Erklärungen sind KI-erstellt mit verlinkter Quelle (alle Quell-URLs automatisiert validiert).

**Ohne Gewähr:** maßgeblich ist allein der offizielle Fragenkatalog des BAMF.

## Lizenz

MIT — siehe [LICENSE](LICENSE).
