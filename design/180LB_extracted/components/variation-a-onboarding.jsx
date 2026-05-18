// Variation A · Onboarding — 9-step flow
// Shared skeleton: black surface, hero word, sub-line, sticky CTA.

// Reusable shell. Children = body content between sub-line and CTA.
function OnbShell({ time = '9:41', hero, heroSize = 84, heroLetter = -3.5,
                   sub, secondary, children, cta, ctaKind = 'primary' }) {
  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0,
        display: 'flex', flexDirection: 'column' }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, letterSpacing: 0.4 }}>
          {time}
        </div>

        <div style={{
          fontSize: heroSize, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: heroLetter, color: ACT.text, marginTop: 16,
          fontVariantNumeric: 'tabular-nums',
        }}>
          {hero}
        </div>

        {sub && (
          <div style={{
            color: ACT.textDim, fontSize: 20, fontWeight: 500,
            letterSpacing: -0.3, marginTop: 12,
          }}>
            {sub}
          </div>
        )}

        <div style={{ marginTop: 32, flex: 1 }}>{children}</div>

        {secondary && (
          <div style={{ paddingBottom: 12 }}>{secondary}</div>
        )}
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          {cta}
        </button>
      </div>
    </div>
  );
}

// Reusable naked row
function OnbRow({ k, v, last }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'baseline', gap: 16,
      padding: '14px 0',
      borderBottom: last ? 'none' : `1px solid ${ACT.hairline}`,
    }}>
      <div style={{
        flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
        letterSpacing: -0.1,
      }}>{k}</div>
      <div style={{ color: ACT.textDim, fontSize: 14, fontFamily: TYPE.mono }}>{v}</div>
    </div>
  );
}

// 1 — Welcome
function OnbWelcome() {
  return (
    <OnbShell
      hero="Act."
      heroSize={120}
      heroLetter={-5}
      sub="No menus. No choices."
      cta="Begin"
    >
      <div style={{
        color: ACT.textMute, fontSize: 11,
        fontFamily: TYPE.mono, letterSpacing: 1.2,
        textTransform: 'uppercase',
      }}>
        9 STEPS
      </div>
    </OnbShell>
  );
}

// 2 — Profile
function OnbProfile() {
  const rows = [
    ['Height', `6'0"`],
    ['Sex',    'M'],
    ['Age',    '33'],
    ['Weight', '310 lb'],
    ['Goal',   '180'],
  ];
  return (
    <OnbShell hero="You." cta="Confirm">
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        {rows.map(([k, v], i) => (
          <OnbRow key={k} k={k} v={v} last={i === rows.length - 1} />
        ))}
      </div>
    </OnbShell>
  );
}

// 3 — Health
function OnbHealth() {
  return (
    <OnbShell
      hero="Health."
      sub="Connect Apple Health"
      cta="Allow"
    >
      <div style={{ marginBottom: 18 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase', marginBottom: 4,
        }}>
          READ
        </div>
        {['Weight', 'Steps', 'Sleep', 'Resting HR', 'HRV', 'VO2 max'].map((k, i, a) => (
          <OnbRow key={k} k={k} v="" last={i === a.length - 1} />
        ))}
      </div>
      <div>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase', marginBottom: 4,
        }}>
          WRITE
        </div>
        {['Workouts', 'Dietary energy', 'Dietary water'].map((k, i, a) => (
          <OnbRow key={k} k={k} v="" last={i === a.length - 1} />
        ))}
      </div>
    </OnbShell>
  );
}

// 4 — Notifications
function OnbNotifications() {
  const schedule = [
    ['5:00',  'Weigh-in'],
    ['5:15',  'Pre-workout'],
    ['7:00',  'Post-workout 16oz'],
    ['17:30', 'Reheat'],
    ['18:00', 'Eat'],
    ['19:00', 'Walk'],
    ['21:00', 'Sleep'],
  ];
  return (
    <OnbShell
      hero="Push."
      sub="7 a day. Useful ones."
      cta="Allow"
    >
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        {schedule.map(([t, k], i) => (
          <div key={k} style={{
            display: 'flex', alignItems: 'baseline', gap: 16,
            padding: '12px 0',
            borderBottom: i < schedule.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
          }}>
            <div style={{
              color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono,
              width: 48, flexShrink: 0,
            }}>{t}</div>
            <div style={{
              flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
              letterSpacing: -0.1,
            }}>{k}</div>
          </div>
        ))}
      </div>
    </OnbShell>
  );
}

// 5 — Scale
function OnbScale() {
  return (
    <OnbShell
      hero="Weigh."
      sub="Pair a smart scale."
      cta="I have Withings / Eufy / Renpho"
      secondary={
        <button style={{
          width: '100%', background: 'transparent', border: 'none',
          color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono,
          letterSpacing: 0.4, padding: '8px 0', cursor: 'pointer',
          textAlign: 'center',
        }}>
          Manual for now →
        </button>
      }
    >
      <div style={{
        color: ACT.textMute, fontSize: 11,
        fontFamily: TYPE.mono, letterSpacing: 1.2,
        textTransform: 'uppercase',
      }}>
        AUTO-SYNCS · 5:00 DAILY
      </div>
    </OnbShell>
  );
}

// 6 — Hydration
function OnbHydration() {
  return (
    <OnbShell
      hero="Sip."
      sub="Pair a Hidrate Spark PRO."
      cta="Already paired in Apple Health"
      secondary={
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <button style={{
            width: '100%', background: 'transparent', border: 'none',
            color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono,
            letterSpacing: 0.4, padding: '8px 0', cursor: 'pointer',
            textAlign: 'center',
          }}>
            Buy one ($65) →
          </button>
          <button style={{
            width: '100%', background: 'transparent', border: 'none',
            color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono,
            letterSpacing: 0.4, padding: '8px 0', cursor: 'pointer',
            textAlign: 'center',
          }}>
            Manual taps for now →
          </button>
        </div>
      }
    >
      <div style={{
        color: ACT.textDim, fontSize: 14, fontWeight: 500,
        lineHeight: 1.4, letterSpacing: -0.1, marginTop: 4,
      }}>
        Layer 2 accountability — 120 oz daily, escalating prompts when stale.
      </div>
    </OnbShell>
  );
}

// 7 — Quit
function OnbQuit() {
  const triggers = ['Social invitation', 'Stress', 'Boredom', 'After dinner', 'Specific person', 'Specific place'];
  const selected = new Set(['Stress', 'After dinner']);

  return (
    <OnbShell
      hero="Quit."
      sub="Today is Day 0. Zero hookah from this moment."
      cta="I am a non-smoker."
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
        {/* Triggers */}
        <div>
          <div style={{
            color: ACT.textMute, fontSize: 11,
            fontFamily: TYPE.mono, letterSpacing: 1.2,
            textTransform: 'uppercase', marginBottom: 12,
          }}>
            TRIGGERS
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {triggers.map(t => {
              const on = selected.has(t);
              return (
                <span key={t} style={{
                  padding: '8px 12px', borderRadius: 999,
                  fontSize: 13, fontWeight: 500, letterSpacing: -0.1,
                  background: on ? ACT.lime : 'transparent',
                  color: on ? '#000' : ACT.textDim,
                  border: on ? '1px solid transparent' : `1px solid ${ACT.hairline2}`,
                  cursor: 'pointer',
                }}>{t}</span>
              );
            })}
          </div>
        </div>

        {/* Your why */}
        <div>
          <div style={{
            color: ACT.textMute, fontSize: 11,
            fontFamily: TYPE.mono, letterSpacing: 1.2,
            textTransform: 'uppercase', marginBottom: 10,
          }}>
            YOUR WHY
          </div>
          <div style={{
            padding: '14px 0',
            borderBottom: `1px solid ${ACT.hairline}`,
            color: ACT.textMute, fontSize: 14, fontFamily: TYPE.mono,
            letterSpacing: 0.2,
          }}>
            One sentence — why are you quitting?
          </div>
        </div>

        {/* Stakes */}
        <button style={{
          background: 'transparent', border: 'none', padding: 0,
          color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono,
          letterSpacing: 0.4, textAlign: 'left', cursor: 'pointer',
        }}>
          Add stakes later →
        </button>
      </div>
    </OnbShell>
  );
}

// 8 — Rotation
function OnbRotation() {
  const weeks = [
    { w: 'Week 1', open: true,  dishes: ['Salmon coconut curry', 'Beef chili'] },
    { w: 'Week 2', open: false, dishes: [] },
    { w: 'Week 3', open: false, dishes: [] },
    { w: 'Week 4', open: false, dishes: [] },
  ];
  return (
    <OnbShell hero="Eat." sub="Week 1 of 4" cta="Looks good">
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        {weeks.map((wk, i) => (
          <div key={wk.w} style={{
            borderBottom: i < weeks.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
            padding: '12px 0',
          }}>
            <div style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            }}>
              <span style={{
                color: wk.open ? ACT.text : ACT.textDim,
                fontSize: 16, fontWeight: wk.open ? 700 : 500,
                letterSpacing: -0.2,
              }}>{wk.w}</span>
              <span style={{
                color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono,
              }}>{wk.open ? '−' : '+'}</span>
            </div>
            {wk.open && (
              <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 4 }}>
                {wk.dishes.map(d => (
                  <div key={d} style={{
                    color: ACT.textDim, fontSize: 14, padding: '4px 0',
                    letterSpacing: -0.1,
                  }}>{d}</div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </OnbShell>
  );
}

// 9 — Grocery
function OnbGrocery() {
  const cats = [
    ['Proteins', '6'],
    ['Grains',   '3'],
    ['Produce',  '11'],
    ['Dairy',    '2'],
    ['Pantry',   '8'],
  ];
  return (
    <OnbShell
      hero="Shop."
      sub="Saturday list, ready."
      cta="Send to Reminders"
    >
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        {cats.map(([k, v], i) => (
          <OnbRow key={k} k={k} v={`${v} items`} last={i === cats.length - 1} />
        ))}
      </div>
    </OnbShell>
  );
}

Object.assign(window, {
  OnbWelcome, OnbProfile, OnbHealth, OnbNotifications, OnbScale,
  OnbHydration, OnbQuit, OnbRotation, OnbGrocery,
});
