# PocketPal Vulkan-Fork: Entscheidungen und Log

Ziel: PocketPal nutzt auf dem Pixel 9 Pro XL (Mali-G715, GrapheneOS) die GPU über Vulkan.
Maschinenlesbare Fassung: `decisions.json`.

## Befund

- llama.rn baut für Android nur OpenCL und Hexagon. OpenCL läuft nur über eine Variante, die `hasAdreno` und Hexagon voraussetzt (`RNLlama.java`).
- Das npm-Paket von llama.rn schließt `ggml-vulkan` aus. Die Quellen kommen deshalb aus dem Git-Tag `v0.13.0-rc.9`.
- PocketPal sperrt zusätzlich in `deviceCapabilities.ts` (`no_adreno`) und setzt ohne Freigabe `no_gpu_devices: true`.

## Entscheidungen

| Datum | Entscheidung | Grund | Verworfen |
|---|---|---|---|
| 2026-11-06 | Fork statt Vorabmessung | Vulkan-Nutzen und Termux-Setup sind aus der Praxis bekannt | Erneute Messung in Termux |
| 2026-11-06 | Build über GitHub Actions | Vorgabe von San | Eigener PC, Frankfurt-Host, Cloud-Umgebung |
| 2026-11-06 | Eigene Variante `rnllama_v8_2_dotprod_i8mm_vulkan`, nur auf Nicht-Adreno geladen | Passt zum Variantenmodell, CPU-Fallback bleibt | Vulkan in vorhandene Varianten mischen |
| 2026-11-06 | Shader vor Gradle erzeugen | Kein Host-Tool im Android-Cross-Build | `ExternalProject` aus Upstream-CMake |
| 2026-11-06 | Feature-Tests mit `-O`, jeder Fehler heißt OFF | Behebt die Ursache des `shaderc`-Fehlers | Tests fest entfernen wie im Termux-Patch |
| 2026-11-06 | F16 als Build-Schalter, Standard an | Geringster Aufwand, Vergleich über zwei APKs | Schalter in der App (später möglich) |
| 2026-11-06 | Eigene Paket-ID `com.pocketpalai.vulkan`, Debug-Keystore | Parallelinstallation, stabile Signatur ohne Secret | Keystore pro Lauf (bricht Updates) |

| 2026-11-06 | Gegen `libvulkan.so`-Stub von API 29 linken | Lauf #1 scheiterte am Link: `vkGetPhysicalDeviceFeatures2` fehlt im API-24-Stub (minSdk 24) | minSdk der App auf 29 heben |

## Log

- 2026-11-06 Lauf #1 (`fe1929f`): Shader ok (155, alle optionalen Features OFF), Link-Fehler `vkGetPhysicalDeviceFeatures2`, 35 min.

## Offene Risiken

- Der Keystore ist öffentlich im Repo. Für ein Dauer-Setup braucht es einen eigenen Keystore als Actions-Secret.
- `glslc` aus NDK r27 ist älter als die Shader-Quellen. Lokal nicht testbar, der erste Lauf zeigt es.
- Der NDK-Build der Variante ist ungetestet.
- F16-Vorteil stammt aus sd.cpp, für Textmodelle unbelegt.
- `isGpuAvailable` lädt in `checkGpuSupport` die Backend-Liste, Auswirkung auf die Startzeit ungeprüft.

## Grün

Die App zeigt nach dem Laden `Active: GPU (Vulkan0)`, ein GGUF-Modell antwortet korrekt, die Antwort stimmt bei gleicher Eingabe inhaltlich mit dem CPU-Lauf überein, und die Geschwindigkeit liegt nahe am Termux-Wert.
