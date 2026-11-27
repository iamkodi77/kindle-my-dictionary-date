# Oxford English-to-Tagalog Dictionary + KOReader updater

This repository is a copy of [mrcloudworks-glitch/oxford-english-to-tagalog](https://github.com/mrcloudworks-glitch/oxford-english-to-tagalog), with an added KOReader plugin for checking and installing the latest published dictionary directly on a Kindle running KOReader.

## Install the dictionary on KOReader

1. Copy `oxford-en-tl/` into the KOReader dictionary directory on the Kindle (normally `koreader/data/dict/oxford-en-tl/`). Keep the four files together: `.dict.dz`, `.idx`, `.ifo`, `.syn`.
2. Restart KOReader or refresh/reopen the dictionary list.

## Install the one-tap updater

Copy `koreader-plugin/oxford-en-tl.koplugin/` into KOReader's `plugins/` directory (commonly `/mnt/us/koreader/plugins/` on Kindle), then restart KOReader. The plugin appears in the main menu as **Update Oxford English-Tagalog dictionary**. Connect to Wi-Fi and tap it, then confirm **Update**. It retrieves the current manifest and dictionary files from the upstream public GitHub repository and installs them under KOReader's `data/dict/oxford-en-tl/` directory. Keep the existing plugin dictionary in that location so updates replace it.

The updater stages all four StarDict files before installing them and checks their byte sizes against `oxford-en-tl/update.json`; on an interrupted download, the installed set is preserved. After updating, restart KOReader or reopen the dictionary if the updated word list is not immediately visible. The plugin requires a KOReader build with LuaSocket HTTPS support and Wi-Fi access. This is a KOReader plugin, not a Kindle firmware plugin, and it does not apply to the stock Kindle reader.

## Publish dictionary changes

The source repository's computer-side tools and curated updates are preserved in `crosspoint-plugin/dictionary-updater/`. To incorporate new curated entries and refresh StarDict binaries and their manifest:

```bash
python3 crosspoint-plugin/dictionary-updater/update_dictionary.py build
python3 crosspoint-plugin/dictionary-updater/validate_stardict.py oxford-en-tl
```

Publish the resulting `oxford-en-tl/` files to the upstream repository's `main` branch. The KOReader plugin checks that repository on each tap, so no plugin reinstall is needed for dictionary-content updates.

## Upstream contents

- `oxford-en-tl/` — compiled English-English-Tagalog StarDict dictionary and published `update.json`.
- `crosspoint-plugin/dictionary-updater/` — original CrossPoint updater and build/publish tools.
- `koreader-plugin/oxford-en-tl.koplugin/` — added KOReader on-device updater.

See the upstream README for dictionary coverage, source attribution, StarDict details, and CrossPoint installation instructions.
