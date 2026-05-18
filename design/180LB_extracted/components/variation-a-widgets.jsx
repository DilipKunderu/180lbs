// Variation A · Home Screen widgets — Small, Medium, Large

// Small — 170×170 — hero countdown
function WidgetSmall() {
  return (
    <div style={{
      width: 170, height: 170, background: '#0A0A0A',
      borderRadius: 22, padding: 16, boxSizing: 'border-box',
      position: 'relative', fontFamily: TYPE.display,
      display: 'flex', flexDirection: 'column',
      justifyContent: 'center', alignItems: 'center',
    }}>
      <div style={{
        color: ACT.text, fontSize: 32, fontWeight: 800,
        letterSpacing: -1.2, lineHeight: 1,
        fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
      }}>
        6:18
      </div>
      <div style={{
        color: ACT.textMute, fontSize: 9, fontFamily: TYPE.mono,
        letterSpacing: 1.2, textTransform: 'uppercase', marginTop: 6,
      }}>
        UNTIL EAT
      </div>

      {/* Lime dot — Act mark */}
      <div style={{
        position: 'absolute', bottom: 14, left: 14,
        width: 8, height: 8, borderRadius: 8, background: ACT.lime,
      }} />

      {/* Weight stamp */}
      <div style={{
        position: 'absolute', bottom: 14, right: 14,
        color: ACT.textMute, fontSize: 9, fontFamily: TYPE.mono,
        letterSpacing: 0.6,
      }}>
        308.4 LB
      </div>
    </div>
  );
}

// Medium — 350×170 — small + status column
function WidgetMedium() {
  const checks = [
    ['Weight', '✓'],
    ['Lift',   '✓'],
    ['Swim',   '✓'],
    ['Walk',   '○'],
  ];
  return (
    <div style={{
      width: 350, height: 170, background: '#0A0A0A',
      borderRadius: 22, padding: 16, boxSizing: 'border-box',
      fontFamily: TYPE.display,
      display: 'flex', gap: 16, position: 'relative',
    }}>
      {/* Left — countdown */}
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        justifyContent: 'center', alignItems: 'flex-start',
        position: 'relative',
      }}>
        <div style={{
          color: ACT.text, fontSize: 40, fontWeight: 800,
          letterSpacing: -1.6, lineHeight: 1,
          fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
        }}>
          6:18
        </div>
        <div style={{
          color: ACT.textMute, fontSize: 9, fontFamily: TYPE.mono,
          letterSpacing: 1.2, textTransform: 'uppercase', marginTop: 6,
        }}>
          UNTIL EAT
        </div>

        {/* Lime mark */}
        <div style={{
          position: 'absolute', bottom: 0, left: 0,
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <span style={{
            width: 7, height: 7, borderRadius: 7, background: ACT.lime,
          }} />
          <span style={{
            color: ACT.textMute, fontSize: 9, fontFamily: TYPE.mono,
            letterSpacing: 1.2,
          }}>308.4 LB</span>
        </div>
      </div>

      {/* Right — checks + hydration */}
      <div style={{
        flex: 1.05, display: 'flex', flexDirection: 'column',
        gap: 0, justifyContent: 'center',
      }}>
        {checks.map(([k, v], i) => (
          <div key={k} style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            padding: '5px 0',
            borderBottom: i < checks.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
          }}>
            <span style={{
              color: ACT.textDim, fontSize: 11, fontFamily: TYPE.mono,
              letterSpacing: 0.4,
            }}>{k}</span>
            <span style={{
              color: v === '✓' ? ACT.lime : ACT.textMute,
              fontSize: 11, fontFamily: TYPE.mono,
            }}>{v}</span>
          </div>
        ))}

        {/* Hydration */}
        <div style={{ marginTop: 10 }}>
          <div style={{ display: 'flex', gap: 3 }}>
            {[1, 0, 0].map((v, i) => (
              <div key={i} style={{
                flex: 1, height: 4, borderRadius: 2,
                background: v ? ACT.lime : ACT.hairline,
              }} />
            ))}
          </div>
          <div style={{
            color: ACT.textMute, fontSize: 9, fontFamily: TYPE.mono,
            letterSpacing: 0.6, marginTop: 5,
          }}>
            HYDRATE · 1 / 3 L
          </div>
        </div>
      </div>
    </div>
  );
}

// Large — 350×370 — countdown + day timeline + macros
function WidgetLarge() {
  const rows = [
    { time: '5:00',  label: 'Weight',   status: '✓', done: true },
    { time: '5:30',  label: 'Lift',     status: '✓', done: true },
    { time: '6:45',  label: 'Swim',     status: '✓', done: true },
    { time: '9–15',  label: 'Hydrate',  status: '1/3', done: false },
    { time: '18:00', label: 'Eat',      status: '○', done: false },
    { time: '21:30', label: 'Sleep',    status: '○', done: false },
  ];

  return (
    <div style={{
      width: 350, height: 370, background: '#0A0A0A',
      borderRadius: 22, padding: 18, boxSizing: 'border-box',
      fontFamily: TYPE.display,
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Top — countdown */}
      <div style={{
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        paddingTop: 6, paddingBottom: 16,
        borderBottom: `1px solid ${ACT.hairline}`,
      }}>
        <div style={{
          color: ACT.text, fontSize: 56, fontWeight: 800,
          letterSpacing: -2.2, lineHeight: 1,
          fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
        }}>
          6:18
        </div>
        <div style={{
          color: ACT.textMute, fontSize: 9, fontFamily: TYPE.mono,
          letterSpacing: 1.2, textTransform: 'uppercase', marginTop: 8,
        }}>
          UNTIL EAT
        </div>
      </div>

      {/* Timeline */}
      <div style={{ flex: 1, padding: '6px 0', display: 'flex', flexDirection: 'column' }}>
        {rows.map((r, i) => (
          <div key={r.label} style={{
            display: 'flex', alignItems: 'baseline', gap: 12,
            padding: '7px 0',
            borderBottom: i < rows.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
            opacity: r.done ? 0.4 : 1,
          }}>
            <span style={{
              color: ACT.textMute, fontSize: 11, fontFamily: TYPE.mono,
              width: 46, flexShrink: 0,
            }}>{r.time}</span>
            <span style={{
              flex: 1, color: ACT.text, fontSize: 14, fontWeight: 500,
              letterSpacing: -0.1,
              textDecoration: r.done ? 'line-through' : 'none',
            }}>{r.label}</span>
            <span style={{
              color: r.done ? ACT.lime : ACT.textMute,
              fontSize: 11, fontFamily: TYPE.mono,
            }}>{r.status}</span>
          </div>
        ))}
      </div>

      {/* Macros */}
      <div style={{
        display: 'flex', gap: 14,
        paddingTop: 12, borderTop: `1px solid ${ACT.hairline}`,
        color: ACT.textMute, fontSize: 11, fontFamily: TYPE.mono,
        letterSpacing: 0.4,
      }}>
        <span>0 / 2150 kcal</span>
        <span style={{ color: ACT.textFaint }}>·</span>
        <span>0 / 190 P</span>
      </div>
    </div>
  );
}

// Board — display all three on a single artboard with iOS home wallpaper context
function WidgetsBoard() {
  const Row = ({ label, sub, children }) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      <div style={{
        color: ACT.textMute, fontSize: 11,
        fontFamily: TYPE.mono, letterSpacing: 1.2,
        textTransform: 'uppercase',
      }}>{label}</div>
      <div style={{ display: 'flex', justifyContent: 'center' }}>{children}</div>
      <div style={{
        color: ACT.textDim, fontSize: 13, lineHeight: 1.4,
        fontFamily: TYPE.text, maxWidth: 360, textAlign: 'left',
      }}>{sub}</div>
    </div>
  );

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      fontFamily: TYPE.display,
      display: 'flex', flexDirection: 'column', gap: 28,
      padding: '60px 16px 42px', boxSizing: 'border-box',
      overflowY: 'auto',
    }}>
      <div style={{ padding: '0 8px' }}>
        <div style={{ color: ACT.textMute, fontSize: 11, fontFamily: TYPE.mono, letterSpacing: 1.2 }}>
          HOME SCREEN WIDGETS
        </div>
        <div style={{
          color: ACT.text, fontSize: 32, fontWeight: 800,
          letterSpacing: -1, marginTop: 6,
        }}>
          Three sizes.
        </div>
      </div>

      <div style={{ padding: '0 8px' }}>
        <Row label="Small · 170×170"
          sub="Countdown is the entire reason for the widget. Lime dot bottom-left, weight stamp bottom-right.">
          <WidgetSmall />
        </Row>
      </div>

      <div style={{ padding: '0 8px' }}>
        <Row label="Medium · 350×170"
          sub="Small contents on the left; today's 4 checks + hydration bar on the right.">
          <WidgetMedium />
        </Row>
      </div>

      <div style={{ padding: '0 8px' }}>
        <Row label="Large · 350×370"
          sub="Hero countdown, full day timeline (6 rows), macros row pinned to the bottom.">
          <WidgetLarge />
        </Row>
      </div>
    </div>
  );
}

Object.assign(window, { WidgetSmall, WidgetMedium, WidgetLarge, WidgetsBoard });
