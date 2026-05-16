// Variation C — MISSION (minimalist)
// Ring + the next thing. Nothing called a "mission".

function MissionToday() {
  return (
    <div style={{ width: '100%', height: '100%', background: ACT.bg, fontFamily: TYPE.display, paddingTop: 60, overflowY: 'auto', boxSizing: 'border-box', display: 'flex', flexDirection: 'column' }}>
      {/* Ring hero */}
      <div style={{ padding: '40px 24px 0', display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0 }}>
        <div style={{ position: 'relative', width: 240, height: 240 }}>
          <svg width="240" height="240" viewBox="0 0 240 240" style={{ transform: 'rotate(-90deg)' }}>
            <circle cx="120" cy="120" r="110" fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="8"/>
            <circle cx="120" cy="120" r="110" fill="none" stroke={ACT.lime} strokeWidth="8"
              strokeDasharray={Math.PI * 220} strokeDashoffset={Math.PI * 220 * 0.62} strokeLinecap="round"/>
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ color: ACT.text, fontSize: 80, fontWeight: 800, letterSpacing: -3.5, lineHeight: 1 }}>
              3<span style={{ color: ACT.textMute, fontSize: 32, fontWeight: 500 }}>/8</span>
            </div>
          </div>
        </div>
      </div>

      {/* Next thing */}
      <div style={{ padding: '40px 24px 0', flex: 1 }}>
        <div style={{ color: ACT.textMute, fontSize: 13, fontFamily: TYPE.mono }}>12:30</div>
        <div style={{ color: ACT.text, fontSize: 44, fontWeight: 800, letterSpacing: -1.6, marginTop: 8 }}>
          Push A
        </div>
        <div style={{ color: ACT.textDim, fontSize: 14, fontFamily: TYPE.mono, marginTop: 6 }}>
          52m · 6 lifts
        </div>
      </div>

      <div style={{ padding: '12px 16px 42px', flexShrink: 0 }}>
        <button style={{
          width: '100%', height: 56, borderRadius: 18, border: 'none',
          background: ACT.lime, color: '#000',
          fontFamily: TYPE.display, fontSize: 18, fontWeight: 700, letterSpacing: -0.3,
          cursor: 'pointer',
        }}>
          Start
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { MissionToday });
