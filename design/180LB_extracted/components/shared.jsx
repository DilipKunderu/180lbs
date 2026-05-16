// Shared atoms for all three variations
// Color tokens, typography, icons, common chrome

const ACT = {
  // surfaces
  bg: '#000000',
  surface: '#0A0A0A',
  surface2: '#141414',
  surface3: '#1C1C1E',
  hairline: 'rgba(255,255,255,0.08)',
  hairline2: 'rgba(255,255,255,0.14)',

  // text
  text: '#FFFFFF',
  textDim: 'rgba(255,255,255,0.55)',
  textMute: 'rgba(255,255,255,0.32)',
  textFaint: 'rgba(255,255,255,0.18)',

  // accents
  lime: 'oklch(0.88 0.18 130)',     // primary action — vital lime
  limeDim: 'oklch(0.88 0.18 130 / 0.18)',
  limeText: '#000',
  warn: 'oklch(0.78 0.16 60)',       // amber
  ok: 'oklch(0.78 0.14 155)',
  red: 'oklch(0.68 0.22 25)',
};

const TYPE = {
  display: '-apple-system, "SF Pro Display", system-ui, sans-serif',
  text: '-apple-system, "SF Pro Text", system-ui, sans-serif',
  mono: '"SF Mono", "JetBrains Mono", ui-monospace, monospace',
};

// Tiny icon set — minimal SF-symbol-ish strokes
const Icon = {
  check: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none">
      <path d="M3 8.5L6.5 12L13 4.5" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  play: (s = 16, c = '#000') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill={c}>
      <path d="M3.5 2.5L13 8L3.5 13.5V2.5Z"/>
    </svg>
  ),
  pause: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill={c}>
      <rect x="3.5" y="2.5" width="3" height="11" rx="1"/>
      <rect x="9.5" y="2.5" width="3" height="11" rx="1"/>
    </svg>
  ),
  flame: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none">
      <path d="M8 1.5C8 4 5 5 5 8.5C5 11.5 6.5 13.5 8 13.5C9.5 13.5 11 11.5 11 8.5C11 7 10 6 9.5 5C9 6 8 6.5 8 1.5Z" stroke={c} strokeWidth="1.4" strokeLinejoin="round"/>
    </svg>
  ),
  bolt: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none">
      <path d="M9 1L3 9H7L7 15L13 7H9L9 1Z" fill={c}/>
    </svg>
  ),
  fork: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none">
      <path d="M4 1V6C4 7 4.5 7.5 5.5 7.5V15M5.5 7.5C6.5 7.5 7 7 7 6V1M11.5 1V8C10.5 8 10 8.5 10 9.5V15" stroke={c} strokeWidth="1.4" strokeLinecap="round"/>
    </svg>
  ),
  dumbbell: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none">
      <rect x="1" y="5" width="2" height="6" rx="0.5" fill={c}/>
      <rect x="3" y="6" width="1.5" height="4" rx="0.4" fill={c}/>
      <rect x="4.5" y="7" width="7" height="2" fill={c}/>
      <rect x="11.5" y="6" width="1.5" height="4" rx="0.4" fill={c}/>
      <rect x="13" y="5" width="2" height="6" rx="0.5" fill={c}/>
    </svg>
  ),
  arrow: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none">
      <path d="M3 8H13M13 8L8.5 3.5M13 8L8.5 12.5" stroke={c} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  chevR: (s = 12, c = 'rgba(255,255,255,0.4)') => (
    <svg width={s * 0.6} height={s} viewBox="0 0 8 14" fill="none">
      <path d="M1 1L7 7L1 13" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  plus: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none">
      <path d="M8 3V13M3 8H13" stroke={c} strokeWidth="2" strokeLinecap="round"/>
    </svg>
  ),
  clock: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none">
      <circle cx="8" cy="8" r="6.3" stroke={c} strokeWidth="1.4"/>
      <path d="M8 4.5V8L10.5 9.5" stroke={c} strokeWidth="1.4" strokeLinecap="round"/>
    </svg>
  ),
  swap: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none">
      <path d="M2 5H13M13 5L10 2.5M13 5L10 7.5M14 11H3M3 11L6 8.5M3 11L6 13.5" stroke={c} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  more: (s = 16, c = '#fff') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill={c}>
      <circle cx="3" cy="8" r="1.4"/><circle cx="8" cy="8" r="1.4"/><circle cx="13" cy="8" r="1.4"/>
    </svg>
  ),
};

// Striped placeholder for imagery (food shots, etc.)
function Placeholder({ width = '100%', height = 200, label, dark = true, radius = 12, style = {} }) {
  return (
    <div style={{
      width, height, borderRadius: radius,
      background: dark
        ? 'repeating-linear-gradient(135deg, #161616, #161616 8px, #1a1a1a 8px, #1a1a1a 16px)'
        : 'repeating-linear-gradient(135deg, #1f1f1f, #1f1f1f 8px, #242424 8px, #242424 16px)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: TYPE.mono, fontSize: 11, color: 'rgba(255,255,255,0.32)',
      letterSpacing: 0.4, textTransform: 'uppercase',
      ...style,
    }}>{label}</div>
  );
}

// Tiny mono tag
function Tag({ children, color = 'rgba(255,255,255,0.55)', style = {} }) {
  return (
    <span style={{
      fontFamily: TYPE.mono, fontSize: 10.5, letterSpacing: 0.6,
      textTransform: 'uppercase', color,
      ...style,
    }}>{children}</span>
  );
}

// Status bar + home indicator wrapper for content (no IOSDevice frame chrome)
function ScreenChrome({ children, time = '7:24', dark = true, hideStatus, hideHome }) {
  return (
    <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column' }}>
      {!hideStatus && (
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 20 }}>
          <IOSStatusBar dark={dark} time={time} />
        </div>
      )}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {children}
      </div>
      {!hideHome && (
        <div style={{
          position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 60,
          height: 34, display: 'flex', justifyContent: 'center', alignItems: 'flex-end',
          paddingBottom: 8, pointerEvents: 'none',
        }}>
          <div style={{
            width: 139, height: 5, borderRadius: 100,
            background: dark ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.25)',
          }} />
        </div>
      )}
    </div>
  );
}

Object.assign(window, { ACT, TYPE, Icon, Placeholder, Tag, ScreenChrome });
