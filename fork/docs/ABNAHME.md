# Abnahme: Build mit GPU-Fix und Deutsch

## 1. GPU (Kernproblem)

Befund aus Lauf #2: Die Einstellungen zeigten „CPU only – No hardware accelerators detected“.

Vermutete Ursache: ggml meldet die Mali über Vulkan als integrierte GPU (`igpu`, gemeinsamer Speicher). PocketPal suchte nur nach `type === 'gpu'` und fand deshalb nichts. Nicht ausgeschlossen ist, dass die Vulkan-Bibliothek gar nicht geladen wurde. Die neue Diagnosezeile trennt beide Fälle.

Änderung: `gpu` und `igpu` zählen jetzt beide als GPU. In den Einstellungen unter der Geräteauswahl steht neu:

- `Backends: …` mit allen Geräten, die llama.rn meldet, als `Backend/Typ/Name`
- nach dem Laden eines Modells `Lib: …`, die tatsächlich geladene Native-Bibliothek

| Prüfpunkt | Erwartet | Ergebnis |
|---|---|---|
| Zeile `Backends` | enthält `Vulkan/igpu/Vulkan0` | |
| Geräteauswahl | Buttons `CPU` und `GPU (Vulkan)` | |
| Nach Modell-Laden mit GPU | `Lib: rnllama_jni_v8_2_dotprod_i8mm_vulkan` und `Active: GPU (…)` | |
| Gleiche Frage GPU und CPU | inhaltlich gleiche Antwort | |
| Geschwindigkeit (2. Lauf zählt) | GPU schneller als CPU | |

Wenn `Backends` nur `CPU/cpu/CPU` zeigt, wurde die Vulkan-Variante nicht geladen. Dann bitte Screenshot der Zeile schicken.

## 2. Deutsch

Deutsch war im Projekt als Datei vorhanden, aber nicht freigeschaltet. Einstellungen → Sprache → `Deutsch (DE)`.

- 89 fehlende Texte übersetzt (Spracheingabe, Sprachmodus, Plus, Projektionsmodell)
- 19 englisch gebliebene Texte übersetzt (Exportieren, Herunterladen, Systemprompt, …)
- 2 kaputte Platzhalter repariert (`{{messing}}`, `{{count}`), die in der App als Rohtext erschienen wären
- „Speculative Decoding“ war als „spekulative Entschlüsselung“ übersetzt, jetzt „Spekulatives Dekodieren“
- Anrede: „Sie“, wie im überwiegenden Teil der Datei (229 zu 5)

| Prüfpunkt | Ergebnis |
|---|---|
| Sprache umschaltbar, App vollständig deutsch | |
| Datumsangaben deutsch (z. B. im Chatverlauf) | |
| Keine abgeschnittenen Texte in Buttons | |
| Sprachmodus-/Plus-Texte lesen sich natürlich | |

Bekannt und offen: Der ältere Sprachmodus-Block duzt („Spreche“, „Versuche es“). Bestehende Texte wurden nicht vollständig gegengelesen, nur die geänderten.

## 3. Übersetzung für das Hauptprojekt

Branch `i18n-de` auf Basis des aktuellen `main`, unabhängig vom Vulkan-Umbau. Geprüft: Locale-Tests (115/115), TypeScript, Font-Check (`verify:fonts`).

Nach der Abnahme hier: Pull Request von `FenrisSulfr:i18n-de` nach `a-ghorbani:main` öffnen. Wichtig: Upstream übersetzt möglicherweise über ein Übersetzungsportal; vorher im Projekt prüfen, ob Übersetzungs-PRs direkt angenommen werden.
