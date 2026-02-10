#!/usr/bin/env python3
"""
Pokemon Card Database Builder

Fetches all Pokemon cards from PokemonTCG.io API and builds a SQLite database
with FTS5 full-text search support for bundling with the iOS app.

Usage:
    python build_pokemon_db.py --out pokemon_cards.db --api-key YOUR_API_KEY

Requirements:
    pip install requests

Performance:
    - Full import: ~5-10 minutes
    - Database size: ~10-15MB
    - Card count: ~30,000+
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
API_BASE_URL = "https://api.pokemontcg.io/v2"
DB_VERSION = 1
SOURCE_URL = "https://pokemontcg.io"


def normalize_name(name: str) -> str:
    """
    Normalize card name for search matching.
    - Removes diacritics (é -> e, ü -> u, etc.)
    - Converts to lowercase
    - Collapses whitespace
    """
    # Remove diacritics using NFKD normalization
    nfkd = unicodedata.normalize('NFKD', name)
    ascii_only = nfkd.encode('ascii', 'ignore').decode('ascii')
    # Lowercase
    lower = ascii_only.lower()
    # Collapse whitespace
    collapsed = re.sub(r'\s+', ' ', lower).strip()
    return collapsed


def check_fts5_support(db_path: str) -> bool:
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
    # Remove existing database if present
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

    # Create main tables
    cursor.executescript("""
        -- Main cards table
        CREATE TABLE cards (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            name_normalized TEXT NOT NULL,
            set_name TEXT NOT NULL,
            set_id TEXT NOT NULL,
            card_number TEXT NOT NULL,
            image_url_small TEXT,
            rarity TEXT,
            updated_at INTEGER DEFAULT (strftime('%s', 'now'))
        );

        -- Metadata table for versioning
        CREATE TABLE meta (
            key TEXT PRIMARY KEY,
            value TEXT
        );

        -- Indexes for fast lookup
        CREATE INDEX idx_cards_set_number ON cards(set_id, card_number);
        CREATE INDEX idx_cards_name_norm ON cards(name_normalized);
        CREATE INDEX idx_cards_name_num ON cards(name_normalized, card_number);

        -- FTS5 virtual table (we'll populate it after bulk insert)
        CREATE VIRTUAL TABLE cards_fts USING fts5(
            name,
            set_name,
            card_number,
            content='cards',
            content_rowid='rowid',
            tokenize='unicode61 remove_diacritics 2'
        );

        -- Sync triggers for future updates
        CREATE TRIGGER cards_ai AFTER INSERT ON cards BEGIN
            INSERT INTO cards_fts(rowid, name, set_name, card_number)
            VALUES (NEW.rowid, NEW.name, NEW.set_name, NEW.card_number);
        END;

        CREATE TRIGGER cards_ad AFTER DELETE ON cards BEGIN
            INSERT INTO cards_fts(cards_fts, rowid, name, set_name, card_number)
            VALUES ('delete', OLD.rowid, OLD.name, OLD.set_name, OLD.card_number);
        END;

        CREATE TRIGGER cards_au AFTER UPDATE ON cards BEGIN
            INSERT INTO cards_fts(cards_fts, rowid, name, set_name, card_number)
            VALUES ('delete', OLD.rowid, OLD.name, OLD.set_name, OLD.card_number);
            INSERT INTO cards_fts(rowid, name, set_name, card_number)
            VALUES (NEW.rowid, NEW.name, NEW.set_name, NEW.card_number);
        END;
    """)

    conn.commit()
    return conn


def fetch_total_count(api_key: Optional[str] = None) -> int:
    """Fetch total card count from API."""
    headers = {"X-Api-Key": api_key} if api_key else {}
    response = requests.get(
        f"{API_BASE_URL}/cards",
        params={"pageSize": 1},
        headers=headers
    )
    response.raise_for_status()
    data = response.json()
    return data.get("totalCount", 0)


def fetch_cards_page(
    page: int,
    page_size: int,
    api_key: Optional[str] = None
) -> list[dict[str, Any]]:
    """Fetch a page of cards from the API."""
    headers = {"X-Api-Key": api_key} if api_key else {}
    response = requests.get(
        f"{API_BASE_URL}/cards",
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


def insert_cards(
    conn: sqlite3.Connection,
    cards: list[dict[str, Any]],
    use_triggers: bool = False
) -> int:
    """Insert cards into the database."""
    cursor = conn.cursor()

    # Temporarily disable triggers for bulk insert performance
    if not use_triggers:
        cursor.execute("DROP TRIGGER IF EXISTS cards_ai")
        cursor.execute("DROP TRIGGER IF EXISTS cards_ad")
        cursor.execute("DROP TRIGGER IF EXISTS cards_au")

    sql = """
        INSERT OR REPLACE INTO cards
        (id, name, name_normalized, set_name, set_id, card_number, image_url_small, rarity, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, strftime('%s', 'now'))
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

    # Recreate triggers for future updates
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


def update_metadata(
    conn: sqlite3.Connection,
    total_count: int,
    data_version: str
) -> None:
    """Update database metadata."""
    cursor = conn.cursor()

    meta = [
        ("db_version", str(DB_VERSION)),
        ("data_version", data_version),
        ("source_total_count", str(total_count)),
        ("source_url", SOURCE_URL),
        ("built_at", datetime.utcnow().isoformat())
    ]

    cursor.executemany(
        "INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)",
        meta
    )
    conn.commit()


def verify_database(conn: sqlite3.Connection) -> dict[str, Any]:
    """Verify database integrity and run sample queries."""
    cursor = conn.cursor()

    # Get card count
    cursor.execute("SELECT COUNT(*) FROM cards")
    card_count = cursor.fetchone()[0]

    # Get FTS count
    cursor.execute("SELECT COUNT(*) FROM cards_fts")
    fts_count = cursor.fetchone()[0]

    # Test exact search
    start = time.time()
    cursor.execute(
        "SELECT id, name FROM cards WHERE name_normalized = ? LIMIT 10",
        ("pikachu",)
    )
    exact_results = cursor.fetchall()
    exact_time = (time.time() - start) * 1000

    # Test FTS search
    start = time.time()
    cursor.execute("""
        SELECT c.id, c.name FROM cards c
        JOIN cards_fts fts ON c.rowid = fts.rowid
        WHERE cards_fts MATCH '"charz"*'
        LIMIT 10
    """)
    fts_results = cursor.fetchall()
    fts_time = (time.time() - start) * 1000

    return {
        "card_count": card_count,
        "fts_count": fts_count,
        "exact_search_ms": exact_time,
        "fts_search_ms": fts_time,
        "exact_results": len(exact_results),
        "fts_results": len(fts_results)
    }


def main():
    parser = argparse.ArgumentParser(
        description="Build Pokemon card SQLite database from PokemonTCG.io API"
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
        "--max-pages",
        type=int,
        default=None,
        help="Maximum pages to fetch (for testing)"
    )

    args = parser.parse_args()

    print("=" * 60, flush=True)
    print("Pokemon Card Database Builder", flush=True)
    print("=" * 60, flush=True)

    # Check FTS5 support
    print("\n[1/6] Checking FTS5 support...")
    if not check_fts5_support(args.out):
        print("ERROR: SQLite FTS5 extension not available!")
        print("Please install SQLite with FTS5 support.")
        sys.exit(1)
    print("  FTS5 support confirmed")

    # Fetch total count
    print("\n[2/6] Fetching card count from API...")
    total_count = fetch_total_count(args.api_key)
    print(f"  Total cards available: {total_count:,}")

    # Calculate pages
    page_size = min(args.page_size, 250)  # API max is 250
    total_pages = (total_count + page_size - 1) // page_size
    if args.max_pages:
        total_pages = min(total_pages, args.max_pages)
        print(f"  Limited to {total_pages} pages for testing")

    # Create database
    print(f"\n[3/6] Creating database: {args.out}")
    conn = create_database(args.out)
    print("  Schema created")

    # Fetch and insert cards
    print(f"\n[4/6] Fetching and inserting cards ({total_pages} pages)...")
    start_time = time.time()
    total_inserted = 0

    for page in range(1, total_pages + 1):
        try:
            cards = fetch_cards_page(page, page_size, args.api_key)
            inserted = insert_cards(conn, cards, use_triggers=False)
            total_inserted += inserted

            # Progress
            progress = page / total_pages * 100
            elapsed = time.time() - start_time
            eta = elapsed / page * (total_pages - page) if page > 0 else 0

            print(f"  Page {page}/{total_pages} ({progress:.1f}%) - "
                  f"{inserted} cards - ETA: {eta:.0f}s")

            # Rate limiting
            if args.sleep_ms > 0:
                time.sleep(args.sleep_ms / 1000)

        except requests.RequestException as e:
            print(f"  ERROR on page {page}: {e}")
            print("  Retrying in 5 seconds...")
            time.sleep(5)
            # Retry once
            try:
                cards = fetch_cards_page(page, page_size, args.api_key)
                inserted = insert_cards(conn, cards, use_triggers=False)
                total_inserted += inserted
            except Exception as retry_e:
                print(f"  Retry failed: {retry_e}")

    fetch_time = time.time() - start_time
    print(f"  Imported {total_inserted:,} cards in {fetch_time:.1f}s")

    # Rebuild FTS index
    print("\n[5/6] Building FTS5 search index...")
    rebuild_fts_index(conn)

    # Update metadata
    data_version = datetime.utcnow().strftime("%Y%m%d")
    update_metadata(conn, total_count, data_version)

    # Verify
    print("\n[6/6] Verifying database...")
    stats = verify_database(conn)
    print(f"  Card count: {stats['card_count']:,}")
    print(f"  FTS index count: {stats['fts_count']:,}")
    print(f"  Exact search time: {stats['exact_search_ms']:.2f}ms ({stats['exact_results']} results)")
    print(f"  FTS search time: {stats['fts_search_ms']:.2f}ms ({stats['fts_results']} results)")

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
    print(f"  Cards: {stats['card_count']:,}")
    print(f"  Data version: {data_version}")
    print(f"  Total time: {total_time:.1f}s")
    print("=" * 60)


if __name__ == "__main__":
    main()
