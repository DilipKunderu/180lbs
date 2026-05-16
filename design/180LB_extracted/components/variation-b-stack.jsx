// Variation B — STACK (minimalist)
// Pure timeline. Time + thing + number. Done items: dimmed, struck through.

function StackToday() {
  const items = [
    { time: '07:00', label: 'Oats',           num: '420', state: 'done', kind: 'meal' },
    { time: '10:00', label: 'Yogurt',         num: '220', state: 'done', kind: 'meal' },
    { time: '12:30', label: 'Push A',         num: '52m', state: 'now',  kind: 'workout' },
    { time: '13:30', label: 'Chicken bowl',   num: '680', state: 'next', kind: 'meal' },
    { time: '16:00', label: 'Shake',          num: '180', state: 'next', kind: 'meal' },
    { time: '19:00', label: 'Salmon',         num: '540', state: 'next', kind: 'meal' },
  ];

  return (
    <div style={{ width: '100%', height: '100%', background: ACT.bg, fontFamily: TYPE.display, paddingTop: 60, overflowY: 'auto', boxSizing: 'border-box' }}>
      <div style={{ padding: '20px 24px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div style={{ color: ACT.text, fontSize: 36, fontWeight: 800, letterSpacing: -1.4 }}>Tue</div>
          <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono }}>3/6</div>
        </div>
      </div>

      <div style={{ padding: '36px 24px 60px', display: 'flex', flexDirection: 'column' }}>
        {items.map((it, i) => {
          const isNow = it.state === 'now';
          const isDone = it.state === 'done';
          return (
            <div key={i} style={{
              display: 'flex', alignItems: 'baseline', gap: 16,
              padding: '18px 0',
              borderBottom: i < items.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
              opacity: isDone ? 0.35 : 1,
            }}>
              <div style={{
                color: isNow ? ACT.lime : ACT.textMute,
                fontFamily: TYPE.mono, fontSize: 13, width: 48, flexShrink: 0,
              }}>{it.time}</div>
              <div style={{
                flex: 1,
                color: ACT.text,
                fontSize: isNow ? 28 : 20,
                fontWeight: isNow ? 700 : 500,
                letterSpacing: isNow ? -0.6 : -0.2,
                textDecoration: isDone ? 'line-through' : 'none',
                lineHeight: 1.1,
              }}>{it.label}</div>
              <div style={{
                color: ACT.textDim,
                fontSize: isNow ? 16 : 14,
                fontFamily: TYPE.mono,
                fontWeight: isNow ? 600 : 400,
              }}>{it.num}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function StackWorkout() {
  const lifts = [
    { name: 'Bench',          set: '4×5',  wt: '185', state: 'done' },
    { name: 'Incline DB',     set: '3×8',  wt: '60',  state: 'now', cur: '2/3' },
    { name: 'Cable fly',      set: '3×12', wt: '35',  state: 'next' },
    { name: 'OHP',            set: '3×8',  wt: '95',  state: 'next' },
    { name: 'Lateral raise',  set: '3×12', wt: '20',  state: 'next' },
    { name: 'Pushdown',       set: '3×12', wt: '50',  state: 'next' },
  ];
  return (
    <div style={{ width: '100%', height: '100%', background: ACT.bg, fontFamily: TYPE.display, paddingTop: 60, overflowY: 'auto', boxSizing: 'border-box' }}>
      <div style={{ padding: '20px 24px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div style={{ color: ACT.text, fontSize: 36, fontWeight: 800, letterSpacing: -1.4 }}>Push</div>
          <div style={{ color: ACT.text, fontSize: 18, fontFamily: TYPE.mono, fontWeight: 600 }}>22:14</div>
        </div>
      </div>

      <div style={{ padding: '36px 24px 60px', display: 'flex', flexDirection: 'column' }}>
        {lifts.map((l, i) => {
          const isNow = l.state === 'now';
          const isDone = l.state === 'done';
          return (
            <div key={i} style={{
              display: 'flex', alignItems: 'baseline', gap: 16,
              padding: '18px 0',
              borderBottom: i < lifts.length - 1 ? `1px solid ${ACT.hairline}` : 'none',
              opacity: isDone ? 0.35 : 1,
            }}>
              <div style={{
                color: isNow ? ACT.lime : ACT.textMute,
                fontFamily: TYPE.mono, fontSize: 13, width: 36, flexShrink: 0,
              }}>{isNow ? l.cur : l.set}</div>
              <div style={{
                flex: 1,
                color: ACT.text,
                fontSize: isNow ? 28 : 20,
                fontWeight: isNow ? 700 : 500,
                letterSpacing: isNow ? -0.6 : -0.2,
                textDecoration: isDone ? 'line-through' : 'none',
                lineHeight: 1.1,
              }}>{l.name}</div>
              <div style={{
                color: ACT.textDim,
                fontSize: isNow ? 18 : 14,
                fontFamily: TYPE.mono,
                fontWeight: isNow ? 600 : 400,
              }}>{l.wt}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

Object.assign(window, { StackToday, StackWorkout });
