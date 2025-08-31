# Time Flipboard — Version 1.5

A split-flap **TIME | CITY** board widget for [Übersicht](https://tracesof.net/uebersicht/).  
Features: independent header widths, Tabler icon theme toggle, header color override, optional blank-tile animation, and top-of-hour time flicker.

> Widget folder: **`Time Flipboard.widget`**  
> Main file: **`index.coffee`**

---

## Install

1. Copy the folder `Time Flipboard.widget` into your Übersicht widgets directory:
   - macOS: `~/Library/Application Support/Übersicht/widgets/`
2. In Übersicht, toggle the widget on.  
3. Optional: adjust **position/scale** at the top of `index.coffee` via `POS`.

---

## Configure (top of `index.coffee`)
- `POS` — position & scale of the board.
- `USE_12H`, `SHOW_SECONDS` — time format.
- `CITY_TILES` — width of city column (rows).
- `HEADERS` — labels for header row.
- `HEADER_TIME_TILES / HEADER_TIME_EXTRA_TILES` — affect **header only** (not the time grid).
- `HEADER_CITY_TILES / HEADER_CITY_EXTRA_TILES` — affect **header only** (not the city grid).
- `HEADER_LABEL_COLOR`, `HEADER_LABEL_FORCE` — override header color.
- `FORCE_UPPERCASE` — row city names forced to uppercase.
- `CITY_CHATTER_ON_CHANGE / _ON_REVEAL` — random overlay “chatter” during city flips.
- `BLANK_TILES_ANIMATE` — blank tiles also flip (blank→blank).
- `HOUR_FLICKER_ON_TURNOVER` — time flickers with random digits when the hour changes.
- `CITIES` — list of `{ city, tz }` (IANA time zones). Empty strings produce blank rows.

---

## Runtime APIs (from browser console)
```js
// Replace rows at runtime
SplitFlapSetCities([
  { city:'Paris', tz:'Europe/Paris' },
  { city:'Tokyo', tz:'Asia/Tokyo' }
]);

// Change header labels at runtime
SplitFlapSetHeaders({ time:'Tiempo', city:'Destino' });

