# Ultimate Downloader

Download ebooks from **15+ platforms** in one unified, interactive tool.

Combines the power of two open-source projects:
- **[EbookDownloader](https://github.com/RythenGlyth/EbookDownloader)** by [@RythenGlyth](https://github.com/RythenGlyth) — direct downloaders for Cornelsen, Klett, Westermann, and more
- **[d4sd](https://github.com/garzj/d4sd)** by [@garzj](https://github.com/garzj) — puppeteer-based downloader for digi4school, Scook, Trauner, and more  
  *(using the extended fork [Johni12M/d4sd](https://github.com/Johni12M/d4sd) with added Helbling, Klett bridge and other improvements)*

---

## Supported Platforms

### Via digi4school downloader (d4sd)
| Platform | URL | Notes |
|---|---|---|
| **Digi4School** | digi4school.at | Login + download whole shelf or specific books |
| **Scook** | scook.at | Provide book URLs directly |
| **Trauner DigiBox** | trauner-digibox.com | Login + download whole shelf or specific books |
| **Helbling e-zone** | helbling.at | Provide book URLs directly *(experimental)* |

These shelves also automatically handle linked books from **Westermann BiBox**, **OEBV**, **Klett bridge**, and others.

### Direct downloaders
| Platform | URL |
|---|---|
| **Cornelsen** | cornelsen.de |
| **Klett** | klett.de |
| **Klett allango** | allango.net |
| **Westermann** | westermann.de |
| **C.C.BUCHNER** click & study | ccbuchner.de |
| **C.C.BUCHNER** click & teach | ccbuchner.de |
| **book2look** | book2look.com |
| **Cornelsen.ch** | cornelsen.ch |
| **kiosquemag** | kiosquemag.com |

### Legacy (hidden by default, enable with `--legacy`)
| Platform | Notes |
|---|---|
| **Scook (Cornelsen)** | Older implementation with hardcoded book list |
| **Helbling Media App** | REST API-based, downloads actual PDFs |

---

## Installation

### Option 1 — Installer (recommended, no prerequisites)

**Windows** — download and run [`ultimate-downloader-setup.exe`](https://github.com/Johni12M/ultimate-downloader/releases/latest):
- Node.js is bundled — nothing else needed
- Registers `ultimate-downloader` globally (restart terminal after install)

**Linux / macOS** — one-liner:
```bash
curl -fsSL https://raw.githubusercontent.com/Johni12M/ultimate-downloader/master/install.sh | bash
```
- Downloads Node.js v20 LTS automatically
- Installs ImageMagick, FFmpeg and mupdf-tools via apt/Homebrew (sudo required)
- Installs to `~/.local/share/ultimate-downloader`, no source code left on disk

---

### Option 2 — Manual (clone)

**Prerequisites:**
- [Node.js](https://nodejs.org/) v18+
- [ImageMagick](https://imagemagick.org/)
- [FFmpeg](https://ffmpeg.org/)
- [mupdf-tools](https://mupdf.com/) (`mutool`)

```bash
git clone --recurse-submodules https://github.com/Johni12M/ultimate-downloader.git
cd ultimate-downloader
```

> **Important:** Use `--recurse-submodules` so the bundled d4sd component is also downloaded.
> If you forgot, run: `git submodule update --init`

**Windows** — run `init.bat`:
```bat
init.bat
```

**Linux / macOS:**
```bash
chmod +x init.sh && ./init.sh
```

> **Windows note:** After running `init.bat`, you may need to restart your terminal for the global command to be available.

---

## Usage

```bash
ultimate-downloader
```

Select your platform from the interactive menu and follow the prompts. For d4sd-based platforms you will be asked for your email, password, and which books to download.

### Enable legacy downloaders

```bash
ultimate-downloader --legacy
```

Adds **Scook (Cornelsen) - legacy** and **Helbling Media App - legacy** to the menu.

### Save credentials (optional)

Create a `config.json` in the project root to skip retyping credentials:

```json
{
  "digi":      { "email": "you@example.com",  "passwd": "yourpassword" },
  "scook-d4sd":{ "email": "you@example.com",  "passwd": "yourpassword" },
  "trauner":   { "email": "you@example.com",  "passwd": "yourpassword" },
  "cornelsen": { "email": "YourDisplayName",  "passwd": "yourpassword" }
}
```

---

## Credits

| Project | Author | License |
|---|---|---|
| [d4sd](https://github.com/garzj/d4sd) | [@garzj](https://github.com/garzj) | GPL-3.0 |
| [d4sd fork](https://github.com/Johni12M/d4sd) (extended) | [@Johni12M](https://github.com/Johni12M) | GPL-3.0 |
| [EbookDownloader](https://github.com/RythenGlyth/EbookDownloader) | [@RythenGlyth](https://github.com/RythenGlyth) | MIT |
| Ultimate Downloader (this merge) | [@Johni12M](https://github.com/Johni12M) | MIT |

---

## Disclaimer

This tool is intended for **educational and personal use only**.  
Please respect the terms of service of each platform and applicable copyright laws.  
Do not use this tool to download content you do not have a license for.
