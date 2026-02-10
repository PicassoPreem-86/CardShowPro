#!/usr/bin/env python3
"""
Pokemon Card Database Builder V2 - Species-Normalized Multilingual Schema

Builds a species-aware database that enables cross-language search:
- Search "Charizard" → finds リザードン (Japanese) cards
- Search "Rizaadon" (romaji) → finds リザードン
- Hybrid denormalized schema for <50ms search performance

Architecture:
- species: Canonical Pokémon (1,010 rows)
- species_aliases: Multilingual names + romaji (10,100+ rows)
- printings: Card instances (32,733 rows)
- printing_species_map: Link cards to species (32,733+ rows)

Usage:
    python build_pokemon_db_v2.py --out pokemon_cards.db --api-key YOUR_API_KEY

Requirements:
    pip install requests
"""

import argparse
import json
import re
import sqlite3
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Tuple, Optional

# Import our modules
from species_fetcher import SpeciesFetcher, Species, SpeciesName
from romanization import Romanizer
from species_mapper import SpeciesMapper, CardSpeciesMapping

try:
    import requests
except ImportError:
    print("Error: 'requests' package required. Install with: pip install requests")
    sys.exit(1)


# Constants
POKEMONTCG_BASE_URL = "https://api.pokemontcg.io/v2"
TCGDEX_BASE_URL = "https://api.tcgdex.net/v2"
DB_VERSION = 2  # V2 with species normalization


class DatabaseBuilder:
    """Orchestrates the multi-phase database build process"""

    def __init__(self, output_path: str, api_key: Optional[str] = None):
        self.output_path = output_path
        self.api_key = api_key
        self.conn: Optional[sqlite3.Connection] = None
        self.species_fetcher = SpeciesFetcher()
        self.romanizer = Romanizer()

        # Stats
        self.stats = {
            'species_count': 0,
            'alias_count': 0,
            'printing_count': 0,
            'mapping_count': 0,
            'start_time': time.time(),
        }

    def build(self):
        """Execute the full build pipeline"""
        print("=" * 70)
        print("Pokemon Card Database Builder V2 - Species-Normalized Schema")
        print("=" * 70)

        try:
            # Phase 1: Create database and schema
            print("\n[Phase 1/5] Creating database and schema...")
            self.create_database()

            # Phase 2: Fetch and insert species
            print("\n[Phase 2/5] Fetching species from PokéAPI...")
            species_list = self.fetch_species()
            self.insert_species(species_list)

            # Phase 3: Generate and insert aliases
            print("\n[Phase 3/5] Generating multilingual aliases...")
            self.generate_aliases(species_list)

            # Phase 4: Fetch and insert card printings
            print("\n[Phase 4/5] Fetching card printings...")
            cards = self.fetch_cards()
            self.insert_printings(cards)

            # Phase 5: Map printings to species
            print("\n[Phase 5/5] Mapping cards to species...")
            self.map_printings_to_species(cards, species_list)

            # Finalize
            self.finalize_database()

            # Print summary
            self.print_summary()

        except Exception as e:
            print(f"\nError: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)
        finally:
            if self.conn:
                self.conn.close()

    def create_database(self):
        """Create database file and schema"""
        # Delete existing database
        path = Path(self.output_path)
        if path.exists():
            path.unlink()
            print(f"  Deleted existing database: {self.output_path}")

        # Create new database
        self.conn = sqlite3.connect(self.output_path)
        cursor = self.conn.cursor()

        # Performance pragmas
        cursor.executescript("""
            PRAGMA journal_mode=WAL;
            PRAGMA synchronous=NORMAL;
            PRAGMA temp_store=MEMORY;
            PRAGMA cache_size=-64000;
        """)

        # Create v2 schema
        cursor.executescript("""
            -- Canonical Pokémon species
            CREATE TABLE species (
                species_id TEXT PRIMARY KEY,
                canonical_name TEXT NOT NULL,
                card_type TEXT NOT NULL DEFAULT 'pokemon',
                national_dex_number INTEGER,
                created_at INTEGER DEFAULT (strftime('%s', 'now'))
            );

            -- All searchable names (multilingual + romanizations)
            CREATE TABLE species_aliases (
                alias_id INTEGER PRIMARY KEY AUTOINCREMENT,
                species_id TEXT NOT NULL,
                alias TEXT NOT NULL,
                alias_normalized TEXT NOT NULL,
                language TEXT NOT NULL,
                is_canonical BOOLEAN DEFAULT 0,
                FOREIGN KEY (species_id) REFERENCES species(species_id) ON DELETE CASCADE
            );

            -- Card printings (specific instances)
            CREATE TABLE printings (
                printing_id TEXT PRIMARY KEY,
                set_id TEXT NOT NULL,
                set_name TEXT NOT NULL,
                card_number TEXT NOT NULL,
                language TEXT NOT NULL,
                image_url_small TEXT,
                rarity TEXT,
                source TEXT NOT NULL DEFAULT 'pokemontcg',
                updated_at INTEGER DEFAULT (strftime('%s', 'now'))
            );

            -- Link printings to species (many-to-many)
            CREATE TABLE printing_species_map (
                printing_id TEXT NOT NULL,
                species_id TEXT NOT NULL,
                is_primary BOOLEAN DEFAULT 1,
                PRIMARY KEY (printing_id, species_id),
                FOREIGN KEY (printing_id) REFERENCES printings(printing_id) ON DELETE CASCADE,
                FOREIGN KEY (species_id) REFERENCES species(species_id) ON DELETE CASCADE
            );

            -- Indexes for performance
            CREATE INDEX idx_species_canonical ON species(canonical_name);
            CREATE INDEX idx_species_aliases_norm ON species_aliases(alias_normalized, language);
            CREATE INDEX idx_species_aliases_species ON species_aliases(species_id);
            CREATE INDEX idx_printings_set_number ON printings(set_id, card_number);
            CREATE INDEX idx_printings_language ON printings(language);
            CREATE INDEX idx_printing_species_map_species ON printing_species_map(species_id);
            CREATE INDEX idx_printing_species_map_printing ON printing_species_map(printing_id);

            -- FTS5 for fast alias search
            CREATE VIRTUAL TABLE species_aliases_fts USING fts5(
                alias,
                content='species_aliases',
                content_rowid='alias_id',
                tokenize='unicode61 remove_diacritics 2'
            );

            -- FTS5 for set/number search
            CREATE VIRTUAL TABLE printings_fts USING fts5(
                set_name,
                card_number,
                content='printings',
                content_rowid='rowid',
                tokenize='unicode61 remove_diacritics 2'
            );

            -- Metadata table
            CREATE TABLE meta (
                key TEXT PRIMARY KEY,
                value TEXT
            );

            -- Insert metadata
            INSERT INTO meta (key, value) VALUES
                ('schema_version', '2'),
                ('db_version', '2'),
                ('build_date', datetime('now')),
                ('source', 'pokemontcg.io + tcgdex');
        """)

        self.conn.commit()
        print(f"  Created database: {self.output_path}")
        print("  Schema version: 2 (species-normalized)")

    def fetch_species(self) -> List[Species]:
        """Fetch all Pokémon species from PokéAPI"""
        # Fetch Pokémon (National Dex 1-1025)
        species_list = self.species_fetcher.fetch_all_species(max_id=1025)

        # Add manual entries for common trainers/energy
        # These will be mapped later if cards reference them
        # For now, just focus on Pokémon species

        print(f"  Fetched {len(species_list)} species")
        return species_list

    def insert_species(self, species_list: List[Species]):
        """Insert species into database"""
        cursor = self.conn.cursor()

        for species in species_list:
            cursor.execute("""
                INSERT INTO species (species_id, canonical_name, card_type, national_dex_number)
                VALUES (?, ?, ?, ?)
            """, (
                species.species_id,
                species.canonical_name,
                species.card_type,
                species.national_dex_number
            ))

        self.conn.commit()
        self.stats['species_count'] = len(species_list)
        print(f"  Inserted {len(species_list)} species")

    def generate_aliases(self, species_list: List[Species]):
        """Generate and insert all searchable aliases"""
        cursor = self.conn.cursor()
        alias_count = 0

        for species in species_list:
            # Insert official names from PokéAPI
            for name_entry in species.names:
                # Insert original name
                cursor.execute("""
                    INSERT INTO species_aliases (species_id, alias, alias_normalized, language, is_canonical)
                    VALUES (?, ?, ?, ?, ?)
                """, (
                    species.species_id,
                    name_entry.name,
                    self._normalize_text(name_entry.name),
                    name_entry.language,
                    name_entry.is_canonical
                ))
                alias_count += 1

                # Generate romaji variants for Japanese names
                if name_entry.language == 'ja' and self._has_katakana(name_entry.name):
                    romaji_variants = self.romanizer.romanize_with_variants(name_entry.name)

                    for variant in romaji_variants:
                        cursor.execute("""
                            INSERT INTO species_aliases (species_id, alias, alias_normalized, language, is_canonical)
                            VALUES (?, ?, ?, ?, ?)
                        """, (
                            species.species_id,
                            variant,
                            variant.lower(),
                            'ja-Latn',  # Japanese romanization
                            False
                        ))
                        alias_count += 1

        self.conn.commit()
        self.stats['alias_count'] = alias_count
        print(f"  Generated {alias_count} searchable aliases")

    def fetch_cards(self) -> List[Dict]:
        """Fetch all cards from PokemonTCG.io and TCGdex"""
        all_cards = []

        # Fetch English cards from PokemonTCG.io
        print("\n  Fetching from PokemonTCG.io (English)...")
        pokemontcg_cards = self._fetch_pokemontcg_cards()
        all_cards.extend(pokemontcg_cards)
        print(f"    Fetched {len(pokemontcg_cards)} English cards")

        # Fetch Japanese and Chinese cards from TCGdex
        print("\n  Fetching from TCGdex (Japanese, Chinese)...")
        tcgdex_cards = self._fetch_tcgdex_cards()
        all_cards.extend(tcgdex_cards)
        print(f"    Fetched {len(tcgdex_cards)} non-English cards")

        print(f"\n  Total cards fetched: {len(all_cards)}")
        return all_cards

    def _fetch_pokemontcg_cards(self) -> List[Dict]:
        """Fetch cards from PokemonTCG.io API"""
        headers = {}
        if self.api_key:
            headers['X-Api-Key'] = self.api_key

        cards = []
        page = 1
        page_size = 250

        while True:
            url = f"{POKEMONTCG_BASE_URL}/cards?page={page}&pageSize={page_size}"

            try:
                response = requests.get(url, headers=headers, timeout=30)
                response.raise_for_status()
                data = response.json()

                page_cards = data.get('data', [])
                if not page_cards:
                    break

                for card in page_cards:
                    cards.append({
                        'id': card['id'],
                        'name': card['name'],
                        'set_id': card['set']['id'],
                        'set_name': card['set']['name'],
                        'card_number': card['number'],
                        'language': 'en',  # PokemonTCG.io is English only
                        'image_url_small': card['images'].get('small'),
                        'rarity': card.get('rarity'),
                        'source': 'pokemontcg'
                    })

                page += 1
                time.sleep(0.1)  # Rate limiting

            except Exception as e:
                print(f"      Warning: Failed page {page}: {e}")
                break

        return cards

    def _fetch_tcgdex_cards(self) -> List[Dict]:
        """Fetch cards from TCGdex API (Japanese, Chinese, etc.)"""
        cards = []
        languages = ['ja', 'zh-tw']  # Japanese and Traditional Chinese

        for lang in languages:
            lang_url = f"{TCGDEX_BASE_URL}/{lang}/sets"

            try:
                response = requests.get(lang_url, timeout=30)
                response.raise_for_status()
                sets = response.json()

                for set_data in sets:
                    set_id = set_data.get('id')
                    if not set_id:
                        continue

                    # Fetch cards for this set
                    set_url = f"{TCGDEX_BASE_URL}/{lang}/sets/{set_id}"
                    set_response = requests.get(set_url, timeout=30)
                    set_response.raise_for_status()
                    set_details = set_response.json()

                    for card in set_details.get('cards', []):
                        cards.append({
                            'id': f"{card['id']}-{lang}",
                            'name': card.get('name', ''),
                            'set_id': set_id,
                            'set_name': set_details.get('name', ''),
                            'card_number': card.get('localId', ''),
                            'language': lang,
                            'image_url_small': card.get('image', {}).get('small'),
                            'rarity': card.get('rarity'),
                            'source': 'tcgdex'
                        })

                    time.sleep(0.2)  # Rate limiting

            except Exception as e:
                print(f"      Warning: Failed to fetch {lang} cards: {e}")
                continue

        return cards

    def insert_printings(self, cards: List[Dict]):
        """Insert card printings into database"""
        cursor = self.conn.cursor()

        for card in cards:
            cursor.execute("""
                INSERT OR REPLACE INTO printings (
                    printing_id, set_id, set_name, card_number, language,
                    image_url_small, rarity, source
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                card['id'],
                card['set_id'],
                card['set_name'],
                card['card_number'],
                card['language'],
                card.get('image_url_small'),
                card.get('rarity'),
                card['source']
            ))

        self.conn.commit()
        self.stats['printing_count'] = len(cards)
        print(f"  Inserted {len(cards)} printings")

    def map_printings_to_species(self, cards: List[Dict], species_list: List[Species]):
        """Map card printings to species using name matching"""
        # Build species name dictionary for mapper
        species_dict = {}
        for species in species_list:
            all_names = [name.name for name in species.names]
            species_dict[species.species_id] = all_names

        # Create mapper
        mapper = SpeciesMapper(species_dict)

        # Map all cards
        cursor = self.conn.cursor()
        mapped_count = 0
        unmapped_count = 0

        for card in cards:
            mapping = mapper.map_card_to_species(
                card['id'],
                card['name']
            )

            if mapping.species_ids:
                # Insert mappings
                for i, species_id in enumerate(mapping.species_ids):
                    cursor.execute("""
                        INSERT INTO printing_species_map (printing_id, species_id, is_primary)
                        VALUES (?, ?, ?)
                    """, (
                        card['id'],
                        species_id,
                        mapping.is_primary[i]
                    ))
                    mapped_count += 1
            else:
                unmapped_count += 1

        self.conn.commit()
        self.stats['mapping_count'] = mapped_count
        print(f"  Created {mapped_count} card→species mappings")
        print(f"  Unmapped cards (trainers/energy): {unmapped_count}")

    def finalize_database(self):
        """Optimize and finalize the database"""
        print("\nFinalizing database...")

        cursor = self.conn.cursor()

        # Rebuild FTS5 indexes
        print("  Rebuilding FTS5 indexes...")
        cursor.execute("INSERT INTO species_aliases_fts(species_aliases_fts) VALUES('rebuild')")
        cursor.execute("INSERT INTO printings_fts(printings_fts) VALUES('rebuild')")

        # Optimize database
        print("  Optimizing database...")
        cursor.execute("VACUUM")
        cursor.execute("ANALYZE")

        self.conn.commit()
        print("  Database optimized")

    def print_summary(self):
        """Print build summary"""
        elapsed = time.time() - self.stats['start_time']

        print("\n" + "=" * 70)
        print("Build Complete!")
        print("=" * 70)
        print(f"Database: {self.output_path}")
        print(f"Schema Version: 2 (species-normalized)")
        print(f"\nStatistics:")
        print(f"  Species: {self.stats['species_count']:,}")
        print(f"  Aliases: {self.stats['alias_count']:,}")
        print(f"  Printings: {self.stats['printing_count']:,}")
        print(f"  Mappings: {self.stats['mapping_count']:,}")
        print(f"\nBuild Time: {elapsed:.1f} seconds")

        # Database size
        db_size = Path(self.output_path).stat().st_size / (1024 * 1024)
        print(f"Database Size: {db_size:.1f} MB")
        print("=" * 70)

    @staticmethod
    def _normalize_text(text: str) -> str:
        """Normalize text for searching"""
        return text.lower().strip()

    @staticmethod
    def _has_katakana(text: str) -> bool:
        """Check if text contains katakana"""
        return any('\u30a0' <= c <= '\u30ff' for c in text)


def main():
    parser = argparse.ArgumentParser(
        description='Build Pokemon Card Database V2 with species normalization'
    )
    parser.add_argument(
        '--out',
        default='pokemon_cards.db',
        help='Output database file (default: pokemon_cards.db)'
    )
    parser.add_argument(
        '--api-key',
        help='PokemonTCG.io API key (optional, increases rate limit)'
    )

    args = parser.parse_args()

    builder = DatabaseBuilder(args.out, args.api_key)
    builder.build()


if __name__ == "__main__":
    main()
