###
───────────────────────────────────────────────────────────────────────────────
Time Flipboard - Version 1.5
Author: Alexander Reyes, Reywins.com
Description: Independent header widths • Theme toggle (Tabler) • Header color override
             Blank tiles can animate • Top-of-hour time flicker (optional)
             Mountain Time added to fallback
───────────────────────────────────────────────────────────────────────────────

EDITABLE AT TOP:
  POS / USE_12H / SHOW_SECONDS / CITY_TILES
  HEADERS + HEADER_* (affects header only, not grid!)
  HEADER_LABEL_COLOR + HEADER_LABEL_FORCE
  FORCE_UPPERCASE (rows only)
  CITY_CHATTER_* (random overlay during city flips)
  BLANK_TILES_ANIMATE (blank tiles flip too)
  HOUR_FLICKER_ON_TURNOVER (time flicker on hour)
  CITIES (IANA tz); blanks allowed
───────────────────────────────────────────────────────────────────────────────
###

# ---------- CONFIG (EDIT HERE) ----------

POS = x: 0, y: 0, z: 0, scale: 1

USE_12H      = false
SHOW_SECONDS = false

CITY_TILES = 14

# First-load reveals
HEADER_REVEAL_ON_START = false
CITY_REVEAL_ON_START   = true

# Header labels (text)
HEADERS = time: 'TIME', city: 'DESTINATION'

# Header widths (independent of grid/rows). null → auto(label + EXTRA).
HEADER_TIME_TILES       = null    # affects header only
HEADER_TIME_EXTRA_TILES = 1      # affects header only
HEADER_CITY_TILES       = null    # affects header only
HEADER_CITY_EXTRA_TILES = 0       # affects header only

# Header label color (dark-ish light gold) + force toggle
HEADER_LABEL_COLOR = '#efc25c'
HEADER_LABEL_FORCE = true

# Force all-caps for ROW city names (header text remains as-is)
FORCE_UPPERCASE = false

# City chatter (random glyphs on city flips). Turn off for perfectly clean flips.
CITY_CHATTER_ON_CHANGE   = true
CITY_CHATTER_ON_REVEAL   = true
HEADER_CHATTER_ON_REVEAL = false

# Blank tiles should animate too (blank→blank) when a flip is triggered
BLANK_TILES_ANIMATE = true

# Hour-change flicker (time column only)
HOUR_FLICKER_ON_TURNOVER = true
HOUR_FLICKER_STAGGER_MS  = 60
HOUR_FLICKER_DIGITS      = "0123456789"

# Tile geometry & type
TILE_W = 40
TILE_H = 60
TILE_G = 6
FONT_SZ = 40

# Anti-clipping tweaks
GLYPH_SCALE_X = 0.96
GLYPH_HPAD    = 2

# Layout paddings/gaps
BOARD_PAD   = 24
FRAME_PAD   = 22
COL_GAP     = 16
ROW_GAP     = 18
HEADER_VPAD = 12
GRID_VPAD   = 6

# Cities (IANA tz). Empty strings render blank rows (still animate if BLANK_TILES_ANIMATE=true).
CITIES = [
  { city: 'New York City', tz: 'America/New_York' }
  { city: 'DFW Metroplex',        tz: 'America/Chicago' }
  { city: 'Denver',        tz: 'America/Denver' }     # Mountain
  { city: 'San Francisco', tz: 'America/Los_Angeles' }
  { city: 'Honolulu',      tz: 'Pacific/Honolulu' }
  { city: '',              tz: '' }                   # blank row
]

# Chatter characters for generic flips
CHARSET = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789-–—•·:;,.!?"

# Theme behavior
DEFAULT_THEME = 'dark'
RESPECT_SAVED_THEME = true
FORCE_DEFAULT_THEME_ON_LOAD = false

# --------------------------------
refreshFrequency: if SHOW_SECONDS then 1000 else 1000
command: "date +%s"
style: ""
className: ""

# ---------- time helpers ----------
pad2 = (n) -> if n < 10 then '0' + n else '' + n

nthDow = (year, monthIdx, dow, nth) ->
  d = new Date(Date.UTC(year, monthIdx, 1))
  shift = (dow - d.getUTCDay() + 7) % 7
  day = 1 + shift + 7*(nth-1)
  new Date(Date.UTC(year, monthIdx, day))

isUsDst = (utcNow) ->
  y = utcNow.getUTCFullYear()
  start = nthDow(y, 2, 0, 2)   # 2nd Sun in Mar
  end   = nthDow(y, 10, 0, 1)  # 1st Sun in Nov
  utcNow >= start and utcNow < end

# Fallback for Intl failures (older WebKit) with static offsets
fallbackTime = (tzId, use12h, showSec) ->
  now = new Date()
  utc = new Date(now.getTime() + now.getTimezoneOffset()*60000)
  dst = isUsDst(utc)

  base =
    'America/New_York':    if dst then -4 else -5
    'America/Chicago':     if dst then -5 else -6
    'America/Denver':      if dst then -6 else -7   # Mountain (DST-aware)
    'America/Los_Angeles': if dst then -7 else -8
    'Pacific/Honolulu':    -10
    'America/Phoenix':     -7                        # Arizona (no DST)

  tzOff = base[tzId] ? 0
  t = new Date(utc.getTime() + tzOff*3600000)
  hh = t.getUTCHours(); mm = t.getUTCMinutes(); ss = t.getUTCSeconds()
  if use12h
    h12 = hh % 12; h12 = 12 if h12 is 0
    pad2(h12) + ':' + pad2(mm) + (if showSec then ':' + pad2(ss) else '')
  else
    pad2(hh) + ':' + pad2(mm) + (if showSec then ':' + pad2(ss) else '')

# cache formatters (micro-optimization)
_fmtCache = {}
formatTime = (tz) ->
  try
    opt =
      hour: '2-digit'
      minute: '2-digit'
      hour12: USE_12H
      timeZone: tz
    if SHOW_SECONDS then opt.second = '2-digit'
    fmt = _fmtCache[tz]
    unless fmt? then fmt = _fmtCache[tz] = new Intl.DateTimeFormat('en-US', opt)
    s = fmt.format new Date()
    base = s.split(' ')[0]
    if base.indexOf(':') is -1 then throw new Error('bad Intl')
    parts = base.split(':')
    parts = ((if p.length < 2 then '0' + p else p) for p in parts)
    parts.join(':')
  catch e
    fallbackTime tz, USE_12H, SHOW_SECONDS

# Parse "HH:MM" from a padded time string; returns {hh, mm} or nulls
parseHHMM = (s) ->
  try
    m = s.match /(\d{2}):(\d{2})/
    if m then {hh: m[1], mm: m[2]} else {hh: null, mm: null}
  catch e
    {hh: null, mm: null}

# Preserve spaces → blank tiles; optional uppercase for ROWS.
padFixed = (txt, w) ->
  t = (txt or '').toString()
  t = t.toUpperCase() if (typeof FORCE_UPPERCASE isnt 'undefined') and FORCE_UPPERCASE
  if t.length < w then t + Array(w - t.length + 1).join(' ') else t.slice(0, w)

# ---------- helpers ----------
randDifferentFromSet = (target, setStr) ->
  pool = setStr
  t = (target or ' ')
  for tries in [0...6]
    c = pool.charAt(Math.floor(Math.random()*pool.length))
    return c if c isnt t
  if t is ' ' then '-' else '•'

randDifferent       = (target) -> randDifferentFromSet(target, CHARSET)
randDigitDifferent  = (target) -> randDifferentFromSet(target, HOUR_FLICKER_DIGITS)

# ---------- tiles ----------
tileStatic = (ch) ->
  g = if ch is ' ' then '&nbsp;' else ch
  """
  <div class="tile blk">
    <div class="face top"><span class="glyph">#{g}</span></div>
    <div class="face bottom"><span class="glyph">#{g}</span></div>
    <div class="hinge"></div>
    <div class="pin pin-l"></div><div class="pin pin-r"></div>
  </div>
  """

# Faces = NEW char; overlays animate TOP=overlayTopChar (random/old/blank), BOTTOM=NEW
tileFlip = (oldCh, newCh, delayMs=0, overlayTopChar=null) ->
  og = if overlayTopChar? then overlayTopChar else oldCh
  og = if og is ' ' then '&nbsp;' else og
  ng = if newCh is ' ' then '&nbsp;' else newCh
  """
  <div class="tile blk animate" style="--st: #{delayMs}ms">
    <div class="face top"><span class="glyph">#{ng}</span></div>
    <div class="face bottom"><span class="glyph">#{ng}</span></div>
    <div class="flip flip-top"><span class="glyph">#{og}</span></div>
    <div class="flip flip-bottom"><span class="glyph">#{ng}</span></div>
    <div class="hinge"></div>
    <div class="pin pin-l"></div><div class="pin pin-r"></div>
  </div>
  """

# Generic tiles (supports blank-animate)
tilesFor = (oldText, newText, staggerMs=0, forceFlipAll=false, noisyTop=false) ->
  out = []
  for i in [0...newText.length]
    n = newText.charAt(i)
    o = if oldText? then oldText.charAt(i) else n

    if n is ' '
      if BLANK_TILES_ANIMATE and (forceFlipAll or (o isnt n))
        out.push tileFlip(' ', ' ', i*staggerMs, ' ')
      else
        out.push tileStatic(' ')
      continue

    if forceFlipAll or (o isnt n)
      topOverlay = if noisyTop then randDifferent(n) else o
      out.push tileFlip(o, n, i*staggerMs, topOverlay)
    else
      out.push tileStatic(n)
  out.join('')

# Special: time flicker with random DIGITS on top overlay, then settle
tilesForHourFlicker = (oldText, newText, staggerMs=0) ->
  out = []
  for i in [0...newText.length]
    n = newText.charAt(i)
    o = if oldText? then oldText.charAt(i) else n
    if n is ' '
      if BLANK_TILES_ANIMATE
        out.push tileFlip(' ', ' ', i*staggerMs, ' ')
      else
        out.push tileStatic(' ')
      continue
    # force all tiles to flip once with random digit on the top overlay
    out.push tileFlip(o, n, i*staggerMs, randDigitDifferent(n))
  out.join('')

# -------- Tabler icons --------
sunHighIcon = ->
  """
  <svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'
       stroke-width='1.6' stroke='currentColor' fill='none' stroke-linecap='round' stroke-linejoin='round' aria-hidden='true'>
    <path stroke='none' d='M0 0h24v24H0z' fill='none'/>
    <circle cx='12' cy='12' r='4'/>
    <path d='M12 3v2'/><path d='M12 19v2'/>
    <path d='M3 12h2'/><path d='M19 12h2'/>
    <path d='M5.6 5.6l1.4 1.4'/><path d='M17 17l1.4 1.4'/>
    <path d='M5.6 18.4l1.4 -1.4'/><path d='M17 7l1.4 -1.4'/>
  </svg>
  """

moonStarsIcon = ->
  """
  <svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'
       stroke-width='1.6' stroke='currentColor' fill='none' stroke-linecap='round' stroke-linejoin='round' aria-hidden='true'>
    <path stroke='none' d='M0 0h24v24H0z' fill='none'/>
    <path d='M12 3a9 9 0 1 0 9 9.5a7.5 7.5 0 1 1 -9 -9.5z'/>
    <path d='M17 4l0 .01'/><path d='M20 6l0 .01'/><path d='M20 3l0 .01'/>
  </svg>
  """

# ---------- THEME HELPERS ----------
_getStoredTheme = ->
  t = null
  if window? and window.localStorage?
    try t = window.localStorage.getItem 'splitflapTheme' catch e then t = null
  t

_iconForTheme = (t) -> if t is 'dark' then sunHighIcon() else moonStarsIcon()

_applyThemeNow = (t) ->
  window._splitflapTheme = t
  if window? and window.localStorage?
    try window.localStorage.setItem 'splitflapTheme', t catch e then null
  frame = document.querySelector('.sf-root .frame')
  board = document.querySelector('.sf-root .board')
  for el in [frame, board] when el?
    el.classList.remove('theme-dark', 'theme-light')
    el.classList.add("theme-#{t}")
  btn = document.getElementById('sf-theme-toggle')
  if btn? then btn.innerHTML = _iconForTheme(t)

window.__toggleSplitflapTheme = ->
  cur = if window? and window._splitflapTheme? then window._splitflapTheme else _getStoredTheme() ? DEFAULT_THEME
  cur = if cur is 'light' then 'light' else 'dark'
  nxt = if cur is 'light' then 'dark' else 'light'
  _applyThemeNow(nxt)
  false

# -------- state across renders --------
prevTimes  = null
prevCities = null
_hasRenderedOnce = false

render: ->
  # Theme
  stored = _getStoredTheme()
  theme =
    if FORCE_DEFAULT_THEME_ON_LOAD
      if window? and window.localStorage?
        try window.localStorage.setItem 'splitflapTheme', DEFAULT_THEME catch e then null
      DEFAULT_THEME
    else if RESPECT_SAVED_THEME and stored?
      stored
    else
      DEFAULT_THEME
  window._splitflapTheme = theme
  icon = _iconForTheme(theme)
  themeClass = "theme-#{theme}"

  # ----- COLUMN SIZING (header and grid fully independent) -----
  # Grid (rows) width
  rowTimeTiles = if SHOW_SECONDS then 8 else 5
  gridTimeColPx = (rowTimeTiles * TILE_W) + ((rowTimeTiles - 1) * TILE_G)
  gridCityColPx = (CITY_TILES   * TILE_W) + ((CITY_TILES   - 1) * TILE_G)

  # Header width (independent)
  htTiles =
    if Number.isInteger(HEADER_TIME_TILES) and HEADER_TIME_TILES > 0 then HEADER_TIME_TILES
    else Math.max((HEADERS.time or '').length + HEADER_TIME_EXTRA_TILES, 4)
  hcTiles =
    if Number.isInteger(HEADER_CITY_TILES) and HEADER_CITY_TILES > 0 then HEADER_CITY_TILES
    else Math.max((HEADERS.city or '').length + HEADER_CITY_EXTRA_TILES, 4)

  headerTimeColPx = (htTiles * TILE_W) + ((htTiles - 1) * TILE_G)
  headerCityColPx = (hcTiles * TILE_W) + ((hcTiles - 1) * TILE_G)

  # Board/frame width should fit the widest of header or grid
  gridContentW   = gridTimeColPx   + COL_GAP + gridCityColPx
  headerContentW = headerTimeColPx + COL_GAP + headerCityColPx
  contentW       = Math.max(gridContentW, headerContentW)
  boardW         = contentW + (2*BOARD_PAD)

  # Data
  arr = if window? then window._flipCitiesOverride else null
  localCities = if Array.isArray(arr) and arr.length > 0 then arr else CITIES

  headerTimeTxt = padFixed(HEADERS.time, htTiles)
  headerCityTxt = padFixed(HEADERS.city, hcTiles)

  # Times use GRID tile count (rowTimeTiles)
  times = (for r in localCities
    if r?.tz? and (''+r.tz).trim().length
      padFixed(formatTime(r.tz), rowTimeTiles)
    else
      padFixed('', rowTimeTiles)
  )
  cities = (for r in localCities then padFixed(r?.city ? '', CITY_TILES))

  # Header tiles
  headerTimeHtml =
    if !_hasRenderedOnce and HEADER_REVEAL_ON_START
      tilesFor Array(htTiles+1).join(' '), headerTimeTxt, 40, true, HEADER_CHATTER_ON_REVEAL
    else tilesFor null, headerTimeTxt, 0, false, false

  headerCityHtml =
    if !_hasRenderedOnce and HEADER_REVEAL_ON_START
      tilesFor Array(hcTiles+1).join(' '), headerCityTxt, 40, true, HEADER_CHATTER_ON_REVEAL
    else tilesFor null, headerCityTxt, 0, false, false

  # Rows
  rows = []
  for i in [0...localCities.length]
    oldTime = if prevTimes?  then prevTimes[i]  else null
    oldCity = if prevCities? then prevCities[i] else null

    # --- time with hour flicker ---
    timeHtml = null
    if HOUR_FLICKER_ON_TURNOVER and prevTimes?
      prev = parseHHMM(prevTimes[i] or '')
      curr = parseHHMM(times[i] or '')
      isHourTurnover = prev.hh? and curr.hh? and (prev.hh isnt curr.hh)
      if isHourTurnover
        timeHtml = tilesForHourFlicker oldTime, times[i], HOUR_FLICKER_STAGGER_MS
    timeHtml ?= tilesFor oldTime, times[i], 0, false, false

    # --- city ---
    cityChanged = prevCities? and (oldCity isnt cities[i])
    cityHtml =
      if (not prevCities?) and CITY_REVEAL_ON_START
        tilesFor Array(CITY_TILES+1).join(' '), cities[i], 60, true, CITY_CHATTER_ON_REVEAL
      else if cityChanged
        tilesFor oldCity, cities[i], 70, true, CITY_CHATTER_ON_CHANGE
      else
        tilesFor oldCity, cities[i], 0, false, false

    rows.push """
      <div class="group time-group">#{timeHtml}</div>
      <div class="group city-group">#{cityHtml}</div>
    """

  prevTimes  = times
  prevCities = cities
  _hasRenderedOnce = true

  # Header color override
  headerColorRule = if HEADER_LABEL_FORCE then ".header .glyph{ color: #{HEADER_LABEL_COLOR} !important; font-weight:800; letter-spacing:2px; }" else ""

  transform = "translate(-50%, -50%) translate(#{POS.x}px, #{POS.y}px) translateZ(#{POS.z}px) scale(#{POS.scale})"

  css = """
  <style>
    .sf-root{position:fixed;left:50%;top:50%;transform-origin:50% 50%;
      z-index:2147483647;color:#fff;user-select:none;pointer-events:none;
      font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue','SF Pro Display',Inter,Roboto,sans-serif}

    .frame{width:#{boardW + (2*FRAME_PAD)}px;height:auto;padding:#{FRAME_PAD}px;border-radius:22px;pointer-events:none}
    .frame.theme-dark{
      background:linear-gradient(180deg,#050506,#17191d 8%,#050506 92%);
      border:2px solid #000; box-shadow:0 18px 36px rgba(0,0,0,.45), inset 0 1px 0 rgba(255,255,255,.08)}
    .frame.theme-light{
      background:linear-gradient(180deg,#ffffff,#f2f4f7 8%,#ffffff 92%);
      border:2px solid #d6dbe3; box-shadow:0 12px 24px rgba(0,0,0,.18), inset 0 1px 0 rgba(255,255,255,.9)}

    .board{width:#{boardW}px;border-radius:18px;padding:#{BOARD_PAD}px; pointer-events:auto}
    .board.theme-dark{
      background:linear-gradient(180deg,#0e0f11,#090a0b);
      border:2px solid #3b3f45; box-shadow:inset 0 1px 0 rgba(255,255,255,.05), inset 0 -1px 0 rgba(0,0,0,.6)}
    .board.theme-light{
      background:linear-gradient(180deg,#f7f8fa,#edf0f4);
      border:2px solid #cdd3db; box-shadow:inset 0 1px 0 rgba(255,255,255,.85), inset 0 -1px 0 rgba(0,0,0,.06)}

    /* Header uses header-specific widths (independent) */
    .header{position:relative; pointer-events:auto;
      display:grid;grid-template-columns: #{headerTimeColPx}px #{headerCityColPx}px;column-gap:#{COL_GAP}px;align-items:center;
      border-radius:12px;padding:#{HEADER_VPAD}px 18px;margin-bottom:16px; border:1px solid}
    .theme-dark .header{ background:linear-gradient(180deg,#17191c,#0f1113); border-color:rgba(255,255,255,.06)}
    .theme-light .header{ background:linear-gradient(180deg,#ffffff,#f3f5f7); border-color:#e6ebf1}

    .header .group{display:flex;flex-wrap:nowrap}
    .header .group .tile{margin-right: #{TILE_G}px}
    .header .group .tile:last-child{margin-right:0}

    /* Grid uses grid-specific widths (independent) */
    .grid{display:grid;grid-template-columns: #{gridTimeColPx}px #{gridCityColPx}px;column-gap:#{COL_GAP}px;row-gap:#{ROW_GAP}px;
      padding:#{GRID_VPAD}px 2px}

    .group{display:flex;flex-wrap:nowrap}
    .group .tile{margin-right: #{TILE_G}px}
    .group .tile:last-child{margin-right:0}

    .tile{position:relative;width:#{TILE_W}px;height:#{TILE_H}px;perspective:1100px;transform-style:preserve-3d;border-radius:6px;
      filter:none; pointer-events:none}

    .theme-dark .tile.blk .face, .theme-dark .tile.blk .flip{background:linear-gradient(180deg,#222426,#0f1012);color:#fff; border-color:rgba(0,0,0,.45)}
    .theme-light .tile.blk .face, .theme-light .tile.blk .flip{background:linear-gradient(180deg,#eef2f6,#e4e8ee);color:#111; border-color:#cfd6de}

    .face{position:absolute;left:0;width:100%;height:#{TILE_H/2}px;overflow:hidden;
      display:block;border:1px solid; transform:translateZ(0)}
    .face.top{top:0} .face.bottom{bottom:0}

    .glyph{
      position:absolute;left:0;top:0;width:100%;height:#{TILE_H}px;line-height:#{TILE_H}px;
      text-align:center;font-weight:700;font-size:#{FONT_SZ}px;letter-spacing:-0.1px;
      text-shadow:none;font-variant-numeric:tabular-nums;
      padding:0 #{GLYPH_HPAD}px; transform:translateZ(0) scaleX(#{GLYPH_SCALE_X});
      transform-origin:center center;}
    .theme-dark .glyph{color:#fff}
    .theme-light .glyph{color:#0e1013}

    /* Header color override (only when forced) */
    #{headerColorRule}

    .face.top   .glyph{top:0}
    .face.bottom .glyph{top:-#{TILE_H/2}px}
    .flip-top    .glyph{top:0}
    .flip-bottom .glyph{top:-#{TILE_H/2}px}

    .hinge{position:absolute;left:12px;right:12px;top:50%;transform:translateY(-50%);
      height:2px;border-radius:2px; opacity:.70; z-index:1;}
    .theme-dark .hinge{background:linear-gradient(90deg, rgba(0,0,0,.45), rgba(255,255,255,.08) 50%, rgba(0,0,0,.45))}
    .theme-light .hinge{background:linear-gradient(90deg, rgba(0,0,0,.18), rgba(255,255,255,.85) 50%, rgba(0,0,0,.18))}
    .pin{position:absolute;width:6px;height:6px;top:calc(50% - 3px);border-radius:50%}
    .theme-dark .pin{background:#0d0d10; box-shadow: inset 0 1px 0 rgba(255,255,255,.14), 0 0 0 1px rgba(0,0,0,.45)}
    .theme-light .pin{background:#e8edf3; box-shadow: inset 0 1px 0 rgba(255,255,255,.9), 0 0 0 1px rgba(0,0,0,.15)}

    .tile.animate .pin{ opacity:.55; transform:scale(.9); transition:opacity .2s linear }
    .tile.animate .hinge{ opacity:.6 }

    .flip{position:absolute;left:0;width:100%;height:#{TILE_H/2}px;overflow:hidden;
      display:block;border:1px solid; z-index:5; visibility:hidden;
      backface-visibility:hidden; transform:translateZ(0)}
    .theme-dark .flip{border-color:rgba(0,0,0,.45)}
    .theme-light .flip{border-color:#cfd6de}
    .flip-top{top:0;transform-origin:bottom center}
    .flip-bottom{bottom:0;transform-origin:top center;transform:rotateX(90deg)}

    .tile.animate{--bt: 200ms}
    .tile.animate .flip{visibility:visible}
    .tile.animate .flip-top{animation:flipTop 260ms cubic-bezier(.2,.9,.3,1) var(--st) forwards}
    .tile.animate .flip-bottom{animation:flipBottom 260ms cubic-bezier(.2,.9,.3,1) calc(var(--st) + var(--bt)) forwards}

    @keyframes flipTop{0%{transform:rotateX(0)}55%{transform:rotateX(-100deg)}100%{transform:rotateX(-180deg);visibility:hidden}}
    @keyframes flipBottom{0%{transform:rotateX(90deg)}100%{transform:rotateX(0)}}

    @media (prefers-reduced-motion: reduce){
      .tile.animate .flip{animation:none !important; visibility:visible !important; transform:none !important;}
    }

    .theme-toggle{
      position:absolute; right:12px; top:50%; transform:translateY(-45%);
      width:38px; height:38px; border-radius:10px;
      display:flex; align-items:center; justify-content:center; cursor:pointer; pointer-events:auto;
      background:transparent; border-color:transparent; box-shadow:none; z-index:10;
      color:#b08900;
    }
    .theme-toggle svg{width:22px; height:22px}
  </style>
  """

  """
  #{css}
  <div class="sf-root" style="transform: #{transform}">
    <div class="frame #{themeClass}">
      <div class="board #{themeClass}">
        <div class="header">
          <div class="group header-group">#{headerTimeHtml}</div>
          <div class="group header-group">#{headerCityHtml}</div>
          <div class="theme-toggle" id="sf-theme-toggle" title="Toggle theme"
               onclick="return window.__toggleSplitflapTheme && window.__toggleSplitflapTheme()">
            #{icon}
          </div>
        </div>
        <div class="grid">
          #{rows.join('')}
        </div>
      </div>
    </div>
  </div>
  """

# Optional console helpers
onLoad: ->
  window.SplitFlapSetCities = (arr) -> window._flipCitiesOverride = arr
  window.SplitFlapSetHeaders = (h) ->
    HEADERS.time = h?.time ? HEADERS.time
    HEADERS.city = h?.city ? HEADERS.city
