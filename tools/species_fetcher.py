#!/usr/bin/env python3
"""
Species Fetcher - PokéAPI Integration
Fetches canonical Pokémon species data with multilingual names from PokéAPI
Includes caching to avoid rate limiting (100 req/min)
"""

import json
import time
from pathlib import Path
from typing import Dict, List, Optional
import requests
from dataclasses import dataclass, asdict


@dataclass
class SpeciesName:
    """A single name variant for a species"""
    language: str
    name: str
    is_canonical: bool = False


@dataclass
class Species:
    """Canonical Pokémon species with all language variants"""
    species_id: str
    canonical_name: str
    card_type: str
    names: List[SpeciesName]
    national_dex_number: Optional[int] = None


class SpeciesFetcher:
    """Fetches and caches Pokémon species data from PokéAPI"""

    API_BASE = "https://pokeapi.co/api/v2"
    RATE_LIMIT_DELAY = 0.6  # 100 req/min = 0.6s per request
    CACHE_FILE = "pokeapi_cache.json"

    # Language mapping from PokéAPI to our database
    LANGUAGE_MAP = {
        "en": "en",
        "ja": "ja",
        "ja-Hrkt": "ja",  # Japanese with hiragana/katakana
        "zh-Hant": "zh-tw",
        "zh-Hans": "zh-cn",
        "fr": "fr",
        "de": "de",
        "es": "es",
        "it": "it",
        "ko": "ko",
        "pt-BR": "pt"
    }

    def __init__(self, cache_path: Optional[Path] = None):
        self.cache_path = cache_path or Path(__file__).parent / self.CACHE_FILE
        self.cache = self._load_cache()
        self.request_count = 0
        self.last_request_time = 0

    def _load_cache(self) -> Dict:
        """Load cached species data"""
        if self.cache_path.exists():
            try:
                with open(self.cache_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Warning: Failed to load cache: {e}")
        return {}

    def _save_cache(self):
        """Save species data to cache"""
        try:
            with open(self.cache_path, 'w', encoding='utf-8') as f:
                json.dump(self.cache, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Warning: Failed to save cache: {e}")

    def _rate_limit(self):
        """Enforce rate limiting"""
        elapsed = time.time() - self.last_request_time
        if elapsed < self.RATE_LIMIT_DELAY:
            time.sleep(self.RATE_LIMIT_DELAY - elapsed)
        self.last_request_time = time.time()

    def _fetch_json(self, url: str) -> Optional[Dict]:
        """Fetch JSON from URL with rate limiting"""
        self._rate_limit()
        self.request_count += 1

        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"Error fetching {url}: {e}")
            return None

    def fetch_species(self, pokemon_id: int) -> Optional[Species]:
        """
        Fetch a single species from PokéAPI

        Args:
            pokemon_id: National Pokédex number (1-1025)

        Returns:
            Species object with all language names, or None on error
        """
        cache_key = f"species_{pokemon_id}"

        # Check cache first
        if cache_key in self.cache:
            data = self.cache[cache_key]
            return Species(
                species_id=data['species_id'],
                canonical_name=data['canonical_name'],
                card_type=data['card_type'],
                names=[SpeciesName(**n) for n in data['names']],
                national_dex_number=data.get('national_dex_number')
            )

        # Fetch from API
        url = f"{self.API_BASE}/pokemon-species/{pokemon_id}/"
        data = self._fetch_json(url)

        if not data:
            return None

        # Extract names
        names = []
        canonical_name = None

        for name_entry in data.get('names', []):
            lang_code = name_entry.get('language', {}).get('name')
            name = name_entry.get('name')

            if not lang_code or not name:
                continue

            # Map to our language codes
            mapped_lang = self.LANGUAGE_MAP.get(lang_code)
            if not mapped_lang:
                continue

            is_canonical = (mapped_lang == 'en')
            if is_canonical:
                canonical_name = name

            names.append(SpeciesName(
                language=mapped_lang,
                name=name,
                is_canonical=is_canonical
            ))

        if not canonical_name:
            print(f"Warning: No English name for species {pokemon_id}")
            return None

        # Create species object
        species_id = data.get('name', '').lower()  # e.g., "charizard"
        species = Species(
            species_id=species_id,
            canonical_name=canonical_name,
            card_type='pokemon',  # All PokéAPI entries are Pokémon
            names=names,
            national_dex_number=pokemon_id
        )

        # Cache the result
        self.cache[cache_key] = {
            'species_id': species.species_id,
            'canonical_name': species.canonical_name,
            'card_type': species.card_type,
            'names': [asdict(n) for n in species.names],
            'national_dex_number': species.national_dex_number
        }

        return species

    def fetch_all_species(self, max_id: int = 1025) -> List[Species]:
        """
        Fetch all Pokémon species up to max_id

        Args:
            max_id: Maximum National Dex number (default: 1025 for Gen 9)

        Returns:
            List of Species objects
        """
        print(f"Fetching species 1-{max_id} from PokéAPI...")
        print(f"Cache: {len(self.cache)} entries")

        species_list = []
        failed = []

        for pokemon_id in range(1, max_id + 1):
            if pokemon_id % 50 == 0:
                print(f"Progress: {pokemon_id}/{max_id} ({self.request_count} API requests)")

            species = self.fetch_species(pokemon_id)
            if species:
                species_list.append(species)
            else:
                failed.append(pokemon_id)

        # Save cache after fetching
        self._save_cache()

        print(f"\nFetched {len(species_list)} species ({self.request_count} API requests)")
        if failed:
            print(f"Failed to fetch: {failed}")

        return species_list

    def add_manual_species(self, species_id: str, canonical_name: str,
                          card_type: str = 'trainer') -> Species:
        """
        Manually create a species for non-Pokémon cards (trainers, energy, etc.)

        Args:
            species_id: Unique identifier (e.g., "professor-oak")
            canonical_name: English name
            card_type: 'trainer' or 'energy'

        Returns:
            Species object with English name only
        """
        return Species(
            species_id=species_id,
            canonical_name=canonical_name,
            card_type=card_type,
            names=[SpeciesName(language='en', name=canonical_name, is_canonical=True)]
        )


def main():
    """Test the species fetcher"""
    fetcher = SpeciesFetcher()

    # Test with a single species
    print("Testing Charizard (ID 6)...")
    charizard = fetcher.fetch_species(6)

    if charizard:
        print(f"\nSpecies ID: {charizard.species_id}")
        print(f"Canonical: {charizard.canonical_name}")
        print(f"Type: {charizard.card_type}")
        print(f"\nNames ({len(charizard.names)}):")
        for name in charizard.names:
            marker = "★" if name.is_canonical else " "
            print(f"  {marker} [{name.language}] {name.name}")

    # Uncomment to fetch all species (takes ~10 minutes)
    # all_species = fetcher.fetch_all_species(max_id=100)
    # print(f"\nFetched {len(all_species)} total species")


if __name__ == "__main__":
    main()
