#!/usr/bin/env python3
"""
Romanization - Katakana to Romaji Conversion
Converts Japanese katakana card names to searchable romaji variants
Generates variants for common romanization ambiguities (r/l, long vowels, etc.)
"""

from typing import List, Set


class Romanizer:
    """Convert Japanese katakana to romaji with variant generation"""

    # Katakana to Hepburn romaji mapping
    KATAKANA_MAP = {
        # Basic vowels
        'ア': 'a', 'イ': 'i', 'ウ': 'u', 'エ': 'e', 'オ': 'o',

        # K-row
        'カ': 'ka', 'キ': 'ki', 'ク': 'ku', 'ケ': 'ke', 'コ': 'ko',
        'ガ': 'ga', 'ギ': 'gi', 'グ': 'gu', 'ゲ': 'ge', 'ゴ': 'go',

        # S-row
        'サ': 'sa', 'シ': 'shi', 'ス': 'su', 'セ': 'se', 'ソ': 'so',
        'ザ': 'za', 'ジ': 'ji', 'ズ': 'zu', 'ゼ': 'ze', 'ゾ': 'zo',

        # T-row
        'タ': 'ta', 'チ': 'chi', 'ツ': 'tsu', 'テ': 'te', 'ト': 'to',
        'ダ': 'da', 'ヂ': 'ji', 'ヅ': 'zu', 'デ': 'de', 'ド': 'do',

        # N-row
        'ナ': 'na', 'ニ': 'ni', 'ヌ': 'nu', 'ネ': 'ne', 'ノ': 'no',

        # H-row
        'ハ': 'ha', 'ヒ': 'hi', 'フ': 'fu', 'ヘ': 'he', 'ホ': 'ho',
        'バ': 'ba', 'ビ': 'bi', 'ブ': 'bu', 'ベ': 'be', 'ボ': 'bo',
        'パ': 'pa', 'ピ': 'pi', 'プ': 'pu', 'ペ': 'pe', 'ポ': 'po',

        # M-row
        'マ': 'ma', 'ミ': 'mi', 'ム': 'mu', 'メ': 'me', 'モ': 'mo',

        # Y-row
        'ヤ': 'ya', 'ユ': 'yu', 'ヨ': 'yo',

        # R-row
        'ラ': 'ra', 'リ': 'ri', 'ル': 'ru', 'レ': 're', 'ロ': 'ro',

        # W-row
        'ワ': 'wa', 'ヲ': 'wo', 'ン': 'n',

        # Small characters (combine with previous)
        'ャ': 'ya', 'ュ': 'yu', 'ョ': 'yo',
        'ァ': 'a', 'ィ': 'i', 'ゥ': 'u', 'ェ': 'e', 'ォ': 'o',

        # Special
        'ー': '', # Long vowel marker (handled specially)
        'ッ': '', # Geminate consonant (handled specially)
        'ヴ': 'vu',

        # Hiragana equivalents (for mixed scripts)
        'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
        'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
        'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
        'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
        'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
        'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
        'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
        'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
        'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
        'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
        'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
        'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
        'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
        'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
        'わ': 'wa', 'を': 'wo', 'ん': 'n',
        'ゃ': 'ya', 'ゅ': 'yu', 'ょ': 'yo',
        'ぁ': 'a', 'ぃ': 'i', 'ぅ': 'u', 'ぇ': 'e', 'ぉ': 'o',
    }

    @staticmethod
    def to_romaji(text: str) -> str:
        """
        Convert katakana/hiragana to romaji (Hepburn system)

        Args:
            text: Japanese text (katakana or hiragana)

        Returns:
            Romanized text (lowercase)
        """
        if not text:
            return ""

        result = []
        i = 0
        length = len(text)

        while i < length:
            char = text[i]

            # Handle small tsu (geminate consonant) - doubles next consonant
            if char == 'ッ' or char == 'っ':
                if i + 1 < length:
                    next_char = text[i + 1]
                    next_romaji = Romanizer.KATAKANA_MAP.get(next_char, '')
                    if next_romaji:
                        result.append(next_romaji[0])  # Double the first consonant
                i += 1
                continue

            # Handle long vowel marker
            if char == 'ー':
                # Extend the previous vowel
                if result:
                    last_char = result[-1][-1] if result[-1] else ''
                    if last_char in 'aeiou':
                        result.append(last_char)
                i += 1
                continue

            # Check for small ya/yu/yo (combine with previous)
            if i + 1 < length and text[i + 1] in ('ャ', 'ュ', 'ョ', 'ゃ', 'ゅ', 'ょ'):
                base_romaji = Romanizer.KATAKANA_MAP.get(char, char.lower())
                small_romaji = Romanizer.KATAKANA_MAP.get(text[i + 1], '')

                # Remove final 'i' from base and append small character
                if base_romaji.endswith('i'):
                    result.append(base_romaji[:-1] + small_romaji)
                else:
                    result.append(base_romaji + small_romaji)
                i += 2
                continue

            # Regular character conversion
            romaji = Romanizer.KATAKANA_MAP.get(char, char.lower())
            result.append(romaji)
            i += 1

        return ''.join(result).lower()

    @staticmethod
    def generate_variants(romaji: str) -> Set[str]:
        """
        Generate common romanization variants for better search matching

        Args:
            romaji: Romanized text

        Returns:
            Set of variant spellings
        """
        variants = {romaji}

        # R/L confusion (common for English speakers)
        if 'r' in romaji:
            variants.add(romaji.replace('r', 'l'))

        # Long vowel variants
        # ō → o, ū → u, etc.
        replacements = [
            ('ō', 'o'), ('oo', 'o'),
            ('ū', 'u'), ('uu', 'u'),
            ('ā', 'a'), ('aa', 'a'),
            ('ē', 'e'), ('ee', 'e'),
            ('ī', 'i'), ('ii', 'i'),
        ]
        for old, new in replacements:
            if old in romaji:
                variants.add(romaji.replace(old, new))

        # Shi/si, chi/ti, tsu/tu variants
        replacements = [
            ('shi', 'si'),
            ('chi', 'ti'),
            ('tsu', 'tu'),
            ('fu', 'hu'),
            ('ji', 'zi'),
        ]
        for old, new in replacements:
            if old in romaji:
                variants.add(romaji.replace(old, new))

        # Remove duplicates and empty strings
        return {v for v in variants if v}

    @staticmethod
    def romanize_with_variants(japanese_text: str) -> List[str]:
        """
        Convert Japanese text to romaji and generate all search variants

        Args:
            japanese_text: Katakana or hiragana text

        Returns:
            List of romanization variants (includes original romaji)
        """
        base_romaji = Romanizer.to_romaji(japanese_text)
        variants = Romanizer.generate_variants(base_romaji)
        return sorted(variants)


def main():
    """Test romanization"""
    test_cases = [
        ("リザードン", "Charizard"),
        ("ピカチュウ", "Pikachu"),
        ("ミュウツー", "Mewtwo"),
        ("フシギバナ", "Venusaur"),
        ("カメックス", "Blastoise"),
        ("イーブイ", "Eevee"),
        ("ゲンガー", "Gengar"),
        ("ギャラドス", "Gyarados"),
        ("ルギア", "Lugia"),
        ("ホウオウ", "Ho-Oh"),
    ]

    print("Romanization Test Cases")
    print("=" * 60)

    for japanese, english in test_cases:
        romaji = Romanizer.to_romaji(japanese)
        variants = Romanizer.generate_variants(romaji)

        print(f"\n{japanese} ({english})")
        print(f"  Base: {romaji}")
        print(f"  Variants: {', '.join(sorted(variants))}")


if __name__ == "__main__":
    main()
