# CLAUDE.md

## Project notes (source of truth)

The maintainer's project documentation lives outside this repo, in the Obsidian vault folder `Projekte/Never Have I Ever` (shared with the app repo `never_have_i_ever`). The vault location is in the maintainer's global `~/.claude/CLAUDE.md`.

- Start with the current handover (linked under "Wo steht was" in `00 Übersicht.md`), then `04 Entscheidungen.md` and `07 Offene Fragen.md`.
- Notes are written in German. The folder is made available via `permissions.additionalDirectories` in `.claude/settings.local.json` (not committed).
- General rules: `~/.claude/CLAUDE.md` (repo `claude-standards`). This file only adds what is specific to this project.

## Project rules

- This repo is public and served by GitHub Pages: every push to `main` publishes immediately, so push only after approval. No local paths, hostnames or private data.
- Changelog prefix: `nhie-pages` (marker `%% nhie-pages:commits %%`). After cloning: `scripts/setup.sh "<vault>" "Never Have I Ever" nhie-pages`.
- The page URLs may be registered in App Store Connect. Do not rename or move `never-havi-i-ever/` (typo included) without a redirect.
- Legal texts (privacy, imprint) change only after Luis has approved the wording.

## Layout

- `index.html`, `styles.css` – overview of all app pages, shared styles
- `never-havi-i-ever/` – Never Have I Ever: `index.html`, `privacy.html`, `support.html`, `imprint.html`

## Commands

- Preview: `python3 -m http.server 8000` (http://localhost:8000)
- Test, build: none (static HTML)
- Deploy (after approval): `git push` (GitHub Pages, https://luisthein.github.io/app-pages/)
