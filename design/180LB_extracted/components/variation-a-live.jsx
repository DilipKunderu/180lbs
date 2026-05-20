// Variation A · Live Activities & Dynamic Island
// Three compact variants (default / hydration emergency / relapse day)
// Two expanded variants (normal / relapse day)
// Lock-screen layout = expanded layout

// One-time keyframes for compact animations
if (typeof document !== 'undefined' && !document.getElementById('act-la-anim')) {
  const s = document.createElement('style');
  s.id = 'act-la-anim';
  s.textContent = `
    @keyframes act-pulse { 0%,100%{opacity:1} 50%{opacity:0.45} }
    @keyframes act-flip {
      0%, 48% { opacity: 1; transform: translateY(0); }
      50%, 98% { opacity: 0; transform: translateY(-2px); pointer-events: none; }
    }
    @keyframes act-flip-b {
      0%, 48% { opacity: 0; transform: translateY(2px); pointer-events: none; }
      50%, 98% { opacity: 1; transform: translateY(0); }
    }
    .act-pulse { animation: act-pulse 1.6s ease-in-out infinite; }
    .act-flip-a { animation: act-flip 10s steps(1, end) infinite; }
    .act-flip-b { animation: act-flip-b 10s steps(1, end) infinite; }
  `;
  document.head.appendChild(s);
}

// ─────────────────────────────────────────────────────────────
// Dynamic Island chrome — a wide black pill, leading + trailing slots
// flank the camera cutout. Realistic-ish dimensions.
// ─────────────────────────────────────────────────────────────
function DIShell({ leading, trailing, dark = '#000' }) {
  return (
    <div style={{
      width: 'fit-content', minWidth: 360,
      background: dark, borderRadius: 999,
      padding: '8px 18px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      gap: 60, // visually reserves the camera punch
      position: 'relative',
      boxShadow: '0 1px 0 rgba(255,255,255,0.04)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        {leading}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        {trailing}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Compact A — default
// ─────────────────────────────────────────────────────────────
function LACompactA() {
  return (
    <DIShell
      leading={<>
        <span style={{
          width: 7, height: 7, borderRadius: 7,
          background: ACT.lime, display: 'inline-block',
        }} />
        <span style={{
          color: '#fff', fontSize: 11, fontFamily: TYPE.mono,
          fontWeight: 600, letterSpacing: 1.2,
        }}>ACT</span>
      </>}
      trailing={<>
        <span style={{
          color: '#fff', fontSize: 13, fontFamily: TYPE.mono,
          fontVariantNumeric: 'tabular-nums',
        }}>6:18</span>
      </>}
    />
  );
}

// ─────────────────────────────────────────────────────────────
// Compact B — hydration emergency
// ─────────────────────────────────────────────────────────────
function Droplet({ color = ACT.red, size = 12 }) {
  return (
    <svg width={size} height={size + 2} viewBox="0 0 12 14" fill="none">
      <path d="M6 1C6 3.5 2 5 2 8.5C2 10.98 3.79 13 6 13C8.21 13 10 10.98 10 8.5C10 5 6 3.5 6 1Z"
        fill={color}/>
    </svg>
  );
}

function LACompactB() {
  return (
    <DIShell
      leading={<Droplet color={ACT.red} size={13} />}
      trailing={
        <span className="act-pulse" style={{
          color: ACT.red, fontSize: 13, fontFamily: TYPE.mono,
          fontWeight: 700, letterSpacing: 0.6,
        }}>DRINK</span>
      }
    />
  );
}

// ─────────────────────────────────────────────────────────────
// Compact C — relapse day (alternates every 5s)
// ─────────────────────────────────────────────────────────────
function LACompactC() {
  return (
    <DIShell
      leading={
        <span style={{
          width: 9, height: 9, borderRadius: 9,
          border: `1.5px solid ${ACT.red}`, display: 'inline-block',
        }} />
      }
      trailing={
        <div style={{ position: 'relative', minWidth: 86, height: 18,
          display: 'flex', alignItems: 'center', justifyContent: 'flex-end' }}>
          <span className="act-flip-a" style={{
            position: 'absolute', right: 0, top: 0,
            color: '#fff', fontSize: 13, fontFamily: TYPE.mono,
            fontVariantNumeric: 'tabular-nums', lineHeight: '18px',
          }}>6:18</span>
          <span className="act-flip-b" style={{
            position: 'absolute', right: 0, top: 0,
            color: ACT.red, fontSize: 13, fontFamily: TYPE.mono,
            fontWeight: 700, letterSpacing: 0.6, lineHeight: '18px',
          }}>RESTART · 0</span>
        </div>
      }
    />
  );
}

// ─────────────────────────────────────────────────────────────
// Expanded — normal day. 390×160, #0A0A0A, 24pt radius.
// hydrationState: 'fresh' | 'warn' | 'critical'
// ─────────────────────────────────────────────────────────────
function LAExpanded({ hydrationState = 'fresh', relapse = false }) {
  const HYDRA = {
    fresh:    { accent: ACT.lime, oz: 84, label: 'NEXT SIP · 22 MIN' },
    warn:     { accent: ACT.warn, oz: 60, label: 'LATE 32 MIN' },
    critical: { accent: ACT.red,  oz: 22, label: 'LATE 1H 12M' },
  }[hydrationState];
  const pct = HYDRA.oz / 120;

  const checks = [
    ['Weigh', '✓'],
    ['Lift',  '✓'],
    ['Swim',  '✓'],
    ['Walk',  '○'],
  ];

  return (
    <div style={{
      width: 390, height: 160, background: '#0A0A0A',
      borderRadius: 24, padding: '16px 20px',
      boxSizing: 'border-box', fontFamily: TYPE.display,
      display: 'flex', flexDirection: 'column', gap: 10,
      border: relapse ? `2px solid ${ACT.red}` : 'none',
      position: 'relative',
    }}>
      {/* Row 1 — meal countdown */}
      <div>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          UNTIL EAT
        </div>
        <div style={{
          color: ACT.text, fontSize: 40, fontWeight: 800,
          letterSpacing: -1.6, lineHeight: 1,
          fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
          marginTop: 2,
        }}>
          06:18:04
        </div>
      </div>

      {/* Row 2 — hydration */}
      <div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Droplet color={HYDRA.accent} size={11} />
          <span style={{
            color: ACT.text, fontSize: 14, fontFamily: TYPE.mono,
            fontVariantNumeric: 'tabular-nums',
          }}>{HYDRA.oz} oz / 120 oz</span>
          <span style={{ flex: 1 }} />
          <span style={{
            color: HYDRA.accent === ACT.lime ? ACT.textMute : HYDRA.accent,
            fontSize: 11, fontFamily: TYPE.mono,
            letterSpacing: 0.8, textTransform: 'uppercase',
          }}>{HYDRA.label}</span>
        </div>
        <div style={{
          marginTop: 5, width: '100%', height: 4,
          background: 'rgba(255,255,255,0.06)', borderRadius: 2, overflow: 'hidden',
        }}>
          <div style={{
            width: `${pct * 100}%`, height: '100%',
            background: HYDRA.accent, borderRadius: 2,
          }} />
        </div>
      </div>

      {/* Row 3 — clean streak / relapse banner */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {relapse ? (
          // lava broken-arc
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
            <path d="M10 6A4 4 0 1 1 6 2" stroke={ACT.red} strokeWidth="1.5" strokeLinecap="round"/>
          </svg>
        ) : (
          <span style={{
            width: 10, height: 10, borderRadius: 10,
            border: `1.5px solid ${ACT.lime}`, display: 'inline-block',
          }} />
        )}
        <span style={{
          color: relapse ? ACT.red : ACT.lime,
          fontSize: 14, fontFamily: TYPE.mono, fontWeight: 600,
          letterSpacing: 0.4,
        }}>
          {relapse ? 'RESTART · day 1 begins tomorrow' : 'CLEAN · 47 / 365 days'}
        </span>
        {!relapse && (
          <>
            <span style={{ flex: 1 }} />
            <span style={{
              color: ACT.textMute, fontSize: 11,
              fontFamily: TYPE.mono, letterSpacing: 0.8,
              textTransform: 'uppercase',
            }}>RECOVERY · DAY 47</span>
          </>
        )}
      </div>

      {/* Row 4 — today's 4 checks */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 0,
        color: ACT.textDim, fontSize: 12, fontFamily: TYPE.mono,
      }}>
        {checks.map(([k, v], i) => (
          <React.Fragment key={k}>
            {i > 0 && <span style={{ padding: '0 8px', color: ACT.textFaint }}>·</span>}
            <span style={{
              color: v === '✓' ? ACT.text : ACT.textMute,
            }}>{k} {v}</span>
          </React.Fragment>
        ))}
      </div>
    </div>
  );
}

function LAExpandedRelapse() {
  return <LAExpanded hydrationState="fresh" relapse={true} />;
}

// ─────────────────────────────────────────────────────────────
// Wrapper artboards — show compacts inside a fake status-bar context
// and expanded as standalone surfaces.
// ─────────────────────────────────────────────────────────────
function LACompactsBoard() {
  const Row = ({ label, children, sub }) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      <div style={{
        color: ACT.textMute, fontSize: 11,
        fontFamily: TYPE.mono, letterSpacing: 1.2,
        textTransform: 'uppercase',
      }}>{label}</div>
      <div style={{ display: 'flex', justifyContent: 'center' }}>{children}</div>
      <div style={{
        color: ACT.textDim, fontSize: 13, lineHeight: 1.4,
        fontFamily: TYPE.text, maxWidth: 320, textAlign: 'left',
      }}>{sub}</div>
    </div>
  );

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      paddingTop: 60, paddingBottom: 42, fontFamily: TYPE.display,
      display: 'flex', flexDirection: 'column', gap: 40,
      padding: '60px 24px 42px', boxSizing: 'border-box',
    }}>
      <div>
        <div style={{ color: ACT.textMute, fontSize: 11, fontFamily: TYPE.mono, letterSpacing: 1.2 }}>
          DYNAMIC ISLAND · COMPACT
        </div>
        <div style={{
          color: ACT.text, fontSize: 32, fontWeight: 800,
          letterSpacing: -1, marginTop: 6,
        }}>
          Three states.
        </div>
      </div>

      <Row label="A · Default"
        sub="The base state. Lime dot + ACT mark, hours-minutes countdown to the eat window.">
        <LACompactA />
      </Row>
      <Row label="B · Hydration emergency (60+ min stale)"
        sub="Replaces A when water lapses. Meal countdown disappears until a sip is logged. Slow pulse on DRINK.">
        <LACompactB />
      </Row>
      <Row label="C · Relapse day (24h after a relapse)"
        sub="Alternates between the countdown and RESTART · 0. Cannot be dismissed. Outranks B if both are active.">
        <LACompactC />
      </Row>
    </div>
  );
}

function LAExpandedBoard() {
  const Row = ({ label, children, sub }) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      <div style={{
        color: ACT.textMute, fontSize: 11,
        fontFamily: TYPE.mono, letterSpacing: 1.2,
        textTransform: 'uppercase',
      }}>{label}</div>
      <div style={{ display: 'flex', justifyContent: 'center' }}>{children}</div>
      <div style={{
        color: ACT.textDim, fontSize: 13, lineHeight: 1.4,
        fontFamily: TYPE.text, maxWidth: 360,
      }}>{sub}</div>
    </div>
  );

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      fontFamily: TYPE.display,
      display: 'flex', flexDirection: 'column', gap: 32,
      padding: '60px 16px 42px', boxSizing: 'border-box',
      overflowY: 'auto',
    }}>
      <div style={{ padding: '0 8px' }}>
        <div style={{ color: ACT.textMute, fontSize: 11, fontFamily: TYPE.mono, letterSpacing: 1.2 }}>
          LIVE ACTIVITY · EXPANDED
        </div>
        <div style={{
          color: ACT.text, fontSize: 32, fontWeight: 800,
          letterSpacing: -1, marginTop: 6,
        }}>
          Normal & relapse.
        </div>
      </div>

      <div style={{ padding: '0 8px' }}>
        <Row label="Normal · hydration FRESH"
          sub="Meal countdown, hydration progress, clean-streak row, today's 4 checks.">
          <LAExpanded hydrationState="fresh" />
        </Row>
      </div>

      <div style={{ padding: '0 8px' }}>
        <Row label="Normal · hydration WARN (amber)"
          sub="Hydration row shifts amber when 30 min late.">
          <LAExpanded hydrationState="warn" />
        </Row>
      </div>

      <div style={{ padding: '0 8px' }}>
        <Row label="Normal · hydration CRITICAL (lava)"
          sub="Lava when 1h+ late. Same row, escalated color.">
          <LAExpanded hydrationState="critical" />
        </Row>
      </div>

      <div style={{ padding: '0 8px' }}>
        <Row label="Relapse day · 24h"
          sub="2pt lava border. Clean-streak row replaced with RESTART. Other rows still functional — the rest of life doesn't stop.">
          <LAExpandedRelapse />
        </Row>
      </div>
    </div>
  );
}

Object.assign(window, {
  LACompactA, LACompactB, LACompactC,
  LAExpanded, LAExpandedRelapse,
  LACompactsBoard, LAExpandedBoard,
});
