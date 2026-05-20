// Variation A — COMMAND (minimalist)
// Numbers and the thing. Nothing else.

// A1 — Today · OMAD fasted daytime state
// Eat window: 18:00–19:00. This is the long stretch in between.
function CmdToday({ onOpen }) {
  const remaining = [
    { time: '07:00', label: 'Lift',  done: true },
    { time: '09:30', label: 'Swim',  done: true },
    { time: '16:00', label: 'Walk',  done: false },
    { time: '22:30', label: 'Sleep', done: false },
  ];

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, letterSpacing: 0.4 }}>
          11:42
        </div>

        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text, marginTop: 16,
        }}>
          Fast.
        </div>

        {/* Countdown — the hero */}
        <div style={{ marginTop: 40 }}>
          <div style={{
            fontSize: 72, fontWeight: 700, lineHeight: 1,
            letterSpacing: -2, color: ACT.text,
            fontFamily: TYPE.mono,
            fontVariantNumeric: 'tabular-nums',
          }}>
            06:18:04
          </div>
          <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, marginTop: 8 }}>
            until eat
          </div>
        </div>

        {/* Hydration — continuous bar (matches Live Activity Row 2) */}
        <div style={{ marginTop: 40 }}>
          <div style={{
            width: '100%', height: 4, borderRadius: 2,
            background: 'rgba(255,255,255,0.06)', overflow: 'hidden',
          }}>
            <div style={{
              width: '30%', height: '100%', background: ACT.lime, borderRadius: 2,
            }} />
          </div>
          <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, marginTop: 10 }}>
            Hydrate · 36 / 120 oz
          </div>
        </div>

        {/* Today's remaining checks */}
        <div style={{ marginTop: 40, display: 'flex', flexDirection: 'column' }}>
          {remaining.map((r, i) => (
            <div key={r.label} style={{
              display: 'flex', alignItems: 'baseline', gap: 16,
              padding: '14px 0',
              borderBottom: i < remaining.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
              opacity: r.done ? 0.35 : 1,
            }}>
              <div style={{
                color: ACT.textMute, fontFamily: TYPE.mono, fontSize: 13,
                width: 48, flexShrink: 0,
              }}>{r.time}</div>
              <div style={{
                flex: 1, color: ACT.text, fontSize: 20, fontWeight: 500,
                letterSpacing: -0.2, textAlign: 'right',
                textDecoration: r.done ? 'line-through' : 'none',
              }}>{r.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Passive CTA — water log */}
      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button onClick={onOpen} style={{
          width: '100%', height: 56, borderRadius: 18,
          background: ACT.surface, border: `1px solid ${ACT.hairline}`,
          color: ACT.textDim,
          fontFamily: TYPE.mono, fontSize: 13, letterSpacing: 0.4,
          cursor: 'pointer',
        }}>
          Drink water
        </button>
      </div>
    </div>
  );
}

// LiftScreen — shared layout for Day A / Day B
function LiftScreen({ progress, liftIdx, liftCount, elapsed, name, weight, reps, set, restMin, restSec }) {
  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column', fontFamily: TYPE.display,
      paddingTop: 60, overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontFamily: TYPE.mono, fontSize: 13 }}>
          <span style={{ color: ACT.textMute }}>{liftIdx} / {liftCount}</span>
          <span style={{ color: ACT.text }}>{elapsed}</span>
        </div>
        <div style={{ display: 'flex', gap: 4, marginTop: 14 }}>
          {progress.map((v, i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 2,
              background: v === 1 ? ACT.lime : v > 0 ? ACT.limeDim : ACT.hairline,
            }} />
          ))}
        </div>
      </div>

      <div style={{ padding: '32px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{
          fontSize: 72, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3, color: ACT.text,
        }}>
          {name}.
        </div>

        <div style={{ display: 'flex', gap: 40, marginTop: 56, alignItems: 'baseline', fontFamily: TYPE.display }}>
          <div>
            <div style={{ color: ACT.text, fontSize: 88, fontWeight: 800, letterSpacing: -3.5, lineHeight: 1, fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums' }}>
              {weight}
            </div>
            <div style={{ color: ACT.textMute, fontSize: 12, fontFamily: TYPE.mono, marginTop: 4 }}>lb</div>
          </div>
          <div style={{ color: ACT.textFaint, fontSize: 40, fontWeight: 400 }}>×</div>
          <div>
            <div style={{ color: ACT.text, fontSize: 88, fontWeight: 800, letterSpacing: -3.5, lineHeight: 1, fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums' }}>
              {reps}
            </div>
            <div style={{ color: ACT.textMute, fontSize: 12, fontFamily: TYPE.mono, marginTop: 4 }}>reps</div>
          </div>
        </div>

        <div style={{ marginTop: 64, color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono }}>
          {set} · Rest {restMin}:{String(restSec).padStart(2, '0')}
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', display: 'flex', gap: 10, flexShrink: 0 }}>
        <button style={{
          width: 56, height: 56, borderRadius: 18, background: ACT.surface2,
          border: `1px solid ${ACT.hairline}`, color: ACT.text,
          cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{Icon.swap(16)}</button>
        <button style={{
          flex: 1, height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Done
        </button>
      </div>
    </div>
  );
}

// Day A — Squat, Bench, Row, Plank, Face Pull
// Currently on Bench, set 2 of 3
function CmdWorkout() {
  return <LiftScreen
    progress={[1, 0.5, 0, 0, 0]}
    liftIdx={2} liftCount={5}
    elapsed="22:14"
    name="Bench"
    weight={135} reps={5}
    set="Set 2 / 3"
    restMin={2} restSec={30}
  />;
}

// Day B — Deadlift, OHP, Lat Pulldown, RDL, Tricep Pushdown
// First lift, single heavy set
function CmdWorkoutB() {
  return <LiftScreen
    progress={[0.5, 0, 0, 0, 0]}
    liftIdx={1} liftCount={5}
    elapsed="04:08"
    name="Deadlift"
    weight={185} reps={5}
    set="Set 1 / 1"
    restMin={3} restSec={0}
  />;
}

// Sunday batch cook session — orchestrator only.
// Act. does NOT contain recipes. The user keeps those in Paprika / NYT Cooking.
// This screen times the session and tracks which phase you're in. That's it.
const COOK_PHASE_NAMES = ['Prep', 'Sauces', 'Proteins', 'Portion', 'Wrap'];

function CmdCook({ phaseIdx = 2, recipes = [
  { name: 'Salmon coconut curry', url: '#' },
  { name: 'Beef chili',           url: '#' },
] }) {
  const isLastPhase = phaseIdx === COOK_PHASE_NAMES.length - 1;
  const phaseName = COOK_PHASE_NAMES[phaseIdx];
  const progress = COOK_PHASE_NAMES.map((_, i) =>
    i < phaseIdx ? 1 : i === phaseIdx ? 0.5 : 0
  );

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column', fontFamily: TYPE.display,
      paddingTop: 60, overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          SUNDAY COOK · 14:00
        </div>
      </div>

      <div style={{ padding: '24px 24px 0', flex: 1, display: 'flex', flexDirection: 'column', overflowY: 'auto', minHeight: 0 }}>
        {/* Fixed hero — never changes */}
        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text,
        }}>
          Cook.
        </div>

        {/* Row A — current phase */}
        <div style={{ marginTop: 40 }}>
          <div style={{
            color: ACT.textMute, fontSize: 11,
            fontFamily: TYPE.mono, letterSpacing: 1.2,
            textTransform: 'uppercase',
          }}>
            PHASE {phaseIdx + 1} / 5
          </div>
          <div style={{
            color: ACT.text, fontSize: 28, fontWeight: 700,
            letterSpacing: -0.8, marginTop: 6,
          }}>
            {phaseName}
          </div>
        </div>

        {/* Row B — phase elapsed timer */}
        <div style={{ marginTop: 32, display: 'flex', alignItems: 'center', gap: 20 }}>
          <div style={{ position: 'relative', width: 88, height: 88, flexShrink: 0 }}>
            <svg width="88" height="88" viewBox="0 0 88 88" style={{ transform: 'rotate(-90deg)' }}>
              <circle cx="44" cy="44" r="40" fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="4"/>
              <circle cx="44" cy="44" r="40" fill="none" stroke={ACT.lime} strokeWidth="4"
                strokeDasharray={Math.PI * 80} strokeDashoffset={Math.PI * 80 * 0.45} strokeLinecap="round"/>
            </svg>
          </div>
          <div>
            <div style={{
              color: ACT.text, fontSize: 44, fontWeight: 800,
              letterSpacing: -1.6, lineHeight: 1,
              fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
            }}>
              28:14
            </div>
            <div style={{ color: ACT.textMute, fontSize: 12, fontFamily: TYPE.mono, marginTop: 4 }}>
              phase elapsed
            </div>
          </div>
        </div>

        {/* Row C — recipe deep-links (only when configured) */}
        {recipes && recipes.length > 0 && (
          <div style={{ marginTop: 32 }}>
            <div style={{
              color: ACT.textMute, fontSize: 11,
              fontFamily: TYPE.mono, letterSpacing: 1.2,
              textTransform: 'uppercase',
            }}>
              RECIPES
            </div>
            <div style={{ marginTop: 4, display: 'flex', flexDirection: 'column' }}>
              {recipes.slice(0, 2).map((r, i, a) => (
                <a key={r.name} href={r.url} style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  padding: '12px 0',
                  borderBottom: i < a.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
                  color: ACT.lime, fontSize: 16, fontWeight: 500,
                  letterSpacing: -0.2, textDecoration: 'none',
                }}>
                  <span>{r.name}</span>
                  <span style={{ marginLeft: 12 }}>→</span>
                </a>
              ))}
            </div>
          </div>
        )}

        {/* Progress bar — below the rows */}
        <div style={{ display: 'flex', gap: 4, marginTop: 32 }}>
          {progress.map((v, i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 2,
              background: v === 1 ? ACT.lime : v > 0 ? ACT.limeDim : ACT.hairline,
            }} />
          ))}
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18,
          fontWeight: isLastPhase ? 800 : 700,
          letterSpacing: -0.3, cursor: 'pointer',
        }}>
          {isLastPhase ? 'Done.' : 'Next phase.'}
        </button>
      </div>
    </div>
  );
}

function CmdProgress() {
  // Week 1 of cut: 310 → 308. Few days of data.
  const points = [310, 310, 309.6, 309.2, 309, 308.6, 308.2, 308];
  const min = 178, max = 312;
  const path = points.map((p, i) => {
    const x = (i / (points.length - 1)) * 100;
    const y = ((max - p) / (max - min)) * 60;
    return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
  }).join(' ');
  const goalY = ((max - 180) / (max - min)) * 60;

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      fontFamily: TYPE.display, paddingTop: 60, overflowY: 'auto', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '20px 24px 60px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 96, fontWeight: 800, letterSpacing: -4, color: ACT.text, lineHeight: 0.9 }}>
            308
          </div>
          <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono }}>180</div>
        </div>
        <div style={{ color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono, marginTop: 4 }}>
          −2 · 128 to go
        </div>

        {/* Naked chart, no card */}
        <svg viewBox="0 0 100 60" preserveAspectRatio="none" style={{ width: '100%', height: 140, display: 'block', marginTop: 36 }}>
          <line x1="0" y1={goalY} x2="100" y2={goalY} stroke="rgba(255,255,255,0.18)" strokeWidth="0.3" strokeDasharray="1,1"/>
          <defs>
            <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={ACT.lime} stopOpacity="0.22"/>
              <stop offset="100%" stopColor={ACT.lime} stopOpacity="0"/>
            </linearGradient>
          </defs>
          <path d={`${path} L 100 60 L 0 60 Z`} fill="url(#g)" />
          <path d={path} fill="none" stroke={ACT.lime} strokeWidth="0.8" strokeLinecap="round" strokeLinejoin="round" vectorEffect="non-scaling-stroke"/>
          <circle cx="100" cy={((max - 308) / (max - min)) * 60} r="1.6" fill={ACT.lime}/>
        </svg>

        {/* Stats — naked rows, no cards */}
        <div style={{ marginTop: 36, display: 'flex', flexDirection: 'column' }}>
          {[
            ['Adherence', '94%'],
            ['Streak', '23'],
            ['Sleep', '7.4h'],
            ['Protein', '6/7'],
          ].map(([k, v], i, a) => (
            <div key={k} style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
              padding: '18px 0', borderBottom: i < a.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
            }}>
              <span style={{ color: ACT.textDim, fontSize: 16 }}>{k}</span>
              <span style={{ color: ACT.text, fontSize: 24, fontWeight: 700, letterSpacing: -0.5, fontFamily: TYPE.mono }}>{v}</span>
            </div>
          ))}
        </div>

        {/* Week dots — today is Wednesday */}
        <div style={{ marginTop: 36, display: 'flex', gap: 6, alignItems: 'flex-end', height: 64 }}>
          {[
            { d: 'M', m: 1, w: 1 },
            { d: 'T', m: 1, w: 0 },
            { d: 'W', m: 0.5, w: 0, today: true },
            { d: 'T', m: 0, w: 0 },
            { d: 'F', m: 0, w: 0 },
            { d: 'S', m: 0, w: 0 },
            { d: 'S', m: 0, w: 0 },
          ].map((d, i) => (
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <div style={{ width: '100%', height: 48, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', gap: 2 }}>
                <div style={{ height: `${d.m * 26}px`, background: d.m === 1 ? ACT.lime : d.m > 0 ? ACT.limeDim : 'rgba(255,255,255,0.06)', borderRadius: 2 }}/>
                <div style={{ height: `${d.w * 18}px`, background: d.w ? '#fff' : 'rgba(255,255,255,0.06)', borderRadius: 2 }}/>
              </div>
              <div style={{ color: d.today ? ACT.text : ACT.textMute, fontSize: 11, fontWeight: d.today ? 700 : 500, fontFamily: TYPE.mono }}>{d.d}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// Pre-workout — psychological readiness, not data
function CmdPreWorkout() {
  const prep = [
    { label: 'Water',               note: '24oz' },
    { label: 'Sodium',              note: '1g' },
    { label: 'Caffeine + creatine', note: '' },
  ];
  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, letterSpacing: 0.4 }}>
          5:15
        </div>

        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text, marginTop: 16,
        }}>
          Lift.
        </div>

        <div style={{
          color: ACT.textDim, fontSize: 24, fontWeight: 500,
          letterSpacing: -0.4, marginTop: 12,
        }}>
          Day A · 5 lifts · 50 min
        </div>

        <div style={{ marginTop: 56, display: 'flex', flexDirection: 'column' }}>
          {prep.map((p, i) => (
            <div key={p.label} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '14px 0',
              borderBottom: i < prep.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
            }}>
              {Icon.check(16, ACT.lime)}
              <div style={{
                flex: 1, color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono,
              }}>{p.label}</div>
              {p.note && (
                <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono }}>
                  {p.note}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Start
        </button>
      </div>
    </div>
  );
}

// Hydration — circular ring hero, three staleness states
function CmdHydration({ state = 'fresh' }) {
  const TARGET = 120;
  const states = {
    fresh: {
      oz: 84,
      accent: ACT.lime,
      context: 'NEXT SIP · 22 MIN',
      contextColor: ACT.textMute,
      contextSize: 11,
      contextLetter: 0.8,
      btn: 'Logged',
      btnBg: ACT.lime,
      btnFg: '#000',
      btnBorder: 'transparent',
      btnFont: TYPE.display,
      btnSize: 18, btnWeight: 700, btnLetter: -0.3,
    },
    stale: {
      oz: 48,
      accent: ACT.warn,
      context: 'LATE BY · 32 MIN',
      contextColor: ACT.warn,
      contextSize: 11,
      contextLetter: 0.8,
      glyph: true,
      btn: 'Drink now',
      btnBg: ACT.warn,
      btnFg: '#000',
      btnBorder: 'transparent',
      btnFont: TYPE.display,
      btnSize: 18, btnWeight: 700, btnLetter: -0.3,
    },
    dry: {
      oz: 22,
      accent: ACT.red,
      hero: 'Drink.',
      subhero: 'You are 3 sips behind.',
      context: 'LATE BY · 1H 12M',
      contextColor: ACT.red,
      contextSize: 11,
      contextLetter: 0.8,
      glyph: true,
      btn: 'DRINK NOW',
      btnBg: ACT.red,
      btnFg: '#000',
      btnBorder: 'transparent',
      btnFont: TYPE.display,
      btnSize: 18, btnWeight: 800, btnLetter: 1,
    },
  };
  const s = states[state];
  const pct = s.oz / TARGET;
  // ring geometry — 240×240, r=110, strokeWidth=8
  const R = 110;
  const C = 2 * Math.PI * R;

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
          12:00
        </div>

        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text, marginTop: 16,
        }}>
          {s.hero || 'Hydrate.'}
        </div>
        {s.subhero && (
          <div style={{
            color: ACT.textDim, fontSize: 16, fontWeight: 500,
            letterSpacing: -0.2, marginTop: 10,
          }}>
            {s.subhero}
          </div>
        )}

        {/* Giant ring */}
        <div style={{
          marginTop: 32, alignSelf: 'center',
          position: 'relative', width: 240, height: 240,
        }}>
          <svg width="240" height="240" viewBox="0 0 240 240" style={{ transform: 'rotate(-90deg)' }}>
            <circle cx="120" cy="120" r={R} fill="none"
              stroke="rgba(255,255,255,0.06)" strokeWidth="8"/>
            <circle cx="120" cy="120" r={R} fill="none"
              stroke={s.accent} strokeWidth="8"
              strokeDasharray={C} strokeDashoffset={C * (1 - pct)}
              strokeLinecap="round"/>
          </svg>
          <div style={{
            position: 'absolute', inset: 0,
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{
              color: ACT.text, fontSize: 80, fontWeight: 800,
              letterSpacing: -3, lineHeight: 1,
              fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
            }}>
              {s.oz}
            </div>
            <div style={{
              color: ACT.textMute, fontSize: 14, fontFamily: TYPE.mono,
              marginTop: 8, letterSpacing: 0.3,
            }}>
              oz · {Math.round(pct * 100)}%
            </div>
          </div>
        </div>

        {/* Context line */}
        <div style={{
          marginTop: 32, alignSelf: 'center',
          color: s.contextColor || s.accent,
          fontSize: s.contextSize || 13,
          fontFamily: TYPE.mono,
          fontWeight: s.contextColor ? 400 : 600,
          letterSpacing: s.contextLetter ?? 1.2,
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          {s.glyph && Icon.flame(11, s.contextColor || s.accent)}
          {s.context}
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <div style={{
          textAlign: 'center', color: ACT.textDim,
          fontSize: 13, fontFamily: TYPE.mono, marginBottom: 12,
        }}>
          Logged 12oz manually
        </div>
        <button style={{
          width: '100%', height: 56, borderRadius: 18,
          background: s.btnBg,
          border: `1px solid ${s.btnBorder}`,
          color: s.btnFg,
          fontFamily: s.btnFont, fontSize: s.btnSize,
          fontWeight: s.btnWeight, letterSpacing: s.btnLetter,
          cursor: 'pointer',
        }}>
          {s.btn}
        </button>
      </div>
    </div>
  );
}

// Reheat — weeknight eat window. The app tells you which container; you handle the rest.
function CmdReheat() {
  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, letterSpacing: 0.4 }}>
          17:30
        </div>

        <div style={{
          fontSize: 72, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3, color: ACT.text, marginTop: 16,
        }}>
          Reheat.
        </div>

        <Placeholder height={200} radius={18} label="SALMON COCONUT CURRY" style={{ marginTop: 28 }} />

        {/* Macros — mirror CmdToday */}
        <div style={{ display: 'flex', gap: 28, marginTop: 22, fontFamily: TYPE.mono }}>
          {[['2150', 'kcal'], ['190', 'P'], ['230', 'C'], ['60', 'F']].map(([v, k]) => (
            <div key={k}>
              <div style={{ color: ACT.text, fontSize: 22, fontWeight: 600 }}>{v}</div>
              <div style={{ color: ACT.textMute, fontSize: 11, marginTop: 2 }}>{k}</div>
            </div>
          ))}
        </div>

        <div style={{
          color: ACT.textDim, fontSize: 14, fontWeight: 500,
          letterSpacing: -0.1, marginTop: 18,
        }}>
          Container 1 · fridge
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Start meal.
        </button>
      </div>
    </div>
  );
}

// Eat window — 18:00–19:00. The one meal.
function CmdMeal() {
  const components = [
    { kind: 'Protein', detail: 'salmon 16 oz', macro: '95g' },
    { kind: 'Shake',   detail: 'whey 30g',     macro: '30g' },
    { kind: 'Carbs',   detail: 'rice 2c',      macro: '90g' },
  ];
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
          18:00
        </div>

        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text, marginTop: 16,
        }}>
          Eat.
        </div>

        {/* Today's dish */}
        <div style={{
          display: 'flex', alignItems: 'baseline', gap: 16,
          padding: '20px 0', borderBottom: `1px solid ${ACT.hairline}`,
          marginTop: 32,
        }}>
          <div style={{
            flex: 1, color: ACT.text, fontSize: 28, fontWeight: 600,
            letterSpacing: -0.6, lineHeight: 1.1,
          }}>
            Salmon coconut curry
          </div>
          <div style={{ color: ACT.textDim, fontSize: 14, fontFamily: TYPE.mono }}>
            2150 kcal
          </div>
        </div>

        {/* Meal components */}
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          {components.map((c, i, a) => (
            <div key={c.kind} style={{
              display: 'flex', alignItems: 'baseline', gap: 16,
              padding: '14px 0',
              borderBottom: i < a.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
            }}>
              <div style={{
                flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
                letterSpacing: -0.1,
              }}>
                {c.kind} · <span style={{ color: ACT.textDim }}>{c.detail}</span>
              </div>
              <div style={{ color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono }}>
                {c.macro}
              </div>
            </div>
          ))}
        </div>

        {/* Spacer pushes meal-window line to bottom */}
        <div style={{ flex: 1 }} />

        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase', paddingBottom: 4,
        }}>
          MEAL WINDOW · 18:00 – 19:00 · 14m left until reset
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', background: 'transparent', border: 'none',
          color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono,
          letterSpacing: 0.4, padding: '8px 0 14px', cursor: 'pointer',
        }}>
          Deviated →
        </button>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Logged + shake
        </button>
      </div>
    </div>
  );
}

// Walk — post-meal 20-min walk. HealthKit logs the rest.
function CmdWalk() {
  const R = 40;
  const C = 2 * Math.PI * R;
  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, letterSpacing: 0.4 }}>
          19:00
        </div>

        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text, marginTop: 16,
        }}>
          Walk.
        </div>

        {/* Timer */}
        <div style={{ marginTop: 56, display: 'flex', alignItems: 'center', gap: 20 }}>
          <div style={{ position: 'relative', width: 88, height: 88, flexShrink: 0 }}>
            <svg width="88" height="88" viewBox="0 0 88 88" style={{ transform: 'rotate(-90deg)' }}>
              <circle cx="44" cy="44" r={R} fill="none"
                stroke="rgba(255,255,255,0.08)" strokeWidth="4"/>
              <circle cx="44" cy="44" r={R} fill="none"
                stroke={ACT.lime} strokeWidth="4"
                strokeDasharray={C} strokeDashoffset={C}
                strokeLinecap="round"/>
            </svg>
          </div>
          <div>
            <div style={{
              color: ACT.text, fontSize: 44, fontWeight: 800,
              letterSpacing: -1.6, lineHeight: 1,
              fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
            }}>
              20:00
            </div>
            <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, marginTop: 4 }}>
              min
            </div>
          </div>
        </div>

        <div style={{
          marginTop: 48,
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          AUTO-LOGGED · HEALTHKIT
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Start
        </button>
      </div>
    </div>
  );
}

// End of day — final checks. Smoke row is the only forced choice in the app.
function CmdEOD() {
  // smokeState: 'unanswered' | 'expanded' | 'clean' | 'relapsed'
  const [smokeState, setSmokeState] = React.useState('unanswered');
  const answered = smokeState === 'clean' || smokeState === 'relapsed';

  const staticRows = [
    { label: 'Weight', value: '308.4 ▼0.6', color: ACT.textDim },
    { label: 'Lift',   value: '✓ Day A · 50m',  color: ACT.textDim },
    { label: 'Meal',   value: '✓ 2150 kcal · 192 P', color: ACT.textDim },
  ];

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, letterSpacing: 0.4 }}>
          21:00
        </div>

        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text, marginTop: 16,
        }}>
          Sleep.
        </div>

        <div style={{
          color: ACT.textDim, fontSize: 20, fontWeight: 500,
          letterSpacing: -0.3, marginTop: 12,
        }}>
          Lights out in 30m
        </div>

        {/* Today's checks */}
        <div style={{ marginTop: 40, display: 'flex', flexDirection: 'column' }}>
          {staticRows.map((r, i) => (
            <div key={r.label} style={{
              display: 'flex', alignItems: 'baseline', gap: 16,
              padding: '14px 0',
              borderBottom: `1px solid ${ACT.hairline}`,
            }}>
              <div style={{
                flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
                letterSpacing: -0.1,
              }}>
                {r.label}
              </div>
              <div style={{ color: r.color, fontSize: 14, fontFamily: TYPE.mono }}>
                {r.value}
              </div>
            </div>
          ))}

          {/* Smoke row — interactive */}
          {smokeState === 'unanswered' && (
            <div onClick={() => setSmokeState('expanded')}
              style={{
                display: 'flex', alignItems: 'baseline', gap: 16,
                padding: '14px 0', cursor: 'pointer',
              }}>
              <div style={{
                flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
                letterSpacing: -0.1,
              }}>
                Smoke
              </div>
              <div style={{
                color: ACT.lime, fontSize: 14, fontFamily: TYPE.mono,
                display: 'flex', alignItems: 'center', gap: 6,
              }}>
                <span style={{
                  display: 'inline-block', width: 12, height: 12, borderRadius: 6,
                  border: `1.5px solid ${ACT.lime}`,
                }} />
                check
              </div>
            </div>
          )}

          {smokeState === 'expanded' && (
            <div style={{ padding: '14px 0', display: 'flex', gap: 8 }}>
              <button
                onClick={() => setSmokeState('clean')}
                style={{
                  flex: 1, height: 56, borderRadius: 14, border: 'none',
                  background: ACT.lime, color: '#000',
                  fontFamily: TYPE.display, fontSize: 18, fontWeight: 700,
                  letterSpacing: -0.3, cursor: 'pointer',
                }}>
                Clean.
              </button>
              <button
                onClick={() => setSmokeState('relapsed')}
                style={{
                  flex: 1, height: 56, borderRadius: 14,
                  background: ACT.surface2,
                  border: `1px solid ${ACT.red}`,
                  color: ACT.red,
                  fontFamily: TYPE.display, fontSize: 18, fontWeight: 700,
                  letterSpacing: -0.3, cursor: 'pointer',
                }}>
                Log relapse.
              </button>
            </div>
          )}

          {smokeState === 'clean' && (
            <div style={{
              display: 'flex', alignItems: 'baseline', gap: 16,
              padding: '14px 0', opacity: 0.55,
            }}>
              <div style={{
                flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
                letterSpacing: -0.1,
              }}>
                Smoke
              </div>
              <div style={{ color: ACT.lime, fontSize: 14, fontFamily: TYPE.mono }}>
                ✓ Clean · day 48
              </div>
            </div>
          )}

          {smokeState === 'relapsed' && (
            <div style={{
              display: 'flex', alignItems: 'baseline', gap: 16,
              padding: '14px 0', opacity: 0.55,
            }}>
              <div style={{
                flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
                letterSpacing: -0.1,
              }}>
                Smoke
              </div>
              <div style={{ color: ACT.red, fontSize: 14, fontFamily: TYPE.mono }}>
                Logged
              </div>
            </div>
          )}
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button
          disabled={!answered}
          style={{
            width: '100%', height: 56, borderRadius: 18, border: 'none',
            background: answered ? ACT.lime : ACT.surface,
            color: answered ? ACT.limeText : ACT.textFaint,
            fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
            cursor: answered ? 'pointer' : 'not-allowed',
            border: answered ? 'none' : `1px solid ${ACT.hairline}`,
          }}>
          OK
        </button>
      </div>
    </div>
  );
}

// Morning weigh-in — number is the whole UI
function CmdWeighIn() {
  const pts = [310.0, 309.6, 309.2, 309.0, 308.8, 308.6, 308.4];
  const min = Math.min(...pts), max = Math.max(...pts);
  const path = pts.map((p, i) => {
    const x = (i / (pts.length - 1)) * 100;
    const y = ((max - p) / (max - min)) * 30;
    return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
  }).join(' ');

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, letterSpacing: 0.4 }}>
          5:00
        </div>

        {/* Numeric hero */}
        <div style={{
          fontSize: 120, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -5, color: ACT.text, marginTop: 24,
          fontFamily: TYPE.display, fontVariantNumeric: 'tabular-nums',
        }}>
          308.4
        </div>

        <div style={{
          color: ACT.textMute, fontSize: 16, fontFamily: TYPE.mono,
          letterSpacing: 1.2, textTransform: 'uppercase', marginTop: 18,
        }}>
          LB · ▼ 0.6 · 7-DAY AVG 309.1
        </div>

        {/* Sparkline */}
        <div style={{ marginTop: 36 }}>
          <svg viewBox="0 0 100 30" preserveAspectRatio="none"
            style={{ width: '100%', height: 40, display: 'block' }}>
            <path d={path} fill="none" stroke={ACT.lime} strokeWidth="0.8"
              strokeLinecap="round" strokeLinejoin="round"
              vectorEffect="non-scaling-stroke"/>
            <circle cx="100" cy={((max - pts[pts.length - 1]) / (max - min)) * 30} r="1.4" fill={ACT.lime}/>
          </svg>
          <div style={{
            display: 'flex', justifyContent: 'space-between', marginTop: 8,
            color: ACT.textMute, fontSize: 11, fontFamily: TYPE.mono, letterSpacing: 0.4,
          }}>
            <span>Wed</span>
            <span>Tue</span>
          </div>
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Good.
        </button>
      </div>
    </div>
  );
}

// Swim — recovery or solo. Same shell, different params.
function CmdSwim({ subline = 'Recovery · 30 min · Zone 2', duration = '0:00', hrTarget = '120–135' }) {
  const R = 110;
  const C = 2 * Math.PI * R;
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
          6:45
        </div>

        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text, marginTop: 16,
        }}>
          Swim.
        </div>

        <div style={{
          color: ACT.textDim, fontSize: 24, fontWeight: 500,
          letterSpacing: -0.4, marginTop: 12,
        }}>
          {subline}
        </div>

        {/* Ring */}
        <div style={{
          marginTop: 32, alignSelf: 'center',
          position: 'relative', width: 240, height: 240,
        }}>
          <svg width="240" height="240" viewBox="0 0 240 240" style={{ transform: 'rotate(-90deg)' }}>
            <circle cx="120" cy="120" r={R} fill="none"
              stroke="rgba(255,255,255,0.06)" strokeWidth="8"/>
            <circle cx="120" cy="120" r={R} fill="none"
              stroke={ACT.lime} strokeWidth="8"
              strokeDasharray={C} strokeDashoffset={C}
              strokeLinecap="round"/>
          </svg>
          <div style={{
            position: 'absolute', inset: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{
              color: ACT.text, fontSize: 80, fontWeight: 800,
              letterSpacing: -3, lineHeight: 1,
              fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
            }}>
              {duration}
            </div>
          </div>
        </div>

        <div style={{
          marginTop: 24, alignSelf: 'center',
          color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono,
          letterSpacing: 1.2, textTransform: 'uppercase',
        }}>
          HR target {hrTarget}
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Start
        </button>
      </div>
    </div>
  );
}

function CmdSwimSolo() {
  return <CmdSwim subline="Solo · 60 min · Zone 2/3" duration="0:00" hrTarget="120–145" />;
}

// Manual weigh-in pad — for days the scale doesn't sync
function CmdWeightPad() {
  // inject cursor blink once
  React.useEffect(() => {
    if (document.getElementById('act-blink')) return;
    const s = document.createElement('style');
    s.id = 'act-blink';
    s.textContent = '@keyframes act-blink {0%,49%{opacity:1}50%,100%{opacity:0}} .act-blink{animation:act-blink 1s steps(1) infinite}';
    document.head.appendChild(s);
  }, []);

  const keys = ['1','2','3','4','5','6','7','8','9','.','0','⌫'];

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          MANUAL WEIGH-IN
        </div>
      </div>

      {/* Entry field */}
      <div style={{ padding: '24px 24px 0', textAlign: 'center' }}>
        <div style={{
          color: ACT.text, fontSize: 96, fontWeight: 800,
          letterSpacing: -4, lineHeight: 1,
          fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
          display: 'inline-flex', alignItems: 'baseline',
        }}>
          <span>308.</span>
          <span className="act-blink" style={{
            display: 'inline-block', width: 4, height: 72,
            background: ACT.lime, marginLeft: 6, alignSelf: 'center',
          }} />
        </div>
        <div style={{
          color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono,
          marginTop: 8, letterSpacing: 0.4,
        }}>
          lb
        </div>
      </div>

      {/* Number pad */}
      <div style={{
        flex: 1, display: 'flex', alignItems: 'flex-end',
        padding: '0 16px',
      }}>
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
          gap: 10, width: '100%',
        }}>
          {keys.map(k => (
            <button key={k} style={{
              width: '100%', aspectRatio: '1 / 1', maxHeight: 80,
              borderRadius: 18, border: 'none',
              background: ACT.surface2, color: ACT.text,
              fontFamily: TYPE.display, fontSize: 28, fontWeight: 700,
              cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>{k}</button>
          ))}
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Logged
        </button>
      </div>
    </div>
  );
}

// Deviation log — photo + reason. No shame language.
function CmdDeviate() {
  const [reason, setReason] = React.useState('Eating out');
  const reasons = ['Eating out', 'Social event', 'Travel', "Just didn't follow plan"];

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          DEVIATED
        </div>
      </div>

      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{
          fontSize: 72, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3, color: ACT.text,
        }}>
          Off.
        </div>
        <div style={{
          color: ACT.textDim, fontSize: 18, fontWeight: 500,
          letterSpacing: -0.2, marginTop: 10,
        }}>
          Photo + reason. Move on.
        </div>

        <Placeholder height={280} radius={18} label="TAP TO ADD PHOTO" style={{ marginTop: 24 }} />

        {/* Reasons — radio rows */}
        <div style={{ marginTop: 24, display: 'flex', flexDirection: 'column' }}>
          {reasons.map((r, i) => {
            const on = reason === r;
            return (
              <div key={r} onClick={() => setReason(r)} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '14px 0',
                borderBottom: i < reasons.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
                cursor: 'pointer',
              }}>
                {on ? (
                  <div style={{
                    width: 20, height: 20, borderRadius: 10, background: ACT.lime,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>{Icon.check(12, '#000')}</div>
                ) : (
                  <div style={{
                    width: 20, height: 20, borderRadius: 10,
                    border: `1.5px solid ${ACT.hairline2}`,
                  }} />
                )}
                <span style={{
                  flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
                  letterSpacing: -0.1,
                }}>{r}</span>
              </div>
            );
          })}
        </div>

        {/* Numeric entries */}
        <div style={{ marginTop: 24, display: 'flex', flexDirection: 'column' }}>
          {[
            ['kcal (est)',    '—'],
            ['protein (est)', '—'],
          ].map(([k, v], i, a) => (
            <div key={k} style={{
              display: 'flex', alignItems: 'baseline', gap: 16,
              padding: '14px 0',
              borderBottom: i < a.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
              cursor: 'pointer',
            }}>
              <div style={{
                flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
                letterSpacing: -0.1,
              }}>{k}</div>
              <div style={{
                color: ACT.textDim, fontSize: 16, fontFamily: TYPE.mono,
                fontVariantNumeric: 'tabular-nums',
              }}>{v}</div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Logged
        </button>
      </div>
    </div>
  );
}

// Rotation editor — 4-week dish cycle. Settings screen, breaks the one-word rule.
function CmdRotation() {
  const weeks = [
    ['Week 1', ['Salmon coconut curry', 'Beef chili']],
    ['Week 2', ['Cod tikka',            'Chicken fajita bowl']],
    ['Week 3', ['Mahi vindaloo',        'Turkey enchilada bowl']],
    ['Week 4', ['Shrimp korma',         'Pork carnitas bowl']],
  ];

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          ROTATION · 4 WEEKS
        </div>
      </div>

      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        {weeks.map(([w, dishes]) => (
          <div key={w} style={{ marginBottom: 28 }}>
            <div style={{
              color: ACT.text, fontSize: 32, fontWeight: 700,
              letterSpacing: -0.8, marginBottom: 8,
            }}>
              {w}
            </div>
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              {dishes.map((d, i) => (
                <div key={d} style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  padding: '14px 0',
                  borderBottom: i < dishes.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
                  cursor: 'pointer',
                }}>
                  <span style={{
                    color: ACT.text, fontSize: 16, fontWeight: 500,
                    letterSpacing: -0.1,
                  }}>{d}</span>
                  {Icon.chevR(11)}
                </div>
              ))}
            </div>
          </div>
        ))}

        <button style={{
          background: 'transparent', border: 'none', padding: '12px 0',
          color: ACT.textDim, fontSize: 11, fontFamily: TYPE.mono,
          letterSpacing: 1.2, textTransform: 'uppercase', cursor: 'pointer',
          textAlign: 'left',
        }}>
          Restart cycle →
        </button>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Add custom dish
        </button>
      </div>
    </div>
  );
}

// Weekly review — stats + Apple Intelligence insight + suggested tweak.
function CmdReview() {
  const stats = [
    ['Adherence',     '94%'],
    ['Weight change', '−1.8 lb'],
    ['Lift PRs',      'Bench +10 · Row +5'],
    ['Swim total',    '4h 12m'],
  ];

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          WEEK 4 · REVIEW
        </div>
      </div>

      <div style={{ padding: '20px 24px 60px', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{
          fontSize: 72, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3, color: ACT.text,
        }}>
          Review.
        </div>

        {/* Stat rows */}
        <div style={{ marginTop: 32, display: 'flex', flexDirection: 'column' }}>
          {stats.map(([k, v], i) => (
            <div key={k} style={{
              display: 'flex', alignItems: 'baseline', gap: 16,
              padding: '18px 0',
              borderBottom: i < stats.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
            }}>
              <div style={{
                flex: 1, color: ACT.text, fontSize: 18, fontWeight: 500,
                letterSpacing: -0.2,
              }}>{k}</div>
              <div style={{
                color: ACT.text, fontSize: 18, fontWeight: 700,
                fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
              }}>{v}</div>
            </div>
          ))}
        </div>

        {/* Insight callout */}
        <div style={{
          marginTop: 28, padding: 24,
          background: ACT.surface2, borderRadius: 18,
        }}>
          <div style={{
            color: ACT.textMute, fontSize: 11,
            fontFamily: TYPE.mono, letterSpacing: 1.2,
            textTransform: 'uppercase', marginBottom: 12,
          }}>
            INSIGHT
          </div>
          <div style={{
            color: ACT.text, fontSize: 16, fontWeight: 500,
            lineHeight: 1.5, letterSpacing: -0.1,
          }}>
            Your weight loss is tracking 0.4 lb/week faster than target.
            Protein is consistently 8g under on swim-recovery days.
            Bump shake to 40g whey on Tue + Thu.
          </div>
          <div style={{
            marginTop: 18, display: 'flex', alignItems: 'center', gap: 16,
          }}>
            <button style={{
              height: 40, padding: '0 18px', borderRadius: 12, border: 'none',
              background: ACT.lime, color: ACT.limeText,
              fontFamily: TYPE.display, fontSize: 14, fontWeight: 700, letterSpacing: -0.2,
              cursor: 'pointer',
            }}>
              Apply
            </button>
            <button style={{
              background: 'transparent', border: 'none', padding: 0,
              color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono,
              letterSpacing: 0.4, cursor: 'pointer',
            }}>
              Not now →
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Saturday grocery list — categorized.
function CmdGrocery() {
  const cats = [
    ['Proteins', [
      ['Salmon',        '4 lb'],
      ['Ground beef',   '3.5 lb'],
    ]],
    ['Grains + Legumes', [
      ['Basmati rice',  '4.5 c dry'],
      ['Kidney beans',  '2 cans'],
      ['Black beans',   '2 cans'],
    ]],
    ['Produce', [
      ['Cucumber',      '2'],
      ['Tomato',        '4'],
      ['Onion',         '3'],
      ['Cilantro',      '1 bunch'],
      ['Lime',          '6'],
      ['Bell pepper',   '2'],
    ]],
    ['Dairy + Eggs', [
      ['Greek yogurt',  '1 qt'],
      ['Shredded cheese', '8 oz'],
      ['Sour cream',    '1 c'],
    ]],
    ['Pantry', null], // assume stocked
    ['Bread + Tortillas', [
      ['Parathas (frozen)', '1 pack'],
      ['Corn tortillas',    '1 pack'],
    ]],
  ];

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          SHOP · SAT · WEEK 1
        </div>
      </div>

      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{
          fontSize: 72, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3, color: ACT.text,
        }}>
          Shop.
        </div>

        <div style={{ marginTop: 32, display: 'flex', flexDirection: 'column', gap: 24 }}>
          {cats.map(([cat, items]) => (
            <div key={cat}>
              <div style={{
                color: ACT.textMute, fontSize: 11,
                fontFamily: TYPE.mono, letterSpacing: 1.2,
                textTransform: 'uppercase', marginBottom: 4,
              }}>
                {cat}
              </div>
              {items ? (
                <div style={{ display: 'flex', flexDirection: 'column' }}>
                  {items.map(([k, v], i) => (
                    <div key={k} style={{
                      display: 'flex', alignItems: 'baseline', gap: 16,
                      padding: '12px 0',
                      borderBottom: i < items.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
                    }}>
                      <div style={{
                        flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
                        letterSpacing: -0.1,
                      }}>{k}</div>
                      <div style={{
                        color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono,
                        fontVariantNumeric: 'tabular-nums',
                      }}>{v}</div>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{
                  color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono,
                  fontStyle: 'italic', padding: '12px 0',
                }}>
                  whey, ghee, oil, spices — assume stocked
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Send to Reminders
        </button>
      </div>
    </div>
  );
}

// Settings hub — no hero, no CTA. Just sectioned naked rows.
function CmdSettings() {
  const sections = [
    ['Profile', [
      ['Weight',              '308.4'],
      ['Goal',                '180'],
      ['Daily kcal target',   '2150'],
      ['Protein target',      '190 g'],
    ]],
    ['Schedule', [
      ['Wake',                '5:00'],
      ['Meal window',         '18:00 – 19:00'],
      ['Bed',                 '21:30'],
    ]],
    ['Notifications', [
      ['Edit times',          '7 daily'],
      ['Enable / disable',    'All on'],
    ]],
    ['Pause', [
      ['Sick mode',           'Off'],
      ['Travel mode',         'Off'],
    ]],
    ['Recipes', [
      ['Salmon coconut curry', 'Paprika'],
      ['Beef chili',           'NYT'],
      ['Add per dish',         '6 more'],
    ]],
    ['Data', [
      ['Export JSON',          ''],
      ['Reset week',           ''],
    ]],
  ];

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          SETTINGS
        </div>
      </div>

      <div style={{ padding: '24px 24px 42px', flex: 1, overflowY: 'auto', minHeight: 0,
        display: 'flex', flexDirection: 'column', gap: 28 }}>
        {sections.map(([title, rows]) => (
          <div key={title}>
            <div style={{
              color: ACT.textMute, fontSize: 11,
              fontFamily: TYPE.mono, letterSpacing: 1.2,
              textTransform: 'uppercase', marginBottom: 4,
            }}>
              {title}
            </div>
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              {rows.map(([k, v], i) => (
                <div key={k} style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '14px 0',
                  borderBottom: i < rows.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
                  cursor: 'pointer',
                }}>
                  <div style={{
                    flex: 1, color: ACT.text, fontSize: 16, fontWeight: 500,
                    letterSpacing: -0.1,
                  }}>{k}</div>
                  {v && (
                    <div style={{
                      color: ACT.textDim, fontSize: 14, fontFamily: TYPE.mono,
                      fontVariantNumeric: 'tabular-nums',
                    }}>{v}</div>
                  )}
                  {Icon.chevR(11)}
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// Urge sheet — 4-7-8 breathing, intensity, trigger chips. Modal slide-up.
function CmdUrge() {
  // inject breathing keyframes once
  React.useEffect(() => {
    if (document.getElementById('act-breathe')) return;
    const s = document.createElement('style');
    s.id = 'act-breathe';
    s.textContent = `
      @keyframes act-breathe {
        0%   { transform: scale(0.5); }
        21%  { transform: scale(1.0); }
        58%  { transform: scale(1.0); }
        100% { transform: scale(0.5); }
      }
      @keyframes act-breathe-label-a {
        0%, 20% { opacity: 1; }
        21%, 100% { opacity: 0; }
      }
      @keyframes act-breathe-label-b {
        0%, 20% { opacity: 0; }
        21%, 57% { opacity: 1; }
        58%, 100% { opacity: 0; }
      }
      @keyframes act-breathe-label-c {
        0%, 57% { opacity: 0; }
        58%, 100% { opacity: 1; }
      }
      .act-breathe { animation: act-breathe 19s ease-in-out infinite; transform-origin: center; }
      .act-bl-a { animation: act-breathe-label-a 19s steps(1) infinite; }
      .act-bl-b { animation: act-breathe-label-b 19s steps(1) infinite; }
      .act-bl-c { animation: act-breathe-label-c 19s steps(1) infinite; }
    `;
    document.head.appendChild(s);
  }, []);

  const [intensity, setIntensity] = React.useState(5);
  const [triggers, setTriggers] = React.useState(new Set());
  const triggerOpts = ['Social invitation', 'Stress', 'Boredom', 'Smell', 'Near a lounge', 'Other'];

  const toggleTrigger = (t) => {
    setTriggers(prev => {
      const next = new Set(prev);
      if (next.has(t)) next.delete(t); else next.add(t);
      return next;
    });
  };

  return (
    // Outer = dimmed Today-ish backdrop so the modal context reads
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      position: 'relative', overflow: 'hidden',
      fontFamily: TYPE.display,
    }}>
      {/* Faint hint of an underlying screen */}
      <div style={{
        position: 'absolute', inset: 0, padding: '70px 24px',
        opacity: 0.18, pointerEvents: 'none',
      }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono }}>14:22</div>
        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text, marginTop: 16,
        }}>Fast.</div>
      </div>

      {/* Backdrop scrim */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'rgba(0,0,0,0.55)',
      }} />

      {/* Sheet — 80% height, rounded top */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        height: '80%', background: '#0A0A0A',
        borderTopLeftRadius: 24, borderTopRightRadius: 24,
        display: 'flex', flexDirection: 'column',
        boxSizing: 'border-box',
        boxShadow: '0 -20px 60px rgba(0,0,0,0.5)',
      }}>
        {/* Grabber */}
        <div style={{
          width: 36, height: 5, borderRadius: 3,
          background: 'rgba(255,255,255,0.18)',
          margin: '8px auto 0',
        }} />

        <div style={{ padding: '18px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
          <div style={{
            color: ACT.textMute, fontSize: 11,
            fontFamily: TYPE.mono, letterSpacing: 1.2,
            textTransform: 'uppercase',
          }}>
            URGE LOGGED · NO SHAME
          </div>

          <div style={{
            fontSize: 84, fontWeight: 800, lineHeight: 0.9,
            letterSpacing: -3.5, color: ACT.text, marginTop: 12,
          }}>
            Breathe.
          </div>

          <div style={{
            color: ACT.textDim, fontSize: 18, fontWeight: 500,
            letterSpacing: -0.2, marginTop: 10,
          }}>
            5 minutes. Then it passes.
          </div>

          {/* Breathing circle */}
          <div style={{
            marginTop: 28, alignSelf: 'center',
            display: 'flex', justifyContent: 'center',
          }}>
            <div style={{
              position: 'relative', width: 240, height: 240,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <div className="act-breathe" style={{
                position: 'absolute', inset: 0,
                borderRadius: '50%',
                border: `2px solid ${ACT.lime}`,
                background: `radial-gradient(circle, ${ACT.limeDim}, transparent 70%)`,
              }} />
              <div style={{
                position: 'relative', width: '100%', textAlign: 'center',
                color: ACT.lime, fontSize: 32, fontWeight: 700,
                fontFamily: TYPE.mono, letterSpacing: 1.2,
              }}>
                <span className="act-bl-a" style={{ position: 'absolute', left: 0, right: 0 }}>INHALE</span>
                <span className="act-bl-b" style={{ position: 'absolute', left: 0, right: 0 }}>HOLD</span>
                <span className="act-bl-c" style={{ position: 'absolute', left: 0, right: 0 }}>EXHALE</span>
                {/* spacer so layout reserves height */}
                <span style={{ opacity: 0 }}>HOLD</span>
              </div>
            </div>
          </div>

          <div style={{
            marginTop: 16, textAlign: 'center',
            color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono,
            letterSpacing: 1.2, textTransform: 'uppercase',
          }}>
            CYCLE 2 / 16
          </div>

          {/* Intensity */}
          <div style={{ marginTop: 28 }}>
            <div style={{
              color: ACT.textMute, fontSize: 11,
              fontFamily: TYPE.mono, letterSpacing: 1.2,
              textTransform: 'uppercase', marginBottom: 10,
            }}>
              INTENSITY · {intensity}
            </div>
            <div style={{ display: 'flex', gap: 6, justifyContent: 'space-between' }}>
              {Array.from({ length: 11 }, (_, i) => (
                <div key={i} onClick={() => setIntensity(i)} style={{
                  flex: 1, aspectRatio: '1 / 1', maxWidth: 24,
                  borderRadius: '50%', cursor: 'pointer',
                  background: i <= intensity ? ACT.lime : 'transparent',
                  border: i <= intensity ? 'none' : `1.5px solid ${ACT.hairline2}`,
                }} />
              ))}
            </div>
          </div>

          {/* Triggers */}
          <div style={{ marginTop: 24, paddingBottom: 16 }}>
            <div style={{
              color: ACT.textMute, fontSize: 11,
              fontFamily: TYPE.mono, letterSpacing: 1.2,
              textTransform: 'uppercase', marginBottom: 12,
            }}>
              TRIGGER
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {triggerOpts.map(t => {
                const on = triggers.has(t);
                return (
                  <span key={t} onClick={() => toggleTrigger(t)} style={{
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
        </div>

        {/* CTA pair */}
        <div style={{
          padding: '12px 16px 28px', display: 'flex', gap: 10, flexShrink: 0,
        }}>
          <button style={{
            flex: 1, height: 56, borderRadius: 18,
            background: ACT.surface2, border: `1px solid ${ACT.hairline}`,
            color: ACT.textDim,
            fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
            cursor: 'pointer',
          }}>
            Logged
          </button>
          <button style={{
            flex: 1, height: 56, borderRadius: 18, border: 'none',
            background: ACT.lime, color: '#000',
            fontFamily: TYPE.display, fontSize: 18, fontWeight: 800, letterSpacing: -0.3,
            cursor: 'pointer',
          }}>
            Stay 5m
          </button>
        </div>
      </div>
    </div>
  );
}

// Relapse log — full-screen modal. Honest, structured, no shame language.
function CmdRelapse() {
  const [trigger, setTrigger] = React.useState(null);
  const [where, setWhere]     = React.useState('');
  const [who, setWho]         = React.useState('');
  const [amount, setAmount]   = React.useState(1);
  const [unit, setUnit]       = React.useState('bowls');
  const [before, setBefore]   = React.useState({ stress: 0, craving: 0, social: 0 });
  const [after, setAfter]     = React.useState({ satisfaction: 0, regret: 0 });
  const [reflection, setReflection] = React.useState('');

  // dot slider — clicking a dot sets the value
  const DotSlider = ({ value, onChange }) => (
    <div style={{ display: 'flex', gap: 5, justifyContent: 'space-between' }}>
      {Array.from({ length: 11 }, (_, i) => (
        <div key={i} onClick={() => onChange(i)} style={{
          flex: 1, aspectRatio: '1 / 1', maxWidth: 22,
          borderRadius: '50%', cursor: 'pointer',
          background: i <= value ? ACT.red : 'transparent',
          border: i <= value ? 'none' : `1.5px solid ${ACT.hairline2}`,
        }} />
      ))}
    </div>
  );

  const RowLabel = ({ children }) => (
    <div style={{
      color: ACT.textMute, fontSize: 11,
      fontFamily: TYPE.mono, letterSpacing: 1.2,
      textTransform: 'uppercase', marginBottom: 12,
    }}>{children}</div>
  );

  const SubLabel = ({ children }) => (
    <div style={{
      color: ACT.text, fontSize: 14, fontFamily: TYPE.text,
      letterSpacing: -0.1, marginBottom: 8,
    }}>{children}</div>
  );

  const Row = ({ children, last }) => (
    <div style={{
      paddingBottom: 24, marginBottom: 24,
      borderBottom: last ? 'none' : `1px solid ${ACT.hairline}`,
    }}>{children}</div>
  );

  const TextRow = ({ value, onChange, placeholder }) => (
    <input value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder}
      style={{
        width: '100%', background: 'transparent', border: 'none',
        outline: 'none', color: ACT.text, padding: '6px 0',
        fontSize: 16, fontFamily: TYPE.mono, letterSpacing: 0.2,
      }} />
  );

  const triggerOpts = ['Social invite', 'Stress', 'Boredom', 'Ritual', 'Specific person', 'Specific place', 'Other'];

  const complete = !!trigger && !!where && !!who && amount > 0
    && Object.values(before).every(v => v > 0)
    && Object.values(after).every(v => v > 0)
    && !!reflection.trim();

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.red, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          RELAPSE LOG · 60 SEC
        </div>
      </div>

      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{
          fontSize: 72, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3, color: ACT.text,
        }}>
          Honest.
        </div>
        <div style={{
          color: ACT.textDim, fontSize: 16, fontWeight: 500,
          letterSpacing: -0.1, marginTop: 10, lineHeight: 1.4,
        }}>
          No shame. Just data. Tell me what happened.
        </div>

        <div style={{ marginTop: 32 }}>
          {/* 1 — Trigger */}
          <Row>
            <RowLabel>WHAT TRIGGERED IT</RowLabel>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {triggerOpts.map(t => {
                const on = trigger === t;
                return (
                  <span key={t} onClick={() => setTrigger(t)} style={{
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
          </Row>

          {/* 2 — Where */}
          <Row>
            <RowLabel>WHERE</RowLabel>
            <TextRow value={where} onChange={setWhere} placeholder="Cafe / friend's place / car..." />
          </Row>

          {/* 3 — Who */}
          <Row>
            <RowLabel>WHO WITH</RowLabel>
            <TextRow value={who} onChange={setWho} placeholder="Names or 'alone'" />
          </Row>

          {/* 4 — How much */}
          <Row>
            <RowLabel>HOW MUCH</RowLabel>
            <div style={{
              color: ACT.text, fontSize: 32, fontWeight: 800,
              letterSpacing: -1.2, fontFamily: TYPE.mono,
              fontVariantNumeric: 'tabular-nums', marginBottom: 12,
            }}>{amount}</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {['bowls', 'minutes'].map(u => {
                const on = unit === u;
                return (
                  <span key={u} onClick={() => setUnit(u)} style={{
                    padding: '8px 14px', borderRadius: 999,
                    fontSize: 13, fontWeight: 500, letterSpacing: -0.1,
                    background: on ? ACT.lime : 'transparent',
                    color: on ? '#000' : ACT.textDim,
                    border: on ? '1px solid transparent' : `1px solid ${ACT.hairline2}`,
                    cursor: 'pointer',
                  }}>{u}</span>
                );
              })}
            </div>
          </Row>

          {/* 5 — Before */}
          <Row>
            <RowLabel>BEFORE</RowLabel>
            <SubLabel>Stress</SubLabel>
            <DotSlider value={before.stress} onChange={v => setBefore(b => ({ ...b, stress: v }))} />
            <div style={{ height: 16 }} />
            <SubLabel>Craving</SubLabel>
            <DotSlider value={before.craving} onChange={v => setBefore(b => ({ ...b, craving: v }))} />
            <div style={{ height: 16 }} />
            <SubLabel>Social pressure</SubLabel>
            <DotSlider value={before.social} onChange={v => setBefore(b => ({ ...b, social: v }))} />
          </Row>

          {/* 6 — After */}
          <Row>
            <RowLabel>AFTER</RowLabel>
            <SubLabel>Satisfaction</SubLabel>
            <DotSlider value={after.satisfaction} onChange={v => setAfter(a => ({ ...a, satisfaction: v }))} />
            <div style={{ height: 16 }} />
            <SubLabel>Regret</SubLabel>
            <DotSlider value={after.regret} onChange={v => setAfter(a => ({ ...a, regret: v }))} />
          </Row>

          {/* 7 — Reflection */}
          <Row last>
            <RowLabel>WHAT YOU'D DO DIFFERENTLY</RowLabel>
            <TextRow value={reflection} onChange={setReflection}
              placeholder="One sentence. Not optional." />
          </Row>
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          marginBottom: 12, textAlign: 'center',
        }}>
          Streak will reset to 0. 24-hour lava state on Live Activity. Recovery clock continues.
        </div>
        <button disabled={!complete} style={{
          width: '100%', height: 56, borderRadius: 18,
          background: ACT.surface2,
          border: `1px solid ${ACT.red}`,
          color: ACT.red,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 800, letterSpacing: -0.3,
          cursor: complete ? 'pointer' : 'not-allowed',
          opacity: complete ? 1 : 0.45,
        }}>
          Submit
        </button>
      </div>
    </div>
  );
}

// Recovery dashboard — read-only. Body milestones + HealthKit trend.
function CmdRecovery() {
  const currentDay = 47;

  const milestones = [
    { day: 1,    text: 'CO normalized' },
    { day: 2,    text: 'Nicotine cleared. Taste returning.' },
    { day: 3,    text: 'Withdrawal peak. The worst day.' },
    { day: 7,    text: 'Lung function measurably improved.' },
    { day: 30,   text: 'Cilia regenerating.' },
    { day: 90,   text: 'Cardiovascular markers significant.' },
    { day: 365,  text: 'Heart attack risk halved.' },
    { day: 1825, text: 'Lung cancer risk halved.' },
  ];

  // Find most recent achieved milestone — that's the "active" lime row.
  const achievedMs = milestones.filter(m => m.day <= currentDay);
  const activeDay = achievedMs.length ? achievedMs[achievedMs.length - 1].day : null;

  const stats = [
    { k: 'Resting HR', base: '78 bpm', cur: '71', delta: '▼ 7 bpm' },
    { k: 'HRV',        base: '32 ms',  cur: '41', delta: '▲ 9 ms'  },
    { k: 'VO2 max',    base: '24.2',   cur: '26.1', delta: '▲ 1.9' },
  ];

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.textMute, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          RECOVERY
        </div>
      </div>

      <div style={{ padding: '20px 24px 60px', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        {/* Hero */}
        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.lime,
          fontFamily: TYPE.display, fontVariantNumeric: 'tabular-nums',
        }}>
          {currentDay}
        </div>
        <div style={{
          color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono,
          letterSpacing: 1.2, textTransform: 'uppercase', marginTop: 10,
        }}>
          DAYS · 365 TARGET
        </div>

        {/* Section A — Body milestones */}
        <div style={{ marginTop: 40 }}>
          <div style={{
            color: ACT.textMute, fontSize: 11,
            fontFamily: TYPE.mono, letterSpacing: 1.2,
            textTransform: 'uppercase', marginBottom: 4,
          }}>
            BODY
          </div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {milestones.map((m, i) => {
              const isActive = m.day === activeDay;
              const isPast   = m.day < activeDay;
              const isFuture = m.day > activeDay;
              const labelColor = isActive ? ACT.lime
                              : isPast   ? ACT.textDim
                              :            ACT.textFaint;
              const textColor  = isActive ? ACT.lime
                              : isPast   ? ACT.textDim
                              :            ACT.textFaint;
              return (
                <div key={m.day} style={{
                  display: 'flex', alignItems: 'center', gap: 14,
                  padding: '14px 0',
                  borderBottom: i < milestones.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
                }}>
                  <div style={{
                    color: labelColor, fontFamily: TYPE.mono, fontSize: 13,
                    width: 56, flexShrink: 0,
                  }}>
                    Day {m.day}
                  </div>
                  <div style={{
                    flex: 1, color: textColor, fontSize: 16,
                    fontWeight: isActive ? 600 : 500, letterSpacing: -0.1,
                  }}>
                    {m.text}
                  </div>
                  {isPast && Icon.check(14, ACT.lime)}
                </div>
              );
            })}
          </div>
        </div>

        {/* Section B — Body data */}
        <div style={{ marginTop: 40 }}>
          <div style={{
            color: ACT.textMute, fontSize: 11,
            fontFamily: TYPE.mono, letterSpacing: 1.2,
            textTransform: 'uppercase', marginBottom: 16,
          }}>
            BODY DATA · FROM APPLE HEALTH
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
            {stats.map(s => (
              <div key={s.k} style={{
                padding: 14, borderRadius: 16,
                background: ACT.surface, border: `1px solid ${ACT.hairline}`,
              }}>
                <div style={{
                  color: ACT.text, fontSize: 12, fontWeight: 600,
                  letterSpacing: -0.1,
                }}>
                  {s.k}
                </div>
                <div style={{
                  color: ACT.textDim, fontSize: 11, fontFamily: TYPE.mono,
                  marginTop: 6, letterSpacing: 0.2,
                }}>
                  {s.base}
                </div>
                <div style={{
                  color: ACT.lime, fontSize: 40, fontWeight: 800,
                  letterSpacing: -1.4, lineHeight: 1, marginTop: 10,
                  fontFamily: TYPE.mono, fontVariantNumeric: 'tabular-nums',
                }}>
                  {s.cur}
                </div>
                <div style={{
                  color: ACT.lime, fontSize: 13, fontFamily: TYPE.mono,
                  marginTop: 6, letterSpacing: 0.2,
                }}>
                  {s.delta}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// Withdrawal coaching — days 1–7 only. Day-aware hero.
const WITHDRAWAL_DAYS = [
  { day: 1, hero: 'Day 1',  text: 'Nicotine cleared. Mild irritability.' },
  { day: 2, hero: 'Heavy',  text: 'Concentration drop. Energy low.' },
  { day: 3, hero: 'Today',  text: 'Worst day. Cravings peak.' },
  { day: 4, hero: 'Lighter',text: 'Cravings less frequent, longer.' },
  { day: 5, hero: 'Sleep',  text: 'Sleep improving.' },
  { day: 6, hero: 'Energy', text: 'Energy returning.' },
  { day: 7, hero: 'Through',text: 'End of acute withdrawal.' },
];

function CmdWithdrawal({ day = 3, whyQuote = "Live to see my daughter graduate." }) {
  const d = WITHDRAWAL_DAYS.find(x => x.day === day);
  const isDay3 = day === 3;

  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{
          color: ACT.lime, fontSize: 11,
          fontFamily: TYPE.mono, letterSpacing: 1.2,
          textTransform: 'uppercase',
        }}>
          WITHDRAWAL · DAY {day} / 7
        </div>
      </div>

      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        {/* Hero */}
        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text,
        }}>
          {d.hero}.
        </div>

        {isDay3 ? (
          <>
            <div style={{
              color: ACT.textDim, fontSize: 24, fontWeight: 500,
              letterSpacing: -0.4, marginTop: 12,
            }}>
              is the worst day.
            </div>
            <div style={{
              color: ACT.text, fontSize: 18, fontWeight: 500,
              letterSpacing: -0.2, marginTop: 14, lineHeight: 1.4,
            }}>
              Tomorrow is easier. Day 4 onward, withdrawal tapers.
            </div>
          </>
        ) : (
          <div style={{
            color: ACT.text, fontSize: 18, fontWeight: 500,
            letterSpacing: -0.2, marginTop: 14, lineHeight: 1.4,
          }}>
            {d.text}
          </div>
        )}

        {/* Curve */}
        <div style={{ marginTop: 36, display: 'flex', flexDirection: 'column' }}>
          {WITHDRAWAL_DAYS.map((row, i) => {
            const active = row.day === day;
            return (
              <div key={row.day} style={{
                display: 'flex', alignItems: 'center', gap: 14,
                padding: active ? '14px 14px' : '14px 0',
                borderBottom: !active && i < WITHDRAWAL_DAYS.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
                border: active ? `1px solid ${ACT.lime}` : 'none',
                borderRadius: active ? 14 : 0,
                margin: active ? '4px -2px' : 0,
              }}>
                <div style={{
                  color: active ? ACT.lime : ACT.textDim,
                  fontFamily: TYPE.mono, fontSize: 13,
                  width: 52, flexShrink: 0,
                  fontWeight: active ? 700 : 400,
                }}>
                  Day {row.day}
                </div>
                <div style={{
                  flex: 1,
                  color: active ? ACT.text : ACT.textDim,
                  fontSize: 15, fontWeight: active ? 600 : 500,
                  letterSpacing: -0.1, lineHeight: 1.35,
                }}>
                  {row.text}
                </div>
              </div>
            );
          })}
        </div>

        {/* Your why callout */}
        <div style={{
          marginTop: 28, padding: 24,
          background: ACT.surface2, borderRadius: 18,
        }}>
          <div style={{
            color: ACT.textMute, fontSize: 11,
            fontFamily: TYPE.mono, letterSpacing: 1.2,
            textTransform: 'uppercase', marginBottom: 12,
          }}>
            YOUR WHY
          </div>
          <div style={{
            color: ACT.text, fontSize: 16, fontWeight: 500,
            fontStyle: 'italic', lineHeight: 1.5, letterSpacing: -0.1,
          }}>
            "{whyQuote}"
          </div>
        </div>

        {/* Footer */}
        <div style={{
          marginTop: 24, paddingBottom: 8,
          color: ACT.textFaint, fontSize: 11, fontFamily: TYPE.mono,
          letterSpacing: 0.4,
        }}>
          After day 7, this screen retires. Recovery milestones take over.
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: ACT.limeText,
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Keep going.
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { CmdToday, CmdWorkout, CmdWorkoutB, CmdCook, CmdProgress, CmdPreWorkout, CmdHydration, CmdReheat, CmdMeal, CmdWalk, CmdEOD, CmdWeighIn, CmdSwim, CmdSwimSolo, CmdWeightPad, CmdDeviate, CmdRotation, CmdReview, CmdGrocery, CmdSettings, CmdUrge, CmdRelapse, CmdRecovery, CmdWithdrawal });
