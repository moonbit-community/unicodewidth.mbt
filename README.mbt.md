# unicodewidth

A MoonBit library for measuring the width of Unicode characters and strings according to the [Unicode Standard Annex #11 (UAX #11)](https://www.unicode.org/reports/tr11/) specification.

This is a direct MoonBit port of Rust's [`unicode-width`](https://github.com/unicode-rs/unicode-width) crate.

## Overview

This library provides functions to determine the display width of Unicode characters and strings, which is essential for:

- Terminal applications and text-based UIs
- Text formatting and alignment
- Display width calculations in monospace environments
- Handling mixed-width text (ASCII, CJK, emoji, etc.)

## Installation

Add this package to your `moon.pkg.json`:

```console
> moon add moonbit-community/unicodewidth
```

## API Reference

### Functions

#### `char_width(c : Char, cjk? : Bool = false) -> Int?`

Returns the UAX #11 based width of a character, or `None` if the character is a control character.

- **Parameters:**
  - `c`: The character to check
  - `cjk`: If `true`, ambiguous width characters are treated as wide (CJK context). If `false`, they are treated as narrow. Defaults to `false`.
- **Returns:** The width of the character, or `None` if it's a control character

#### `str_width(s : @string.View, cjk? : Bool = false) -> Int`

Returns the UAX #11 based width of a string.

- **Parameters:**
  - `s`: The string to measure
  - `cjk`: If `true`, ambiguous width characters are treated as wide (CJK context). If `false`, they are treated as narrow. Defaults to `false`.
- **Returns:** The total width of the string

#### `display_line(s : @string.View, cjk? : Bool = false) -> DisplayLine`

Parses a single logical line into terminal display units and legal textual
positions. This is the TUI-oriented API for cursor movement, hit testing,
zero-copy viewing, and truncation.

- **Parameters:**
  - `s`: The single-line string to lay out
  - `cjk`: If `true`, ambiguous width characters are treated as wide (CJK context). If `false`, they are treated as narrow. Defaults to `false`.
- **Returns:** A `DisplayLine` that maps between textual positions and display columns

#### `unicode_version: (Int, Int, Int)`

A constant tuple representing the Unicode version this library supports.

## Usage Examples

### Basic Character Width

```mbt nocheck
///|
test {
  // ASCII characters have width 1
  assert_eq(@unicodewidth.char_width('a'), Some(1))
  assert_eq(@unicodewidth.char_width('Z'), Some(1))

  // Fullwidth characters have width 2
  assert_eq(@unicodewidth.char_width('ｈ'), Some(2)) // Fullwidth 'h'

  // Control characters return None
  assert_eq(@unicodewidth.char_width('\u{0}'), None) // Null character

  // But str_width handles them as width 1
  assert_eq(@unicodewidth.str_width("\u{0}"), 1)
}
```

### String Width Calculation

```mbt nocheck
///|
test {
  // Mixed-width strings
  assert_eq(@unicodewidth.str_width("Hello"), 5) // ASCII only
  assert_eq(@unicodewidth.str_width("ｈｅｌｌｏ"), 10) // Fullwidth only
  assert_eq(@unicodewidth.str_width("Hello世界"), 9) // Mixed ASCII + CJK (5 + 2 + 2)

  // Emoji handling
  assert_eq(@unicodewidth.str_width("👩"), 2) // Woman emoji
  assert_eq(@unicodewidth.str_width("👩‍🔬"), 2) // Woman scientist (ZWJ sequence)
}
```

### CJK vs Non-CJK Context

```mbt nocheck
///|
test {
  // Ambiguous width characters behave differently in CJK vs non-CJK contexts
  let ambiguous_char = '\u{B7}' // Middle dot

  // In non-CJK context (cjk=false)
  assert_eq(@unicodewidth.char_width(ambiguous_char, cjk=false), Some(1))

  // In CJK context (cjk=true) - treated as wide
  assert_eq(@unicodewidth.char_width(ambiguous_char, cjk=true), Some(2))

  // This affects string width calculations
  let text = "Hello\u{B7}World"
  assert_eq(@unicodewidth.str_width(text, cjk=false), 11) // 5 + 1 + 5
  assert_eq(@unicodewidth.str_width(text, cjk=true), 12) // 5 + 2 + 5
}
```

### Complex Unicode Sequences

```mbt nocheck
///|
test {
  // Regional indicator sequences (flag emojis)
  assert_eq(@unicodewidth.str_width("🇺🇸"), 2) // US flag

  // Emoji with modifiers
  assert_eq(@unicodewidth.str_width("👶🏽"), 2) // Baby with skin tone modifier

  // Zero-width sequences
  assert_eq(@unicodewidth.str_width("👨‍👩‍👧‍👦"), 2) // Family emoji (multiple ZWJ)

  // Combining marks
  assert_eq(@unicodewidth.str_width("é"), 1) // 'e' + acute accent
}
```

### Terminal Line Layout

```mbt nocheck
///|
test {
  let line = @unicodewidth.display_line("a你好b")

  // Whole-line display width
  assert_eq(line.width(), 6)

  // Move by legal textual positions, not UTF-16 code units
  let after_a = line.next(line.start()).unwrap()
  let after_ni = line.next(after_a).unwrap()
  assert_eq(line.display_position(after_ni).column(), 3)

  // Convert a display column inside a wide character back to text boundaries
  let middle = @unicodewidth.DisplayPosition::new(column=2)
  assert_eq(
    line
    .view(line.start(), line.textual_position_at_or_before(middle))
    .to_owned(),
    "a",
  )
  assert_eq(
    line
    .view(line.start(), line.textual_position_at_or_after(middle))
    .to_owned(),
    "a你",
  )

  // Truncate without cutting through a display unit
  assert_eq(line.truncate(4), "a你…")
}
```

### Practical Applications

```mbt nocheck
///|
test {
  // Text alignment in terminal
  fn align_text(text : String, width : Int, align : String) -> String {
    let text_width = @unicodewidth.str_width(text)
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
  assert_eq(@unicodewidth.str_width(sample_text), 9) // 5 + 2 + 2
  let centered = align_text(sample_text, 10, "center")
  assert_eq(@unicodewidth.str_width(centered), 10)
}
```

For text truncation, split the input into grapheme clusters first, for example
with [`display_line`](#terminal-line-layout), then use its display units or
`truncate` method to avoid cutting through a user-perceived character or a
non-additive display sequence.

`str_width` remains the right API when you only need the final width of a whole
string. TUI editors should use `display_line` when they also need to map between
text positions and terminal columns.

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

```console
> moon test
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please ensure all tests pass and the code follows the project's coding conventions.
