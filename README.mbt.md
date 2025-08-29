# unicodewidth

A MoonBit library for measuring the width of Unicode characters and strings according to the [Unicode Standard Annex #11 (UAX #11)](https://www.unicode.org/reports/tr11/) specification.

## Overview

This library provides functions to determine the display width of Unicode characters and strings, which is essential for:

- Terminal applications and text-based UIs
- Text formatting and alignment
- Display width calculations in monospace environments
- Handling mixed-width text (ASCII, CJK, emoji, etc.)

## Installation

Add this package to your `moon.pkg.json`:

```console
> moon add rami3l/unicodewidth
```

## API Reference

### Functions

#### `char_width(c: Char, cjk?: Bool = true) -> Int?`

Returns the UAX #11 based width of a character, or `None` if the character is a control character.

- **Parameters:**
  - `c`: The character to check
  - `cjk`: If `true`, ambiguous width characters are treated as wide (CJK context). If `false`, they are treated as narrow. Defaults to `true`.
- **Returns:** The width of the character, or `None` if it's a control character

#### `str_width(s: String, cjk?: Bool = true) -> Int`

Returns the UAX #11 based width of a string.

- **Parameters:**
  - `s`: The string to measure
  - `cjk`: If `true`, ambiguous width characters are treated as wide (CJK context). If `false`, they are treated as narrow. Defaults to `true`.
- **Returns:** The total width of the string

#### `unicode_version: (Int, Int, Int)`

A constant tuple representing the Unicode version this library supports.

## Usage Examples

### Basic Character Width

```mbt
test {
  // ASCII characters have width 1
  assert_eq(char_width('a'), Some(1))
  assert_eq(char_width('Z'), Some(1))

  // Fullwidth characters have width 2
  assert_eq(char_width('ｈ'), Some(2)) // Fullwidth 'h'

  // Control characters return None
  assert_eq(char_width('\u{0}'), None) // Null character

  // But str_width handles them as width 1
  assert_eq(str_width("\u{0}"), 1)
}
```

### String Width Calculation

```mbt
test {
  // Mixed-width strings
  assert_eq(str_width("Hello"), 5)                    // ASCII only
  assert_eq(str_width("ｈｅｌｌｏ"), 10)              // Fullwidth only
  assert_eq(str_width("Hello世界"), 9)                 // Mixed ASCII + CJK (5 + 2 + 2)

  // Emoji handling
  assert_eq(str_width("👩"), 2)                       // Woman emoji
  assert_eq(str_width("👩‍🔬"), 2)                     // Woman scientist (ZWJ sequence)
}
```

### CJK vs Non-CJK Context

```mbt
test {
  // Ambiguous width characters behave differently in CJK vs non-CJK contexts
  let ambiguous_char = '\u{B7}'  // Middle dot

  // In non-CJK context (cjk=false)
  assert_eq(char_width(ambiguous_char, cjk=false), Some(1))

  // In CJK context (cjk=true) - treated as wide
  assert_eq(char_width(ambiguous_char, cjk=true), Some(2))

  // This affects string width calculations
  let text = "Hello\u{B7}World"
  assert_eq(str_width(text, cjk=false), 11)  // 5 + 1 + 5
  assert_eq(str_width(text, cjk=true), 12)   // 5 + 2 + 5
}
```

### Complex Unicode Sequences

```mbt
test {
  // Regional indicator sequences (flag emojis)
  assert_eq(str_width("🇺🇸"), 2) // US flag

  // Emoji with modifiers
  assert_eq(str_width("👶🏽"), 2) // Baby with skin tone modifier

  // Zero-width sequences
  assert_eq(str_width("👨‍👩‍👧‍👦"), 2) // Family emoji (multiple ZWJ)

  // Combining marks
  assert_eq(str_width("é"), 1) // 'e' + acute accent
}
```

### Practical Applications

```mbt
test {
  // Text alignment in terminal
  fn align_text(text: String, width: Int, align: String) -> String {
    let text_width = str_width(text)
    match align {
      "left" => text + " ".repeat(width - text_width)
      "right" => " ".repeat(width - text_width) + text
      "center" => {
        let left_pad = (width - text_width) / 2
        let right_pad = width - text_width - left_pad
        " ".repeat(left_pad) + text + " ".repeat(right_pad)
      }
      _ => text
    }
  }

  // Example usage
  let sample_text = "Hello世界"
  assert_eq(str_width(sample_text), 9)  // 5 + 2 + 2
  let centered = align_text(sample_text, 10, "center")
  assert_eq(str_width(centered), 10)
}
```

### Text Truncation Utility

```mbt
test {
  // Truncate text to fit display width
  fn truncate_to_width(text: String, max_width: Int) -> String {
    let mut result = ""
    let mut current_width = 0

    for c in text {
      let char_w = char_width(c).unwrap_or(1)
      if current_width + char_w <= max_width {
        result = result + c.to_string()
        current_width = current_width + char_w
      } else {
        break
      }
    }

    result
  }

  // Example usage
  let long_text = "This is a very long text with emoji 🚀 and CJK 世界"
  let truncated = truncate_to_width(long_text, 20)
  assert_eq(str_width(truncated), 20)
}
```

## Character Width Categories

The library handles various Unicode character width categories:

- **Width 0:** Combining marks, zero-width characters, control characters
- **Width 1:** Most ASCII, Latin, and narrow characters
- **Width 2:** Fullwidth characters, CJK ideographs, emoji, wide characters
- **Ambiguous:** Characters that can be either narrow or wide depending on context

## Unicode Version Support

This library supports Unicode version information through the `unicode_version` constant, allowing you to check compatibility and version-specific behavior.

## Testing

The library includes comprehensive tests covering:

- Basic character and string width calculations
- CJK vs non-CJK context handling
- Emoji and complex Unicode sequences
- Regional indicators and combining marks
- Zero-width characters and sequences
- Edge cases and boundary conditions

Run tests with:

```bash
make test
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please ensure all tests pass and the code follows the project's coding conventions.
