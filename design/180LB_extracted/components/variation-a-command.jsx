// Variation A — COMMAND (minimalist)
// Numbers and the thing. Nothing else.

function CmdToday({ onOpen }) {
  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column',
      paddingTop: 60, fontFamily: TYPE.display,
      overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '20px 24px 0', flex: 1, overflowY: 'auto', minHeight: 0 }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono, letterSpacing: 0.4 }}>
          7:24
        </div>
        <div style={{
          fontSize: 84, fontWeight: 800, lineHeight: 0.9,
          letterSpacing: -3.5, color: ACT.text, marginTop: 16,
        }}>
          Oats.
        </div>

        <Placeholder height={220} radius={20} label="" style={{ marginTop: 28 }} />

        <div style={{ display: 'flex', gap: 28, marginTop: 22, fontFamily: TYPE.mono }}>
          {[['420', 'kcal'], ['32', 'P'], ['58', 'C'], ['8', 'F']].map(([v, k]) => (
            <div key={k}>
              <div style={{ color: ACT.text, fontSize: 22, fontWeight: 600 }}>{v}</div>
              <div style={{ color: ACT.textMute, fontSize: 11, marginTop: 2 }}>{k}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Sticky CTA */}
      <div style={{
        padding: '12px 16px 42px',
        flexShrink: 0,
      }}>
        <button onClick={onOpen} style={{
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

function CmdWorkout() {
  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column', fontFamily: TYPE.display,
      paddingTop: 60, overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontFamily: TYPE.mono, fontSize: 13 }}>
          <span style={{ color: ACT.textMute }}>3 / 6</span>
          <span style={{ color: ACT.text }}>22:14</span>
        </div>
        <div style={{ display: 'flex', gap: 4, marginTop: 14 }}>
          {[1,1,1,0.5,0,0].map((v, i) => (
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
          Bench.
        </div>

        <div style={{ display: 'flex', gap: 40, marginTop: 56, alignItems: 'baseline', fontFamily: TYPE.display }}>
          <div>
            <div style={{ color: ACT.text, fontSize: 88, fontWeight: 800, letterSpacing: -3.5, lineHeight: 1 }}>
              185
            </div>
            <div style={{ color: ACT.textMute, fontSize: 12, fontFamily: TYPE.mono, marginTop: 4 }}>lb</div>
          </div>
          <div style={{ color: ACT.textFaint, fontSize: 40, fontWeight: 400 }}>×</div>
          <div>
            <div style={{ color: ACT.text, fontSize: 88, fontWeight: 800, letterSpacing: -3.5, lineHeight: 1 }}>
              5
            </div>
            <div style={{ color: ACT.textMute, fontSize: 12, fontFamily: TYPE.mono, marginTop: 4 }}>reps</div>
          </div>
        </div>

        <div style={{ marginTop: 64, color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono }}>
          Set 2 / 4 · Rest 2:30
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

function CmdCook() {
  return (
    <div style={{
      width: '100%', height: '100%', background: ACT.bg,
      display: 'flex', flexDirection: 'column', fontFamily: TYPE.display,
      paddingTop: 60, overflow: 'hidden', boxSizing: 'border-box',
    }}>
      <div style={{ padding: '12px 24px 0', flexShrink: 0 }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono }}>3 / 7</div>
        <div style={{ display: 'flex', gap: 4, marginTop: 14 }}>
          {[1,1,0.5,0,0,0,0].map((v, i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 2,
              background: v === 1 ? ACT.lime : v > 0 ? ACT.limeDim : ACT.hairline,
            }} />
          ))}
        </div>
      </div>

      <div style={{ padding: '24px 24px 0', flex: 1, display: 'flex', flexDirection: 'column', overflowY: 'auto', minHeight: 0 }}>
        <Placeholder height={180} radius={18} label="" />
        <div style={{
          fontSize: 56, fontWeight: 800, lineHeight: 0.95,
          letterSpacing: -2, color: ACT.text, marginTop: 28,
        }}>
          Sear.
        </div>

        {/* Big timer */}
        <div style={{
          marginTop: 40, display: 'flex', alignItems: 'center', gap: 20,
        }}>
          <div style={{ position: 'relative', width: 88, height: 88, flexShrink: 0 }}>
            <svg width="88" height="88" viewBox="0 0 88 88" style={{ transform: 'rotate(-90deg)' }}>
              <circle cx="44" cy="44" r="40" fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="4"/>
              <circle cx="44" cy="44" r="40" fill="none" stroke={ACT.lime} strokeWidth="4"
                strokeDasharray={Math.PI * 80} strokeDashoffset={Math.PI * 80 * 0.45} strokeLinecap="round"/>
            </svg>
          </div>
          <div>
            <div style={{ color: ACT.text, fontSize: 44, fontWeight: 800, letterSpacing: -1.6, lineHeight: 1, fontFamily: TYPE.display }}>
              2:13
            </div>
            <div style={{ color: ACT.textMute, fontSize: 12, fontFamily: TYPE.mono, marginTop: 4 }}>side 1</div>
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
          Next
        </button>
      </div>
    </div>
  );
}

function CmdProgress() {
  const points = [200, 198.5, 198, 196.5, 195, 194, 192.8, 191, 190.2, 189, 188.5, 187, 186, 185, 184.5, 184];
  const min = 182, max = 202;
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
            184
          </div>
          <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono }}>180</div>
        </div>
        <div style={{ color: ACT.textDim, fontSize: 13, fontFamily: TYPE.mono, marginTop: 4 }}>
          −16 · 4 to go
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
          <circle cx="100" cy={((max - 184) / (max - min)) * 60} r="1.6" fill={ACT.lime}/>
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

        {/* Week dots */}
        <div style={{ marginTop: 36, display: 'flex', gap: 6, alignItems: 'flex-end', height: 64 }}>
          {[
            { d: 'M', m: 1, w: 1 },
            { d: 'T', m: 1, w: 1 },
            { d: 'W', m: 1, w: 0 },
            { d: 'T', m: 0.7, w: 1 },
            { d: 'F', m: 1, w: 1 },
            { d: 'S', m: 0.5, w: 0, today: true },
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

Object.assign(window, { CmdToday, CmdWorkout, CmdCook, CmdProgress });
