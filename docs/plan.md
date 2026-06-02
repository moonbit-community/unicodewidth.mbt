# DisplayLine API checkpoint

## Goal

Add a high-level single-line terminal display API so TUI authors can work with
safe text boundaries and display columns without manually combining grapheme
iteration and `str_width`.

## Accepted design

Expose a single-line `DisplayLine` model built from text and the existing width
rules. It provides display units, legal textual positions, display-column
positions, conversion between those coordinate systems, zero-copy viewing, and
truncation.

The API deliberately avoids the word cursor because terminal cursor coordinates
and textual insertion boundaries are different concepts.

## Target files and surfaces

- `moon.mod`: add the grapheme dependency used to determine legal text
  boundaries.
- `moon.pkg`: import the grapheme package for the root package.
- `display_line.mbt`: implementation of the new API.
- `unicodewidth_test.mbt`: focused tests for display units, position mapping,
  viewing, and truncation.
- `README.mbt.md`: document the TUI-oriented API.
- `pkg.generated.mbti`: generated interface update from `moon info`.

## API/interface diff

Expected additions:

- `pub fn display_line(StringView, cjk? : Bool) -> DisplayLine`
- opaque `DisplayLine`
- opaque `DisplayUnit`
- opaque `TextualPosition`
- opaque `DisplayPosition`
- `DisplayLine::width(Self) -> Int`
- `DisplayLine::units(Self) -> Array[DisplayUnit]`
- `DisplayLine::start(Self) -> TextualPosition`
- `DisplayLine::end(Self) -> TextualPosition`
- `DisplayLine::next(Self, TextualPosition) -> TextualPosition?`
- `DisplayLine::prev(Self, TextualPosition) -> TextualPosition?`
- `DisplayLine::display_position(Self, TextualPosition) -> DisplayPosition`
- `DisplayLine::textual_position_at_or_before(Self, DisplayPosition) -> TextualPosition`
- `DisplayLine::textual_position_at_or_after(Self, DisplayPosition) -> TextualPosition`
- `DisplayLine::view(Self, TextualPosition, TextualPosition) -> StringView`
- `DisplayLine::truncate(Self, Int, suffix? : StringView) -> String`
- `DisplayUnit::text(Self) -> StringView`
- `DisplayUnit::width(Self) -> Int`
- `DisplayUnit::textual_start(Self) -> TextualPosition`
- `DisplayUnit::textual_end(Self) -> TextualPosition`
- `DisplayUnit::display_start(Self) -> DisplayPosition`
- `DisplayUnit::display_end(Self) -> DisplayPosition`
- `DisplayPosition::column(Self) -> Int`

Existing `char_width`, `str_width`, and `unicode_version` remain unchanged.

## Open questions

Use `Array[DisplayUnit]` for `DisplayLine::units` initially. A custom iterator
can be added later if profiling shows array allocation is a real issue.

## Next implementation step

Implement `DisplayLine` using `kawaz/grapheme` as the textual boundary source
and the existing `str_width` rules for unit widths.

## Validation plan

- Add tests for ASCII, CJK wide characters, emoji ZWJ sequences, combining
  marks, truncation with suffix, and display-column mapping inside wide units.
- Run `moon check`.
- Run `moon test`.
- Run `moon info && moon fmt`.
- Review `.mbti` changes before committing.
