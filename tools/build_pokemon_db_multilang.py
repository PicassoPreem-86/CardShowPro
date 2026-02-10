#!/usr/bin/env python3
"""
Pokemon Card Database Builder - Multi-Language Edition

Fetches Pokemon cards from multiple sources:
- PokemonTCG.io API (English cards with pricing)
- TCGdex API (Japanese cards and other languages)

Creates a unified SQLite database with FTS5 full-text search support.

Usage:
    python build_pokemon_db_multilang.py --out pokemon_cards.db --api-key YOUR_API_KEY

Requirements:
    pip install requests
"""

import argparse
import json
import re
import sqlite3
import sys
import time
import unicodedata
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

try:
    import requests
except ImportError:
    print("Error: 'requests' package required. Install with: pip install requests")
    sys.exit(1)


# Constants
POKEMONTCG_BASE_URL = "https://api.pokemontcg.io/v2"
TCGDEX_BASE_URL = "https://api.tcgdex.net/v2"
DB_VERSION = 2  # Bumped for multi-language support
SOURCE_URL = "https://pokemontcg.io"


def normalize_name(name: str) -> str:
    """
    Normalize card name for search matching.
    - Removes diacritics (é -> e, ü -> u, etc.)
    - Converts to lowercase
    - Collapses whitespace
    - Keeps Japanese characters as-is (hiragana, katakana, kanji)
    """
    # For Japanese text, just lowercase and collapse whitespace
    # Check if contains Japanese characters
    has_japanese = any('\u3040' <= c <= '\u30ff' or '\u4e00' <= c <= '\u9fff' for c in name)

    if has_japanese:
        # Just collapse whitespace for Japanese
        return re.sub(r'\s+', ' ', name).strip()

    # For non-Japanese: remove diacritics
    nfkd = unicodedata.normalize('NFKD', name)
    ascii_only = nfkd.encode('ascii', 'ignore').decode('ascii')
    lower = ascii_only.lower()
    collapsed = re.sub(r'\s+', ' ', lower).strip()
    return collapsed


def check_fts5_support() -> bool:
    """Check if SQLite has FTS5 support."""
    conn = sqlite3.connect(":memory:")
    cursor = conn.cursor()
    try:
        cursor.execute("CREATE VIRTUAL TABLE test_fts USING fts5(content)")
        cursor.execute("DROP TABLE test_fts")
        conn.close()
        return True
    except sqlite3.OperationalError:
        conn.close()
        return False


def create_database(db_path: str) -> sqlite3.Connection:
    """Create a new SQLite database with schema."""
    path = Path(db_path)
    if path.exists():
        path.unlink()

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Set pragmas for performance
    cursor.executescript("""
        PRAGMA journal_mode=WAL;
        PRAGMA synchronous=NORMAL;
        PRAGMA temp_store=MEMORY;
        PRAGMA cache_size=-64000;
    """)

    # Create main tables with language support
    cursor.executescript("""
        -- Main cards table with language column
        CREATE TABLE cards (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            name_normalized TEXT NOT NULL,
            set_name TEXT NOT NULL,
            set_id TEXT NOT NULL,
            card_number TEXT NOT NULL,
            image_url_small TEXT,
            rarity TEXT,
            language TEXT NOT NULL DEFAULT 'en',
            source TEXT NOT NULL DEFAULT 'pokemontcg',
            updated_at INTEGER DEFAULT (strftime('%s', 'now'))
        );

        -- Metadata table for versioning
        CREATE TABLE meta (
            key TEXT PRIMARY KEY,
            value TEXT
        );

        -- Indexes for fast lookup
        CREATE INDEX idx_cards_language ON cards(language);
        CREATE INDEX idx_cards_set_number ON cards(set_id, card_number);
        CREATE INDEX idx_cards_name_norm ON cards(name_normalized);
        CREATE INDEX idx_cards_name_lang ON cards(name_normalized, language);

        -- FTS5 virtual table (populated after bulk insert)
        CREATE VIRTUAL TABLE cards_fts USING fts5(
            name,
            set_name,
            card_number,
            content='cards',
            content_rowid='rowid',
            tokenize='unicode61 remove_diacritics 2'
        );
    """)

    conn.commit()
    return conn


def fetch_pokemontcg_count(api_key: Optional[str] = None) -> int:
    """Fetch total card count from PokemonTCG.io API."""
    headers = {"X-Api-Key": api_key} if api_key else {}
    response = requests.get(
        f"{POKEMONTCG_BASE_URL}/cards",
        params={"pageSize": 1},
        headers=headers
    )
    response.raise_for_status()
    data = response.json()
    return data.get("totalCount", 0)


def fetch_pokemontcg_page(
    page: int,
    page_size: int,
    api_key: Optional[str] = None
) -> list[dict[str, Any]]:
    """Fetch a page of cards from PokemonTCG.io API."""
    headers = {"X-Api-Key": api_key} if api_key else {}
    response = requests.get(
        f"{POKEMONTCG_BASE_URL}/cards",
        params={
            "page": page,
            "pageSize": page_size,
            "orderBy": "set.releaseDate"
        },
        headers=headers
    )
    response.raise_for_status()
    data = response.json()
    return data.get("data", [])


def fetch_tcgdex_sets(language: str = "ja") -> list[dict[str, Any]]:
    """Fetch all sets from TCGdex API."""
    response = requests.get(f"{TCGDEX_BASE_URL}/{language}/sets")
    response.raise_for_status()
    return response.json()


def fetch_tcgdex_set_cards(set_id: str, language: str = "ja") -> list[dict[str, Any]]:
    """Fetch all cards in a set from TCGdex API."""
    response = requests.get(f"{TCGDEX_BASE_URL}/{language}/sets/{set_id}")
    if response.status_code == 404:
        return []
    response.raise_for_status()
    data = response.json()
    return data.get("cards", [])


def insert_pokemontcg_cards(conn: sqlite3.Connection, cards: list[dict[str, Any]]) -> int:
    """Insert PokemonTCG.io cards into the database."""
    cursor = conn.cursor()

    sql = """
        INSERT OR REPLACE INTO cards
        (id, name, name_normalized, set_name, set_id, card_number, image_url_small, rarity, language, source, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'en', 'pokemontcg', strftime('%s', 'now'))
    """

    inserted = 0
    for card in cards:
        try:
            name = card.get("name", "")
            set_info = card.get("set", {})
            images = card.get("images", {})

            cursor.execute(sql, (
                card.get("id", ""),
                name,
                normalize_name(name),
                set_info.get("name", ""),
                set_info.get("id", ""),
                card.get("number", ""),
                images.get("small"),
                card.get("rarity")
            ))
            inserted += 1
        except Exception as e:
            print(f"  Warning: Failed to insert card {card.get('id', 'unknown')}: {e}")

    conn.commit()
    return inserted


def insert_tcgdex_cards(
    conn: sqlite3.Connection,
    cards: list[dict[str, Any]],
    set_name: str,
    set_id: str,
    language: str
) -> int:
    """Insert TCGdex cards into the database."""
    cursor = conn.cursor()

    sql = """
        INSERT OR REPLACE INTO cards
        (id, name, name_normalized, set_name, set_id, card_number, image_url_small, rarity, language, source, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'tcgdex', strftime('%s', 'now'))
    """

    inserted = 0
    for card in cards:
        try:
            name = card.get("name", "")
            card_id = card.get("id", "")
            local_id = card.get("localId", "")
            image_base = card.get("image", "")
            image_url = f"{image_base}/low.webp" if image_base else None

            # Prefix ID with language to avoid collisions
            unique_id = f"{language}_{card_id}"

            cursor.execute(sql, (
                unique_id,
                name,
                normalize_name(name),
                set_name,
                set_id,
                local_id,
                image_url,
                None,  # TCGdex doesn't include rarity in list endpoint
                language
            ))
            inserted += 1
        except Exception as e:
            print(f"  Warning: Failed to insert card {card.get('id', 'unknown')}: {e}")

    conn.commit()
    return inserted


def rebuild_fts_index(conn: sqlite3.Connection) -> None:
    """Rebuild the FTS5 index from scratch."""
    cursor = conn.cursor()

    print("Rebuilding FTS5 index...")
    start = time.time()

    # Drop existing FTS table and triggers
    cursor.executescript("""
        DROP TRIGGER IF EXISTS cards_ai;
        DROP TRIGGER IF EXISTS cards_ad;
        DROP TRIGGER IF EXISTS cards_au;
        DROP TABLE IF EXISTS cards_fts;
    """)

    # Recreate FTS table
    cursor.execute("""
        CREATE VIRTUAL TABLE cards_fts USING fts5(
            name,
            set_name,
            card_number,
            content='cards',
            content_rowid='rowid',
            tokenize='unicode61 remove_diacritics 2'
        )
    """)

    # Populate FTS index
    cursor.execute("""
        INSERT INTO cards_fts(rowid, name, set_name, card_number)
        SELECT rowid, name, set_name, card_number FROM cards
    """)

    # Recreate triggers
    cursor.executescript("""
        CREATE TRIGGER IF NOT EXISTS cards_ai AFTER INSERT ON cards BEGIN
            INSERT INTO cards_fts(rowid, name, set_name, card_number)
            VALUES (NEW.rowid, NEW.name, NEW.set_name, NEW.card_number);
        END;

        CREATE TRIGGER IF NOT EXISTS cards_ad AFTER DELETE ON cards BEGIN
            INSERT INTO cards_fts(cards_fts, rowid, name, set_name, card_number)
            VALUES ('delete', OLD.rowid, OLD.name, OLD.set_name, OLD.card_number);
        END;

        CREATE TRIGGER IF NOT EXISTS cards_au AFTER UPDATE ON cards BEGIN
            INSERT INTO cards_fts(cards_fts, rowid, name, set_name, card_number)
            VALUES ('delete', OLD.rowid, OLD.name, OLD.set_name, OLD.card_number);
            INSERT INTO cards_fts(rowid, name, set_name, card_number)
            VALUES (NEW.rowid, NEW.name, NEW.set_name, NEW.card_number);
        END;
    """)

    conn.commit()
    elapsed = time.time() - start
    print(f"FTS5 index rebuilt in {elapsed:.2f}s")


def update_metadata(conn: sqlite3.Connection, en_count: int, ja_count: int, data_version: str, zh_count: int = 0) -> None:
    """Update database metadata."""
    cursor = conn.cursor()

    meta = [
        ("db_version", str(DB_VERSION)),
        ("data_version", data_version),
        ("english_card_count", str(en_count)),
        ("japanese_card_count", str(ja_count)),
        ("chinese_card_count", str(zh_count)),
        ("total_card_count", str(en_count + ja_count + zh_count)),
        ("source_url", SOURCE_URL),
        ("built_at", datetime.utcnow().isoformat()),
        ("languages", "en,ja,zh-tw")
    ]

    cursor.executemany(
        "INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)",
        meta
    )
    conn.commit()


def verify_database(conn: sqlite3.Connection) -> dict[str, Any]:
    """Verify database integrity and run sample queries."""
    cursor = conn.cursor()

    # Get counts by language
    cursor.execute("SELECT language, COUNT(*) FROM cards GROUP BY language")
    lang_counts = dict(cursor.fetchall())

    # Get total count
    cursor.execute("SELECT COUNT(*) FROM cards")
    total_count = cursor.fetchone()[0]

    # Get FTS count
    cursor.execute("SELECT COUNT(*) FROM cards_fts")
    fts_count = cursor.fetchone()[0]

    # Test English search
    start = time.time()
    cursor.execute(
        "SELECT id, name FROM cards WHERE name_normalized = ? AND language = 'en' LIMIT 10",
        ("pikachu",)
    )
    en_results = cursor.fetchall()
    en_time = (time.time() - start) * 1000

    # Test Japanese search
    start = time.time()
    cursor.execute(
        "SELECT id, name FROM cards WHERE name LIKE ? AND language = 'ja' LIMIT 10",
        ("%リザードン%",)
    )
    ja_results = cursor.fetchall()
    ja_time = (time.time() - start) * 1000

    # Test Chinese search
    start = time.time()
    cursor.execute(
        "SELECT id, name FROM cards WHERE name LIKE ? AND language = 'zh-tw' LIMIT 10",
        ("%皮卡丘%",)
    )
    zh_results = cursor.fetchall()
    zh_time = (time.time() - start) * 1000

    # Test FTS search
    start = time.time()
    cursor.execute("""
        SELECT c.id, c.name, c.language FROM cards c
        JOIN cards_fts fts ON c.rowid = fts.rowid
        WHERE cards_fts MATCH '"pikachu"*'
        LIMIT 10
    """)
    fts_results = cursor.fetchall()
    fts_time = (time.time() - start) * 1000

    return {
        "total_count": total_count,
        "english_count": lang_counts.get("en", 0),
        "japanese_count": lang_counts.get("ja", 0),
        "chinese_count": lang_counts.get("zh-tw", 0),
        "fts_count": fts_count,
        "en_search_ms": en_time,
        "ja_search_ms": ja_time,
        "zh_search_ms": zh_time,
        "fts_search_ms": fts_time,
        "en_results": len(en_results),
        "ja_results": len(ja_results),
        "zh_results": len(zh_results),
        "fts_results": len(fts_results)
    }


def main():
    parser = argparse.ArgumentParser(
        description="Build Pokemon card SQLite database from PokemonTCG.io and TCGdex APIs"
    )
    parser.add_argument(
        "--out", "-o",
        default="pokemon_cards.db",
        help="Output SQLite database path (default: pokemon_cards.db)"
    )
    parser.add_argument(
        "--api-key", "-k",
        default=None,
        help="PokemonTCG.io API key (optional, improves rate limits)"
    )
    parser.add_argument(
        "--page-size",
        type=int,
        default=250,
        help="Cards per API request (default: 250, max: 250)"
    )
    parser.add_argument(
        "--sleep-ms",
        type=int,
        default=100,
        help="Delay between API requests in milliseconds (default: 100)"
    )
    parser.add_argument(
        "--skip-english",
        action="store_true",
        help="Skip English cards (for testing Japanese only)"
    )
    parser.add_argument(
        "--skip-japanese",
        action="store_true",
        help="Skip Japanese cards"
    )
    parser.add_argument(
        "--skip-chinese",
        action="store_true",
        help="Skip Chinese (Traditional) cards"
    )
    parser.add_argument(
        "--max-sets",
        type=int,
        default=None,
        help="Maximum sets to fetch per language (for testing)"
    )

    args = parser.parse_args()

    print("=" * 60, flush=True)
    print("Pokemon Card Database Builder (Multi-Language)", flush=True)
    print("=" * 60, flush=True)

    # Check FTS5 support
    print("\n[1/8] Checking FTS5 support...")
    if not check_fts5_support():
        print("ERROR: SQLite FTS5 extension not available!")
        sys.exit(1)
    print("  FTS5 support confirmed")

    # Create database
    print(f"\n[2/8] Creating database: {args.out}")
    conn = create_database(args.out)
    print("  Schema created")

    total_english = 0
    total_japanese = 0
    total_chinese = 0
    start_time = time.time()

    # Fetch English cards from PokemonTCG.io
    if not args.skip_english:
        print("\n[3/8] Fetching English cards from PokemonTCG.io...")

        en_count = fetch_pokemontcg_count(args.api_key)
        print(f"  Total English cards available: {en_count:,}")

        page_size = min(args.page_size, 250)
        total_pages = (en_count + page_size - 1) // page_size

        en_start = time.time()
        for page in range(1, total_pages + 1):
            try:
                cards = fetch_pokemontcg_page(page, page_size, args.api_key)
                inserted = insert_pokemontcg_cards(conn, cards)
                total_english += inserted

                progress = page / total_pages * 100
                elapsed = time.time() - en_start
                eta = elapsed / page * (total_pages - page) if page > 0 else 0

                print(f"  Page {page}/{total_pages} ({progress:.1f}%) - {inserted} cards - ETA: {eta:.0f}s")

                if args.sleep_ms > 0:
                    time.sleep(args.sleep_ms / 1000)

            except requests.RequestException as e:
                print(f"  ERROR on page {page}: {e}")
                time.sleep(5)
                try:
                    cards = fetch_pokemontcg_page(page, page_size, args.api_key)
                    inserted = insert_pokemontcg_cards(conn, cards)
                    total_english += inserted
                except Exception as retry_e:
                    print(f"  Retry failed: {retry_e}")

        print(f"  Imported {total_english:,} English cards")
    else:
        print("\n[3/8] Skipping English cards")

    # Fetch Japanese cards from TCGdex
    if not args.skip_japanese:
        print("\n[4/8] Fetching Japanese cards from TCGdex...")

        try:
            ja_sets = fetch_tcgdex_sets("ja")
            print(f"  Found {len(ja_sets)} Japanese sets")

            if args.max_sets:
                ja_sets = ja_sets[:args.max_sets]
                print(f"  Limited to {len(ja_sets)} sets for testing")

            ja_start = time.time()
            for i, set_info in enumerate(ja_sets, 1):
                set_id = set_info.get("id", "")
                set_name = set_info.get("name", "")

                try:
                    cards = fetch_tcgdex_set_cards(set_id, "ja")
                    if cards:
                        inserted = insert_tcgdex_cards(conn, cards, set_name, set_id, "ja")
                        total_japanese += inserted

                    progress = i / len(ja_sets) * 100
                    elapsed = time.time() - ja_start
                    eta = elapsed / i * (len(ja_sets) - i) if i > 0 else 0

                    print(f"  Set {i}/{len(ja_sets)} ({progress:.1f}%) - {set_name}: {len(cards)} cards - ETA: {eta:.0f}s")

                    # Rate limit for TCGdex
                    time.sleep(0.05)

                except Exception as e:
                    print(f"  ERROR on set {set_id}: {e}")

            print(f"  Imported {total_japanese:,} Japanese cards")

        except Exception as e:
            print(f"  ERROR fetching Japanese sets: {e}")
    else:
        print("\n[4/8] Skipping Japanese cards")

    # Fetch Chinese (Traditional) cards from TCGdex
    if not args.skip_chinese:
        print("\n[5/8] Fetching Chinese (Traditional) cards from TCGdex...")

        try:
            zh_sets = fetch_tcgdex_sets("zh-tw")
            print(f"  Found {len(zh_sets)} Chinese sets")

            if args.max_sets:
                zh_sets = zh_sets[:args.max_sets]
                print(f"  Limited to {len(zh_sets)} sets for testing")

            zh_start = time.time()
            for i, set_info in enumerate(zh_sets, 1):
                set_id = set_info.get("id", "")
                set_name = set_info.get("name", "")

                try:
                    cards = fetch_tcgdex_set_cards(set_id, "zh-tw")
                    if cards:
                        inserted = insert_tcgdex_cards(conn, cards, set_name, set_id, "zh-tw")
                        total_chinese += inserted

                    progress = i / len(zh_sets) * 100
                    elapsed = time.time() - zh_start
                    eta = elapsed / i * (len(zh_sets) - i) if i > 0 else 0

                    print(f"  Set {i}/{len(zh_sets)} ({progress:.1f}%) - {set_name}: {len(cards)} cards - ETA: {eta:.0f}s")

                    # Rate limit for TCGdex
                    time.sleep(0.05)

                except Exception as e:
                    print(f"  ERROR on set {set_id}: {e}")

            print(f"  Imported {total_chinese:,} Chinese cards")

        except Exception as e:
            print(f"  ERROR fetching Chinese sets: {e}")
    else:
        print("\n[5/8] Skipping Chinese cards")

    # Rebuild FTS index
    print("\n[6/8] Building FTS5 search index...")
    rebuild_fts_index(conn)

    # Update metadata
    print("\n[7/8] Updating metadata...")
    data_version = datetime.utcnow().strftime("%Y%m%d")
    update_metadata(conn, total_english, total_japanese, data_version, total_chinese)
    print("  Metadata updated")

    # Verify
    print("\n[8/8] Verifying database...")
    stats = verify_database(conn)
    print(f"  Total cards: {stats['total_count']:,}")
    print(f"  English cards: {stats['english_count']:,}")
    print(f"  Japanese cards: {stats['japanese_count']:,}")
    print(f"  Chinese cards: {stats['chinese_count']:,}")
    print(f"  FTS index count: {stats['fts_count']:,}")
    print(f"  English search: {stats['en_search_ms']:.2f}ms ({stats['en_results']} results)")
    print(f"  Japanese search: {stats['ja_search_ms']:.2f}ms ({stats['ja_results']} results)")
    print(f"  Chinese search: {stats['zh_search_ms']:.2f}ms ({stats['zh_results']} results)")
    print(f"  FTS search: {stats['fts_search_ms']:.2f}ms ({stats['fts_results']} results)")

    # Close and optimize
    conn.execute("VACUUM")
    conn.close()

    # Final stats
    db_size = Path(args.out).stat().st_size / (1024 * 1024)
    total_time = time.time() - start_time

    print("\n" + "=" * 60)
    print("BUILD COMPLETE")
    print("=" * 60)
    print(f"  Database: {args.out}")
    print(f"  Size: {db_size:.2f} MB")
    print(f"  English cards: {total_english:,}")
    print(f"  Japanese cards: {total_japanese:,}")
    print(f"  Chinese cards: {total_chinese:,}")
    print(f"  Total cards: {total_english + total_japanese + total_chinese:,}")
    print(f"  Data version: {data_version}")
    print(f"  Total time: {total_time:.1f}s")
    print("=" * 60)


if __name__ == "__main__":
    main()
