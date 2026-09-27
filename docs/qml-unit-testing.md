# QML Unit Testing — Candidates

Status: no QML test runner wired. Only `Plugins/third_party/*_test.*` and `vastctl/internal/pretty/tree_test.go` exist. Candidates below are pure functions and timer-free state transitions extracted during Part 1 / Part 2 refactor. Side-effect owners (`Process`, `FileView`, `execDetached`, hardware) are explicitly deferred.

Proposed harness: `QtQuick.Test` `TestCase` + `qmltestrunner`, one file per owner under `Qml/tests/`. No harness committed yet; list is ordered by test value per line of test code.

## P0 — pure formatters and classifiers

### `Qml/Core/Utils/FormatTimeUtils.qml`
- `formatDuration(seconds)`: `<=0`/NaN/null → `"0:00"`; `59 → "0:59"`; `60 → "1:00"`; `3599 → "59:59"`; `3600 → "1:00:00"`; `3661 → "1:01:01"`; floors fractional input.
- `formatBattery(seconds)`: `<=0` → `"N/A"`; `<3600` → `"%N min"`; exact hour → `"H h"`; hour+minutes → `"H h M min"`.
- `formatSize(bytes)`: negative/non-number → `""`; `0 → "0 B"`; `1023 → "1023 B"`; `1024 → "1.0 KiB"`; MiB/GiB boundaries at `1048576`/`1073741824`.
- `formatClipboard(ms)`: `<=0`/NaN date → `""`; otherwise locale `"MMM d, hh:mm ap"` string, non-empty.
- `formatLauncher(tsSec)`: `NaN` → `""`; epoch seconds ×1000, `en-US` month/day/hour/minute.
- `convertTo12Hour` / `convertTo12HourCompact`: `""`/null → `""`; `"00:00"` → `"12:00 AM"` / `"12AM"`; `"12:00"` stays PM; `"13:05"` → `"1:05 PM"` / `"1PM"`; `"2026-01-01 09:30:00"` strips date prefix; non-colon input returned unchanged.
- `formatTimestampShort`: `dd/MM/yyyy` zero-padded.
- `formatTimestampCustom(timestamp, format)`: `DD`/`MM`/`YYYY`/`YY`/`HH`/`mm`/`ss` substitution; unknown tokens untouched.
- `formatCompactAge(diffMs)`: `<60s → "now"`; `60m → "1h"`; `24h → "1d"`; prefers `d > h > m`.

### `Qml/Core/Utils/WifiUtils.qml`
- `iconFor(strength, locked)`: `>=0.8 network_wifi`; `>=0.5 network_wifi_3_bar`; `>=0.3 network_wifi_2_bar`; `>=0.15 network_wifi_1_bar`; else `signal_wifi_0_bar` (no `_locked` suffix on the zero-bar branch — pin this); locked appends `_locked` on the four upper branches; null strength → zero-bar.
- `sorted(networks)`: connected first, then known, then `signalStrength` desc; null input → `[]`; must not mutate input ordering expectations.

### `Qml/Core/Utils/VolumeUtils.qml`
- `clamp(value, maximum)`: clamps to `[0, maximum]`; non-numeric → `0`; default max `1.0`.
- `fromPercent(percent, maximum)`: `100 → 1.0`; `150 → maximum`; negative → `0`.
- `toPercent(value)`: `1 → 100`; `>1 → 100` (clamped); rounds.

### `Qml/Core/Utils/AqiScale.qml`
- `categoryFor(value, categories?)`: boundary values `50/100/150/200/300/500` map to Good/Fair/Moderate/Poor/Very Poor/Hazardous; above max returns last; default table is `usaCategories` when arg omitted.
- `fraction(value, bounds, max)`: non-finite/empty bounds → `0`; value at each bound lands on segment boundary `i/segments`; mid-segment interpolates; above max clamps to `1`; `max <= lower` tail → `1`-bounded.

### `Qml/Core/Utils/MediaKind.qml`
- `isVideo(path)`: `mp4|mkv|webm|mov|avi|m4v` case-insensitive; null → false; `png` → false.
- `kindOf(path)`: video vs `png|jpg|jpeg|gif|bmp|webp|svg|avif` image vs `unknown`.
- `staticPathFor(path)`: returns `String(path ?? "")` unchanged (null → `""`).
- `videoThumbnailPathFor(path, cacheDir?)`: non-video returns `""`; video returns `<dir>/vast-wallpaper-<md5>.png`; default dir `${Paths.cacheDir}/vast-shell`.

### `Qml/Core/Utils/ModelAdapter.qml`
- `countOf(model)`: null → `0`; `count()` function vs `count`/`length` props; non-numeric → `0`.
- `itemAt(model, index)`: out-of-range/negative → `null`; prefers `get(i)` over `model[i]`.
- `indexOfValue(model, role, value)`: first match index; miss → `-1`.
- `displayText(model, index, role, fallback)`: null/`""`/undefined → fallback; otherwise `String(value)`.

### `Qml/Core/Utils/FileListMetrics.qml`
- `clampWidth(w, min, max)`: below/above/in-range.
- `clampHeight(count, rowH, spacing, max)`: `count=0 → 0`; `n` rows add `(n-1)*spacing`; caps at max; negative count → `0`.
- `computeMaxWidth(items, measure, max, pad)`: null items → `pad`-bounded; takes max of measures + pad, capped.
- `computeActiveWidth(items, measure, min, pad, emptyW)`: empty → `emptyW`; else `max(min, maxMeasure+pad)`.

### `Qml/Services/BluetoothDeviceIndex.qml`
- `connectedCount(devices, adapter)`: null adapter → `0`; counts `d.adapter === adapter && d.connected`.
- `hasWhere(devices, adapter, key)`: null adapter → false.
- `pairedDevices`: filter `adapter && paired`, connected-first, then name/address `localeCompare`.
- `availableDevices`: filter `adapter && !paired`; nameless sorts after named; then name/address compare.
- `blockedDevices`: filter `adapter && blocked`; null adapter → `[]`.

### `Qml/Services/BluetoothDeviceFormatter.qml`
- `displayName(device)`: null → `""`; prefers `name || deviceName || address`.
- `stateString(device)`: null → `""`; pairing → `"Pairing…"`; else `BluetoothDeviceState.toString(state)`.
- `addressLine(device)`: null → `""`; pairing appends `" · Pairing…"`.
- `headerSubtitle(...)`: precedence No-adapter > blocked > Enabling > Disabling > off > Scanning > tap-to-connect.
- `cardSubtitle(...)`: No-adapter > Off > `%N connected` > Scanning > On-not-connected.
- `cardIconName(...)`: disabled ×2 → `bluetooth_disabled`; connected → `bluetooth_connected`; discovering → `bluetooth_searching`; else `bluetooth`.

### `Qml/Services/SystemInfoFormatter.qml`
- `parseNetworkData(data, wifi, wired)`: skips 2 header lines; short lines `<17` fields ignored; non-matching iface ignored; returns `{iface: {rxBytes, txBytes}}`.
- `parsePerCoreCpu(data)`: `cpuN user nice system idle [iowait]` → `{total, idle}` per core; aggregate `cpu` line excluded by regex.
- `formatUsage(mb)`: `<1024 → "X.XX MB"`; else GB.
- `formatKB(kb)`: divides by 1024 then `formatUsage`.
- `formatSpeed(mbps, thresholds)`: first `limit` hit wins; fallthrough `"0.00 MB/s"`.

## P1 — weather formatter (pure subset of `Qml/Services/WeatherFormatter.qml`)

- `forecastHour(entry)`: `"2026-01-01 09:30"` → `9`; bare `"09:30"` → `9`; missing → `NaN`.
- `hourlyFromNow(forecast, currentMinutes)`: keeps `hour >= floor(now/60)`; drops non-finite; null forecast → `[]`.
- `isCurrentForecastHour(entry, currentMinutes)`: equality on floored hour.
- `moonPhaseText(phase)`: 8 known phases pass through translated; unknown passes through; null/empty → `"Unknown"`.
- `formatHourOfDay(timeStr)`: `""` → `""`; ISO string → `"HH:MM"` zero-padded.
- `formatDate(dateStr)`: `""` → `""`; else `en-US` weekday/month/day.
- `parseAstronomyTime(timeStr)`: `"06:30 PM"` → `"18:30"`; `"12:00 AM"` → `"00:00"`; `"12:00 PM"` → `"12:00"`; non-match returns input; `""` → `""`.
- `calculateDayLength(rise, set)`: missing → `{0,0}`; overnight wraps +24h; returns `{hours, minutes}`.
- `weatherStatus(code)` / `windDirectionText(deg)`: map lookup + `"Unknown"` fallback.
- `europeanAQIInfo` / `usAQIInfo`: threshold table + category/color/description shape.
- `dominantPollutant(pm25, pm10)`: ratio vs absolute threshold branches.
- `healthRecommendation(eu, us, pm25, pm10)`: boundary sweep 50/75/100/150/200.
- `quickSummary(data)`: `weatherLoaded=false → ""`; each branch (muggy/hot/cold/pleasant/moderate + priority advisories) selectable by fixture; caps at 4 parts; bullet format `"head\n\n• a\n\n• b"`.
- `iconFor(code, isDay, day, night)`: null → `WeatherIcon.windy`; night override only when key exists; fallback windy.

## P2 — state machines and navigation (timer-free transitions only)

### `Qml/Services/AuthFlow.qml`
- `submitSecret()`: empty → `false`, no signal; non-empty → `true`, clears failure, sets `inProgress`, emits `submitted(secret)`.
- `fail()`: clears text, `showFailure=true`, `inProgress=false`.
- `cancel()`: clears text, `inProgress=false`, emits `cancelled`.
- `clear()`: resets text + failure.

### `Qml/Services/TransferController.qml`
- `acceptDroppedFiles`: empty/null → no-op; Idle/FilesDropped → append + `FilesDropped`; other states reject.
- `goToDeviceSelection/goToConfirmation/goBack`: selection ⇄ confirmation ⇄ FilesDropped.
- `dismiss()`: full reset to Idle, clears files/device/flag, stops timers.
- `cancelTransfer()`: `transferSuccess=false`, state Completed, restarts reset timer.
- Deferred: `startTransfer` (calls `KDEConnect.shareFile`) and timer expiry — needs injection or signal spy.

### `Qml/Services/LauncherServices.qml` (navigation subset)
- `pageDef/parentOf/crumbOf/childPages`: lookup + `""`/undefined misses.
- `enterPage/goBack/openPath`: crumb sync; `openPath` walks nested crumbs; `onQueryChanged` pops pages whose crumb no longer prefixes query.
- `pageFilter/rowSearchText`: crumb-prefix stripping + trim + lowercase (filter only).
- `childRows/filteredItems`: empty filter returns all children; non-match filters.
- `captureFileKind(name)`: video/image/other by extension; no-dot → other.
- Deferred: `activateRow/launch/openCaptureFile` (exec side effects).

### `Qml/Services/HolidayModel.qml` (pure subset)
- `isoDate(date)`: string passthrough; Date → `YYYY-MM-DD` zero-padded.
- `applyData(json, year)`: groups entries by `entry.date`; skips non-array years; sets `loaded/cachedYear`, clears `loading`, emits `dataChanged`.
- `getHolidaysForDate/hasHoliday/nameForDate`: unloaded → `[]/false/""`; miss → defaults; multi-entry joins `", "`.
- Deferred: `ensureYear` (XHR + FileView).

### `Qml/Services/GreeterWallpaper.qml`
- `loadConfig(json, fallback)`: invalid JSON → defaults; partial JSON fills defaults; `useVideoWallpaper` coerced to bool.
- `effectiveWallpaper/colorSource/thumbnailFor`: video branch prefixes `file://` + md5 cache path; static branch passthrough.
- `isVideo`: delegates `MediaKind` (covered above; one delegation test suffices).

### `Qml/Services/ThumbnailQueue.qml` (queue subset)
- `pathFor(video, dir)`: strips extension, appends `.png` under dir; no-dot keeps basename.
- `generate`: empty args → no-op; duplicate (current or queued) → single entry; else push + `startNext`.
- `startNext/finish`: idle+nonempty → pops to `currentJob`; busy/empty → no-op; `finish` emits `thumbnailReady`, clears current, chains next.
- Deferred: `probeProcess/extractProcess` (ffprobe/ffmpeg).

## Deferred — needs extraction or harness before testing

- `Qml/Services/DynamicIslandService.qml`: `show/dismiss/dismissCurrent/promoteOrClose/finishDismissedOverlay/_expireBase/_expireOverlay/_finishClose` are deterministic but coupled to 4 live `Timer`s and `Appearance` durations. Candidate after timer injection.
- `Qml/Core/Utils/CelestialProgress.qml`: `minutesOf` is testable now (empty → `-1`; short → `-1`; non-numeric → `-1`; `"06:30"` → `390`). `progressBetween` reads live `nowMinutes`; candidate after adding a `nowMinutes` parameter.
- `Qml/Core/Utils/DebouncedValue.qml`: only timer behavior; needs `TestCase.tryCompare` timing test, low value.
- `Qml/Services/CaptureNotify.qml` / `CaptureSaver.qml` / `AudioRestore.qml` / `KDEConnect.qml` / `Hotspot.qml` / `ScreenCaptureHistory.qml`: `Process`/`execDetached`/`FileView`/hardware side effects dominate; test after extracting arg-builders and parsers.
- `Qml/Core/Utils/IconUtils.qml`: `desktopId` string fallback chain (`application.id` → binary basename → node-name basename) is testable with stub nodes; `guessIconPath/iconForId` wrap `Quickshell.iconPath` and need a stub.
- `Qml/Core/Utils/Time.qml`: `SystemClock` wrapper only; no test value.
