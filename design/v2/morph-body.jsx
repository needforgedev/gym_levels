// MorphBody — anime-style male torso figure that morphs with body type.
// Muscle groups render as stylized purple-glow overlays (pecs, delts, abs, arms, quads)
// with thickness / definition varying by body type.

const BODY_PRESETS = {
  lean:     { muscleOpacity: 0.55, muscleScale: 0.85, shoulderW: 62, waistW: 28, armW: 8,  thighW: 14, abs: true,  vCut: 0.9, glowHue: '#19E3E3' },
  muscular: { muscleOpacity: 0.9,  muscleScale: 1.05, shoulderW: 74, waistW: 30, armW: 12, thighW: 18, abs: true,  vCut: 1.0, glowHue: '#A78BFA' },
  powerful: { muscleOpacity: 1.0,  muscleScale: 1.2,  shoulderW: 82, waistW: 36, armW: 15, thighW: 22, abs: false, vCut: 0.7, glowHue: '#F5A623' },
  balanced: { muscleOpacity: 0.75, muscleScale: 0.95, shoulderW: 68, waistW: 30, armW: 10, thighW: 16, abs: true,  vCut: 0.95, glowHue: '#22E06B' },
};

const MorphBody = ({ type }) => {
  const p = BODY_PRESETS[type] || BODY_PRESETS.balanced;
  // Silhouette path uses preset dimensions (symmetric around x=100, viewBox 200x260)
  const cx = 100;
  const sh = p.shoulderW, w = p.waistW;
  // Head 92→108 at y=0..26, neck 96..104 at 26..36
  // Shoulders flare out at y=36 → sh wide, taper to waist at y=130
  // Pelvis 130..150, thighs, knees at 210
  const sil = `
    M${cx - 9} 4 Q${cx} 0 ${cx + 9} 4 Q${cx + 14} 14 ${cx + 12} 24 L${cx + 11} 30
    Q${cx + 14} 36 ${cx + sh / 2} 42 Q${cx + sh / 2 + 2} 60 ${cx + sh / 2 - 4} 80
    Q${cx + w / 2 + 14} 110 ${cx + w / 2} 132
    Q${cx + w / 2 + p.thighW} 150 ${cx + w / 2 + p.thighW - 2} 180
    Q${cx + w / 2 + p.thighW - 4} 210 ${cx + w / 2 + p.thighW - 6} 240
    L${cx + w / 2 + p.thighW - 10} 252
    L${cx + 4} 252 L${cx + 4} 240
    Q${cx + 2} 210 ${cx + 2} 180 L${cx + 2} 150
    L${cx - 2} 150 L${cx - 2} 180
    Q${cx - 2} 210 ${cx - 4} 240 L${cx - 4} 252
    L${cx - w / 2 - p.thighW + 10} 252
    L${cx - w / 2 - p.thighW + 6} 240
    Q${cx - w / 2 - p.thighW + 4} 210 ${cx - w / 2 - p.thighW + 2} 180
    Q${cx - w / 2 - p.thighW + 2} 150 ${cx - w / 2} 132
    Q${cx - w / 2 - 14} 110 ${cx - sh / 2 + 4} 80
    Q${cx - sh / 2 - 2} 60 ${cx - sh / 2} 42
    Q${cx - 14} 36 ${cx - 11} 30 L${cx - 12} 24 Q${cx - 14} 14 ${cx - 9} 4 Z
  `;

  // Arms hang beside torso
  const armPath = (side) => {
    const s = side === 'L' ? -1 : 1;
    const ax = cx + s * (sh / 2 + 2);
    return `
      M${ax} 42 Q${ax + s * p.armW} 60 ${ax + s * (p.armW - 1)} 90
      Q${ax + s * (p.armW - 2)} 115 ${ax + s * (p.armW - 4)} 140
      L${ax + s * (p.armW - 6)} 155 L${ax + s * 2} 155
      Q${ax + s * 2} 130 ${ax} 100 Q${ax - s * 2} 70 ${ax} 42 Z
    `;
  };

  return (
    <div style={{ width: 180, height: 260, position: 'relative', filter: `drop-shadow(0 0 24px ${p.glowHue}55)` }}>
      <svg viewBox="0 0 200 260" style={{ width: '100%', height: '100%', display: 'block' }}>
        <defs>
          <linearGradient id="bodyGrad" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor="#1A1025"/>
            <stop offset="50%" stopColor="#120A1F"/>
            <stop offset="100%" stopColor="#0A0612"/>
          </linearGradient>
          <linearGradient id="muscleGrad" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor={p.glowHue} stopOpacity="0.9"/>
            <stop offset="100%" stopColor="#8B5CF6" stopOpacity="0.7"/>
          </linearGradient>
          <radialGradient id="rimGlow">
            <stop offset="70%" stopColor={p.glowHue} stopOpacity="0"/>
            <stop offset="100%" stopColor={p.glowHue} stopOpacity="0.4"/>
          </radialGradient>
          <filter id="muscleGlow">
            <feGaussianBlur stdDeviation="1.5" result="b"/>
            <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
          </filter>
        </defs>

        {/* Back glow halo */}
        <ellipse cx={cx} cy="130" rx="85" ry="130" fill="url(#rimGlow)"/>

        {/* Arms behind torso */}
        <path d={armPath('L')} fill="url(#bodyGrad)" stroke={p.glowHue} strokeOpacity="0.5" strokeWidth="0.8" style={{ transition: 'all 0.4s ease' }}/>
        <path d={armPath('R')} fill="url(#bodyGrad)" stroke={p.glowHue} strokeOpacity="0.5" strokeWidth="0.8" style={{ transition: 'all 0.4s ease' }}/>

        {/* Body silhouette */}
        <path d={sil} fill="url(#bodyGrad)" stroke={p.glowHue} strokeOpacity="0.7" strokeWidth="1" style={{ transition: 'all 0.4s ease' }}/>

        {/* Muscle overlays — all animated via transform origin */}
        <g opacity={p.muscleOpacity} filter="url(#muscleGlow)" style={{ transition: 'all 0.4s ease' }}>
          {/* Pecs — two rounded slabs */}
          <g style={{ transform: `scale(${p.muscleScale})`, transformOrigin: '100px 62px', transition: 'transform 0.4s ease' }}>
            <path d={`M${cx - 2} 50 Q${cx - sh/2 + 8} 52 ${cx - sh/2 + 10} 68 Q${cx - sh/2 + 14} 78 ${cx - 4} 76 Q${cx - 2} 68 ${cx - 2} 50 Z`} fill="url(#muscleGrad)"/>
            <path d={`M${cx + 2} 50 Q${cx + sh/2 - 8} 52 ${cx + sh/2 - 10} 68 Q${cx + sh/2 - 14} 78 ${cx + 4} 76 Q${cx + 2} 68 ${cx + 2} 50 Z`} fill="url(#muscleGrad)"/>
          </g>

          {/* Delts (shoulders) */}
          <circle cx={cx - sh/2 + 2} cy="46" r={7 * p.muscleScale} fill="url(#muscleGrad)"/>
          <circle cx={cx + sh/2 - 2} cy="46" r={7 * p.muscleScale} fill="url(#muscleGrad)"/>

          {/* Biceps */}
          <ellipse cx={cx - sh/2 - p.armW/2 + 2} cy="70" rx={p.armW/2 + 1} ry={10 * p.muscleScale} fill="url(#muscleGrad)"/>
          <ellipse cx={cx + sh/2 + p.armW/2 - 2} cy="70" rx={p.armW/2 + 1} ry={10 * p.muscleScale} fill="url(#muscleGrad)"/>

          {/* Abs — 6-pack grid (only if defined) */}
          {p.abs && (
            <g opacity={p.vCut}>
              {[0, 1, 2].map(row => (
                <React.Fragment key={row}>
                  <rect x={cx - 10} y={86 + row * 11} width="8" height="8" rx="2" fill="url(#muscleGrad)"/>
                  <rect x={cx + 2} y={86 + row * 11} width="8" height="8" rx="2" fill="url(#muscleGrad)"/>
                </React.Fragment>
              ))}
              {/* V-cut */}
              <path d={`M${cx - 10} 120 L${cx} 130 L${cx + 10} 120`} stroke={p.glowHue} strokeWidth="1.2" fill="none" opacity="0.8"/>
            </g>
          )}
          {/* Belly (no abs) — soft curve */}
          {!p.abs && (
            <ellipse cx={cx} cy="105" rx="18" ry="16" fill="url(#muscleGrad)" opacity="0.5"/>
          )}

          {/* Quads */}
          <ellipse cx={cx - w/2 + 2} cy="175" rx={p.thighW/2 + 1} ry="28" fill="url(#muscleGrad)" opacity="0.75"/>
          <ellipse cx={cx + w/2 - 2} cy="175" rx={p.thighW/2 + 1} ry="28" fill="url(#muscleGrad)" opacity="0.75"/>
        </g>

        {/* Head accent — simple anime hair silhouette top */}
        <path d={`M${cx - 10} 6 Q${cx - 12} -2 ${cx - 4} 2 Q${cx} -3 ${cx + 4} 2 Q${cx + 12} -2 ${cx + 10} 6 Q${cx + 9} 12 ${cx + 6} 10 Q${cx + 2} 7 ${cx} 10 Q${cx - 2} 7 ${cx - 6} 10 Q${cx - 9} 12 ${cx - 10} 6 Z`}
              fill="#1A1025" stroke={p.glowHue} strokeOpacity="0.6" strokeWidth="0.8"/>

        {/* Scan line effect */}
        <rect x="0" y="0" width="200" height="260" fill="none">
          <animate attributeName="opacity" values="0;0.3;0" dur="3s" repeatCount="indefinite"/>
        </rect>
        <line x1="20" y1="0" x2="180" y2="0" stroke={p.glowHue} strokeWidth="0.5" opacity="0.5">
          <animate attributeName="y1" values="10;250;10" dur="4s" repeatCount="indefinite"/>
          <animate attributeName="y2" values="10;250;10" dur="4s" repeatCount="indefinite"/>
        </line>
      </svg>

      {/* Corner HUD brackets */}
      {[{t:0,l:0,r:null,b:null,h:'bl'},{t:0,l:null,r:0,b:null,h:'br'},{t:null,l:0,r:null,b:0,h:'tl'},{t:null,l:null,r:0,b:0,h:'tr'}].map((c,i)=>(
        <div key={i} style={{
          position:'absolute', top:c.t, left:c.l, right:c.r, bottom:c.b,
          width:14, height:14,
          borderTop: c.t!==null ? `1.5px solid ${p.glowHue}` : 'none',
          borderBottom: c.b!==null ? `1.5px solid ${p.glowHue}` : 'none',
          borderLeft: c.l!==null ? `1.5px solid ${p.glowHue}` : 'none',
          borderRight: c.r!==null ? `1.5px solid ${p.glowHue}` : 'none',
          opacity: 0.7,
          transition: 'border-color 0.4s',
        }}/>
      ))}
    </div>
  );
};

window.MorphBody = MorphBody;
window.BODY_PRESETS = BODY_PRESETS;
