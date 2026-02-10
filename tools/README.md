# Pokemon Card Database Builder

This directory contains tools for building the pre-bundled Pokemon card database for CardShowPro.

## Overview

The iOS app includes a bundled SQLite database with all Pokemon cards (~30,000+) to enable instant local search on first launch. This eliminates the need for users to wait 5-10 minutes for an initial database import.

## Quick Start

```bash
# Install dependencies
pip install requests

# Build the database
python build_pokemon_db.py --out ../CardShowPro/Resources/pokemon_cards.db

# For testing with fewer cards
python build_pokemon_db.py --out test.db --max-pages 5
```

## build_pokemon_db.py

### Description

Fetches all Pokemon cards from the [PokemonTCG.io API](https://pokemontcg.io/) and creates a SQLite database with:

- All card data (name, set, number, image URL, rarity)
- FTS5 full-text search index for fast prefix matching
- Normalized names for exact matching
- Metadata for version tracking

### CLI Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--out`, `-o` | `pokemon_cards.db` | Output SQLite database path |
| `--api-key`, `-k` | None | PokemonTCG.io API key (optional, improves rate limits) |
| `--page-size` | 250 | Cards per API request (max: 250) |
| `--sleep-ms` | 100 | Delay between API requests in milliseconds |
| `--max-pages` | None | Limit pages for testing |

### API Key

While optional, using an API key improves rate limits. Get one free at:
https://dev.pokemontcg.io/

### Examples

```bash
# Full production build (5-10 minutes)
python build_pokemon_db.py \
    --out pokemon_cards.db \
    --api-key YOUR_API_KEY_HERE

# Quick test build (~1 minute)
python build_pokemon_db.py \
    --out test.db \
    --max-pages 5

# Slower build without API key
python build_pokemon_db.py \
    --out pokemon_cards.db \
    --sleep-ms 500
```

### Output

The script creates a SQLite database with:

- **~30,000+ cards** with full metadata
- **FTS5 search index** for blazing fast searches (<50ms)
- **Version metadata** for update tracking
- **Size:** ~10-15 MB

## Adding to Xcode Project

1. Build the database:
   ```bash
   python build_pokemon_db.py --out pokemon_cards.db
   ```

2. Copy to the app resources:
   ```bash
   cp pokemon_cards.db ../CardShowPro/Resources/
   ```

3. Add to Xcode:
   - Open the Xcode project
   - Drag `pokemon_cards.db` into `CardShowPro/Resources/` group
   - Ensure "Copy items if needed" is checked
   - Ensure "Add to target: CardShowPro" is checked

4. Verify in Build Phases:
   - Check that `pokemon_cards.db` appears in "Copy Bundle Resources"

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build App with Pokemon DB

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Python dependencies
        run: pip install requests

      - name: Build Pokemon Database
        run: |
          python tools/build_pokemon_db.py \
            --out CardShowPro/Resources/pokemon_cards.db \
            --api-key ${{ secrets.POKEMON_TCG_API_KEY }}

      - name: Build iOS App
        run: |
          xcodebuild -workspace CardShowPro.xcworkspace \
            -scheme CardShowPro \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            build
```

### Caching the Database

To avoid rebuilding on every CI run, cache the database:

```yaml
- name: Cache Pokemon DB
  uses: actions/cache@v4
  with:
    path: CardShowPro/Resources/pokemon_cards.db
    key: pokemon-db-${{ hashFiles('tools/build_pokemon_db.py') }}

- name: Build Pokemon Database
  if: steps.cache.outputs.cache-hit != 'true'
  run: python tools/build_pokemon_db.py --out CardShowPro/Resources/pokemon_cards.db
```

## Database Schema

### cards table

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | PokemonTCG.io card ID (e.g., "base1-4") |
| name | TEXT | Card name |
| name_normalized | TEXT | Lowercase, no diacritics |
| set_name | TEXT | Set name |
| set_id | TEXT | Set ID |
| card_number | TEXT | Card number in set |
| image_url_small | TEXT | Small image URL |
| rarity | TEXT | Card rarity |
| updated_at | INTEGER | Unix timestamp |

### meta table

| Key | Description |
|-----|-------------|
| db_version | Database schema version |
| data_version | Data version (YYYYMMDD) |
| source_total_count | Total cards at build time |
| source_url | Data source URL |
| built_at | ISO 8601 build timestamp |

### cards_fts (FTS5 virtual table)

Full-text search index on `name`, `set_name`, `card_number` for fast prefix matching.

## Troubleshooting

### "FTS5 not available"

Your Python's SQLite doesn't have FTS5 support. Solutions:

- **macOS:** Use Homebrew Python: `brew install python`
- **Linux:** Install `libsqlite3-dev` and rebuild Python
- **Windows:** Use the official Python installer

### Rate limiting

If you get 429 errors, either:
- Use an API key (free at https://dev.pokemontcg.io/)
- Increase `--sleep-ms` (e.g., `--sleep-ms 500`)

### Database too large

The full database is ~10-15 MB. If this is too large:
- Consider using `--max-pages` to include only recent sets
- Remove image URLs if not needed (saves ~2-3 MB)

## Updating the Database

To update the bundled database:

1. Rebuild with the latest data:
   ```bash
   python build_pokemon_db.py --out pokemon_cards.db
   ```

2. Replace in Xcode project
3. Increment your app version
4. Release the update

For over-the-air updates, see `DatabaseUpdater.swift` which supports downloading new databases at runtime.
