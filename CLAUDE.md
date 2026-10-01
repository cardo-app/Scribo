# Scribo – Hinweise für Claude Code

Scribo: eigenständige Notizen-Web-App (PWA), gehört zum Cardo-Ökosystem, für das Schreiben mit Stift (Apple Pencil), Funktionen nach Vorbild von GoodNotes, Aussehen und Farbthemen wie Cardo (Karteikarten-App im Nachbarordner `../Cardo-App`). Soll später evtl. in Cardo integriert werden. Nutzung auf iPad Pro 11" (Hauptgerät), iPhone 16 Pro und Mac.

## Arbeitsweise (Wünsche des Nutzers)
- Sprache: Deutsch, kurz und verständlich (kein Fachjargon ohne Erklärung).
- „Frag nicht immer, sondern mach.“ Änderungen direkt umsetzen, testen, committen und pushen. Pushen macht Claude selbst über GitHub Desktop (Computer-Steuerung: Repo oben links wählen → „Push origin“ klicken); im Terminal gibt es keine GitHub-Zugangsdaten. Der Nutzer will dafür nicht selbst klicken. Nur bei echten Richtungsentscheidungen kurz fragen.
- Nach jeder Änderung: in 2–4 Sätzen sagen, was sich geändert hat und was auf dem echten Gerät noch zu prüfen ist.

## Dateien
- `index.html` – die ganze App (CSS + ein Inline-Skript als IIFE mit "use strict"). Farbthemen (THEMES, THEME_IC, CSS-Tokens) sind 1:1 aus Cardo übernommen – bei Änderungen an Cardos Themen hier mitziehen.
- `sw.js` – Service Worker. **Bei jeder Änderung an index.html/sw.js die Cache-Version hochzählen** (`notizen-vNN`). Er darf nur Speicher löschen, die mit `notizen-` beginnen (Cardo liegt auf derselben Adresse).
- `icons/icon.svg` – App-Icon (S aus zwei Bögen mit orangem Punkt, leichter Schatten); PNGs daraus mit `qlmanage -t -s 1024` + `sips` erzeugen.
- `supabase-setup.sql` – einmal im Supabase-SQL-Editor ausführen (Tabelle `notes_docs`, privater Bucket `note-files`).
- Ordner `Claude outputs/` NICHT committen.

## Aufbau
- Supabase: gleiches Projekt wie Cardo (rormgkvthvisrctcsjrg), gleiches Konto. Tabelle `notes_docs` (user_id, path, data): `folders/<id>`, `notes/<id>` (Seitenliste), `thumbs/<id>`, `settings/main`, `ink/<notiz>/<seite>` (Striche, Delta-kodiert). Dateien: `note-files/<user>/<datei>`.
- Auf dem Gerät: IndexedDB `cardo-notizen` (meta, ink, pend = wartende Änderungen, files, fup = wartende Uploads). Offline-first.
- Farbthema „Wie Cardo“ liest Cardos `docs`-Zeile `settings/main`.
- Editor: jede Seite 1000 Einheiten breit; gezeichnet wird nur der sichtbare Ausschnitt (scharf beim Zoomen, wenig Speicher). Stift = Pointer Events (pen), Handballen/Finger über touchType/Einstellung „Mit dem Finger zeichnen“. Zwei Finger = verschieben/zoomen (eigene Geste). PDF über pdf.js 3.11 (cdnjs).

## Vor jedem Commit
- Syntax prüfen (im Browser: Seite laden, Konsole auf Fehler prüfen) bzw. mit node: Skript zwischen `<script>` und `</script>` extrahieren und `node --check`.
- Keine `//`-Kommentare in Einzeiler setzen, hinter denen noch Code steht – dort `/* … */`.
- Testen ohne Konto: `index.html?local` → nur lokal, kein Supabase.
- Commit-Nachricht auf Deutsch, beschreibend, mit „Cache vNN“ am Ende.

## Entscheidungen des Nutzers
- App heißt **Scribo** (Stand 30.09.2026). Icon vom Nutzer vorgegeben (S + oranger Punkt), Schatten ergänzt.
- Notizen-Struktur: Fach → Unterordner nach Thema; Art (Vorlesung/Tutorium/Übung/Sonstiges) als Etikett, nicht als Ordner. Im Fach erscheinen alle Notizen der Unterordner gesammelt.
- Startanimation nur beim ersten Öffnen nach der Installation (nicht angemeldet, `scribo-intro-seen` fehlt), nicht überspringbar, endet im Anmeldebildschirm; Aufbau/Farben wie Cardos Intro: S dreht sich halb, Kugel fliegt hoch → fällt auf eine dunkle Notizseite, Stift kritzelt das S (runter–hoch–runter mit Schlaufen), Kugel hüpft währenddessen auf der Oberkante → fällt ins S, beim Aufprall entsteht das Icon (vom Nutzer als „perfekt“ abgenommen, 01.10.2026). Testen mit `?intro`.
