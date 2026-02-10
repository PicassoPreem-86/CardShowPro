#!/usr/bin/env python3
"""
Species Mapper - Card Name to Species Linking
Maps card names to species IDs by analyzing card text and matching against species names
Handles multi-Pokémon cards, variants (EX, GX, V, VMAX, etc.), and edge cases
"""

import re
from typing import List, Dict, Set, Optional, Tuple
from dataclasses import dataclass


@dataclass
class CardSpeciesMapping:
    """Mapping between a card and its species"""
    card_id: str
    species_ids: List[str]
    is_primary: List[bool]  # Which species is primary (for multi-Pokémon cards)
    confidence: float  # 0.0-1.0, for manual review threshold


class SpeciesMapper:
    """Maps card names to species using pattern matching and name normalization"""

    # Pokémon card variants to strip (case-insensitive)
    VARIANT_SUFFIXES = [
        r'\s+EX\s*$',
        r'\s+GX\s*$',
        r'\s+V\s*$',
        r'\s+VMAX\s*$',
        r'\s+VSTAR\s*$',
        r'\s+&\s+',  # TAG TEAM delimiter
        r'\s+ex\s*$',  # Lowercase variants
        r'\s+gx\s*$',
        r'\s+v\s*$',
        r'\s+vmax\s*$',
        r'\s+vstar\s*$',
    ]

    # Trainer/Energy keywords (not Pokémon)
    NON_POKEMON_KEYWORDS = [
        'professor', 'energy', 'potion', 'ball', 'stadium', 'supporter',
        'item', 'tool', 'fossil', 'trainer', 'stadium', 'rocket',
        # Common trainer names
        'oak', 'juniper', 'sycamore', 'cynthia', 'n', 'guzma', 'marnie',
    ]

    def __init__(self, species_dict: Dict[str, List[str]]):
        """
        Initialize mapper with species data

        Args:
            species_dict: {species_id: [list of all names in all languages]}
                         e.g., {"charizard": ["Charizard", "リザードン", "Rizaadon", ...]}
        """
        self.species_dict = species_dict

        # Build reverse lookup: normalized_name -> species_id
        self.name_to_species: Dict[str, str] = {}
        for species_id, names in species_dict.items():
            for name in names:
                normalized = self._normalize_name(name)
                if normalized:
                    # Store first match (canonical usually comes first)
                    if normalized not in self.name_to_species:
                        self.name_to_species[normalized] = species_id

    @staticmethod
    def _normalize_name(name: str) -> str:
        """Normalize name for matching"""
        if not name:
            return ""

        # Lowercase and strip whitespace
        normalized = name.lower().strip()

        # Remove special characters but keep spaces for multi-word names
        normalized = re.sub(r'[^\w\s]', '', normalized)

        # Remove extra whitespace
        normalized = re.sub(r'\s+', ' ', normalized).strip()

        return normalized

    def _strip_variants(self, card_name: str) -> str:
        """Remove variant suffixes from card name"""
        name = card_name

        for pattern in self.VARIANT_SUFFIXES:
            name = re.sub(pattern, '', name, flags=re.IGNORECASE)

        return name.strip()

    def _is_trainer_or_energy(self, card_name: str) -> bool:
        """Check if card name contains trainer/energy keywords"""
        name_lower = card_name.lower()

        for keyword in self.NON_POKEMON_KEYWORDS:
            if keyword in name_lower:
                return True

        return False

    def _extract_pokemon_names(self, card_name: str) -> List[str]:
        """
        Extract Pokémon names from card name (handles TAG TEAMs, etc.)

        Returns:
            List of Pokémon names found (e.g., ["Pikachu", "Zekrom"] for TAG TEAM)
        """
        # Remove variant suffixes first
        cleaned = self._strip_variants(card_name)

        # Check for TAG TEAM (& delimiter)
        if '&' in cleaned:
            parts = [p.strip() for p in cleaned.split('&')]
            return [p for p in parts if p]

        # Single Pokémon
        return [cleaned] if cleaned else []

    def map_card_to_species(self, card_id: str, card_name: str,
                           card_type: Optional[str] = None) -> CardSpeciesMapping:
        """
        Map a single card to its species

        Args:
            card_id: Unique card identifier
            card_name: Card name from API
            card_type: Optional type hint ('pokemon', 'trainer', 'energy')

        Returns:
            CardSpeciesMapping with species IDs and confidence
        """
        # Check if it's explicitly not a Pokémon
        if card_type in ('trainer', 'energy') or self._is_trainer_or_energy(card_name):
            return CardSpeciesMapping(
                card_id=card_id,
                species_ids=[],
                is_primary=[],
                confidence=0.0
            )

        # Extract Pokémon names
        pokemon_names = self._extract_pokemon_names(card_name)

        if not pokemon_names:
            return CardSpeciesMapping(
                card_id=card_id,
                species_ids=[],
                is_primary=[],
                confidence=0.0
            )

        # Match each Pokémon name to a species
        species_ids = []
        is_primary = []
        confidences = []

        for i, name in enumerate(pokemon_names):
            normalized = self._normalize_name(name)

            if normalized in self.name_to_species:
                species_id = self.name_to_species[normalized]
                species_ids.append(species_id)
                is_primary.append(i == 0)  # First Pokémon is primary
                confidences.append(1.0)  # Exact match
            else:
                # Fuzzy match attempt (check if name is substring of any species name)
                best_match = self._fuzzy_match(normalized)
                if best_match:
                    species_ids.append(best_match)
                    is_primary.append(i == 0)
                    confidences.append(0.7)  # Lower confidence for fuzzy match

        # Overall confidence is minimum of all matches
        overall_confidence = min(confidences) if confidences else 0.0

        return CardSpeciesMapping(
            card_id=card_id,
            species_ids=species_ids,
            is_primary=is_primary,
            confidence=overall_confidence
        )

    def _fuzzy_match(self, name: str) -> Optional[str]:
        """
        Fuzzy match a name against species names

        Args:
            name: Normalized name to match

        Returns:
            Best matching species_id or None
        """
        if not name or len(name) < 3:
            return None

        # Check if name is a substring of any species name
        for species_name, species_id in self.name_to_species.items():
            if name in species_name or species_name in name:
                return species_id

        return None

    def map_all_cards(self, cards: List[Dict]) -> List[CardSpeciesMapping]:
        """
        Map all cards to species

        Args:
            cards: List of card dicts with 'id' and 'name' keys

        Returns:
            List of CardSpeciesMapping objects
        """
        mappings = []

        for card in cards:
            card_id = card.get('id')
            card_name = card.get('name')
            card_type = card.get('type')

            if not card_id or not card_name:
                continue

            mapping = self.map_card_to_species(card_id, card_name, card_type)
            mappings.append(mapping)

        return mappings

    def get_unmapped_cards(self, mappings: List[CardSpeciesMapping],
                          confidence_threshold: float = 0.9) -> List[CardSpeciesMapping]:
        """
        Get cards that failed to map or have low confidence

        Args:
            mappings: List of all mappings
            confidence_threshold: Minimum confidence to consider "mapped"

        Returns:
            List of unmapped/low-confidence mappings for manual review
        """
        return [
            m for m in mappings
            if not m.species_ids or m.confidence < confidence_threshold
        ]


def main():
    """Test species mapping"""
    # Sample species dict
    species_dict = {
        'charizard': ['Charizard', 'リザードン', 'Rizaadon'],
        'pikachu': ['Pikachu', 'ピカチュウ', 'Pikachuu'],
        'mewtwo': ['Mewtwo', 'ミュウツー', 'Myuutsuu'],
        'reshiram': ['Reshiram', 'レシラム', 'Reshiramu'],
        'zekrom': ['Zekrom', 'ゼクロム', 'Zekuromu'],
    }

    mapper = SpeciesMapper(species_dict)

    # Test cases
    test_cards = [
        {'id': '1', 'name': 'Charizard EX'},
        {'id': '2', 'name': 'Pikachu VMAX'},
        {'id': '3', 'name': 'Reshiram & Zekrom GX'},  # TAG TEAM
        {'id': '4', 'name': 'Professor Oak'},  # Trainer
        {'id': '5', 'name': 'リザードン'},  # Japanese
        {'id': '6', 'name': 'Mewtwo V'},
    ]

    print("Species Mapping Test Cases")
    print("=" * 60)

    for card in test_cards:
        mapping = mapper.map_card_to_species(
            card['id'],
            card['name']
        )

        print(f"\nCard: {card['name']}")
        print(f"  Species: {mapping.species_ids}")
        print(f"  Primary: {mapping.is_primary}")
        print(f"  Confidence: {mapping.confidence:.2f}")


if __name__ == "__main__":
    main()
