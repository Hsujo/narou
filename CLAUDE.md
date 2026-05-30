# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **patched fork** of [whiteleaf7/narou](https://github.com/whiteleaf7/narou) (v3.9.1), a Japanese web novel downloader/converter/manager. The upstream is unmaintained since Oct 2024; this fork applies 11 community PRs fixing site scraping breakages and dependency issues, plus Docker support.

**Supported sites**: syosetu.com, noc.syosetu.com, mnlt.syosetu.com, mid.syosetu.com, syosetu.org (Hameln), kakuyomu.jp, akatsuki-novels.com, mai-net.net (Arcadia)

## Build & Test Commands

```bash
# Build the Ruby gem (from project root)
gem build narou.gemspec

# Run tests
bundle exec rspec

# Docker build and run
cp .env.example .env   # edit proxy credentials first
docker compose build
docker compose up -d
docker compose exec narou narou <subcommand>
```

The `.env` file is gitignored and must contain:
```
HTTP_PROXY=http://user:pass@172.17.0.1:7890
HTTPS_PROXY=http://user:pass@172.17.0.1:7890
```

## Architecture

**Dual-mode operation**: CLI (console) and WEB UI (Sinatra-based browser interface). Both share the same core engine.

### Entry Points
- `narou.rb` → `CommandLine.run!` dispatches subcommands (download, update, convert, web, etc.)
- `bin/narou` — shebang entry for running from source
- The gem installs `narou` as a system command

### Core Pipeline
```
Site scraping → Download text → Convert/format → EPUB generation (AozoraEpub3) → Optional: send to device
```

### Key Modules

| Path | Purpose |
|------|---------|
| `lib/command/*.rb` | 18+ CLI subcommands (download, update, convert, web, send, list, diff, etc.) |
| `lib/downloader.rb` | Fetches novel chapters from websites |
| `lib/novelconverter.rb` | Text formatting, vertical-writing conversion, EPUB generation via AozoraEpub3 |
| `lib/web/` | Sinatra WEB UI (appserver.rb, pushserver.rb for WebSocket, HAML views) |
| `webnovel/*.yaml` | **Site-specific scraping definitions** — YAML-driven selectors, regex patterns, pagination |
| `lib/sitesetting.rb` | Parses YAML site definitions into scraping rules |
| `lib/database.rb` | YAML-based novel metadata storage (toc.yaml per novel) |
| `lib/novelsetting.rb` | Per-novel settings (INI-like format) |
| `lib/inventory.rb` | YAML config persistence with `:global` (`.narousetting/`) and `:local` (`.narou/`) scopes |
| `lib/aozoraepub3.rb` | AozoraEpub3 resource management (CSS, fonts, ini, chuki_tag); detects `honke` vs `denshokyo` format |
| `lib/aozora.rb` | AozoraEpub3 type detection (original vs denshokyo), provides structured path configs |
| `lib/device.rb` + `lib/device/` | Device abstraction (Kindle, Kobo, EPUB, iBooks) |
| `preset/` | Default configs, fonts (DMincho.ttf), CSS templates for EPUB styling |
| `template/` | ERB templates (novel.txt.erb, converter.rb.erb, etc.) |

### Scraping Architecture
Each supported site has a YAML file in `webnovel/` defining:
- URL patterns, encoding, cookie requirements
- TOC extraction (subtitles regex, pagination patterns)
- Novel info extraction (title, author, synopsis selectors)
- Pre/post-processing code blocks (`code: eval:` with embedded Ruby)
- Site versioning for tracking format changes

### Data Flow
```
narou init → creates .narou/ (local) and .narousetting/ (global) dirs
narou download <id> → fetches TOC → downloads chapters → saves to 小説データ/<site>/<id>/
narou update → checks all novels for new/revised chapters → re-downloads
narou convert → text formatting → AozoraEpub3 Java process → EPUB/MOBI output
```

## Docker Notes

- **Network mode**: `bridge` — required so the container can reach the host's mihomo proxy at `172.17.0.1:7890`
- **Security**: ports mapped to `127.0.0.1` only in docker-compose.yml. The application internally binds `0.0.0.0` (required for Docker port forwarding), but UFW and Docker's port mapping restrict external access
- **Workspace**: `./workspace:/novel` bind mount — persists `.narou/` and `.narousetting/` configs
- **Novel data**: `/home/xutao/repository/NarouTranslator/小説データ:/novel/小説データ` bind mount — shares existing novels downloaded from Windows
- **First-run**: `docker-entrypoint.sh` checks `database.yaml` to detect imported config vs fresh install. `mkdir -p .narousetting` must run BEFORE `narou init`, otherwise narou falls back to `~/.narousetting/` and global settings are lost
- **AozoraEpub3**: Copied into the image at `/opt/AozoraEpub3/` from the local NarouTranslator project during build
- **WebSocket**: PushServer runs on port 33001 for real-time log streaming. If VS Code only forwards 33000, the JS Console falls back to AJAX polling every 2s

## Gem Dependency Notes

- `erubis` replaced with `erubi` (PR #444) — tilt >= 2.5.0 dropped Erubis support
- `sinatra` constraint widened to `>= 2.0.8.1, < 4` to avoid conflicts
- The `narou.gemspec` uses `git ls-files` to determine packaged files — requires git available when building

## Applied Community PRs

Site scraping fixes (#441, #442, #446, #452), Erubi replacement (#444), Sinatra version (#408), converter fixes (#440, #454), AozoraEpub3 denshokyo support (#420, #439). Full list in the commit log of the `patched` branch.
