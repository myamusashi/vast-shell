# Translations

[Back to README](../README.md)

vast-shell uses Qt's translation system. Files are in `translations/`:

- `.ts`: the editable source (XML).
- `.qm`: the compiled file used at runtime. Do not edit it.

| Locale | Language |
|---|---|
| `en_US` | English (source and fallback) |
| `id_ID` | Indonesian |

A locale without a `.qm` file falls back to the untranslated source strings.

## Add or update a translation

`lupdate` and `lrelease` come from `qt6-tools` (Arch), `qt6-tools-dev-tools` (Debian/Ubuntu) or `qt6.qttools` (NixOS).

```sh
# 1. Create the .ts file, or sync new strings into an existing one
lupdate $(find Qml -name "*.qml") -ts translations/your_locale.ts

# 2. Translate in Qt Linguist (or edit the XML by hand)
linguist translations/your_locale.ts

# 3. Compile to .qm
lrelease translations/your_locale.ts
```

Replace `your_locale` with a locale code such as `fr_FR`, `ja_JP` or `de_DE`. Syncing never overwrites existing translations.

Qt Linguist shows each string in context, tracks progress and marks unfinished or obsolete entries.

## Build integration

- **NixOS:** translations are compiled during the build.
- **Arch Linux:** `archInstall.sh` compiles them. To recompile by hand: `/usr/lib/qt6/bin/lrelease translations/*.ts`
