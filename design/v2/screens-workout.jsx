// Workout logger + Workout complete screens

// ─── Logger active session ────────────────────────────────
const LoggerScreen = ({ onClose, onFinish }) => {
  const [currentEx, setCurrentEx] = React.useState(0);
  const [currentSet, setCurrentSet] = React.useState(0);
  const [completedSets, setCompletedSets] = React.useState([]); // [{exIdx, setIdx, weight, reps, xp}]
  const [weight, setWeight] = React.useState(EXERCISES[0].sets[0].weight);
  const [reps, setReps] = React.useState(EXERCISES[0].sets[0].reps);
  const [xpFloat, setXpFloat] = React.useState(null);
  const [showRest, setShowRest] = React.useState(false);
  const [elapsed, setElapsed] = React.useState(2834); // 47:14

  React.useEffect(() => {
    const t = setInterval(() => setElapsed(e => e + 1), 1000);
    return () => clearInterval(t);
  }, []);

  const ex = EXERCISES[currentEx];
  const totalVolume = completedSets.reduce((a, s) => a + s.weight * s.reps, 0);
  const totalXp = completedSets.reduce((a, s) => a + s.xp, 0);

  const fmtTime = s => {
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), ss = s % 60;
    return h > 0 ? `${h}:${String(m).padStart(2,'0')}:${String(ss).padStart(2,'0')}` : `${m}:${String(ss).padStart(2,'0')}`;
  };

  const completeSet = () => {
    const xp = Math.round(5 * (0.8 + Math.random() * 0.5));
    const newSet = { exIdx: currentEx, setIdx: currentSet, weight, reps, xp };
    setCompletedSets([...completedSets, newSet]);
    setXpFloat({ amount: xp, id: Date.now() });
    setTimeout(() => setXpFloat(null), 900);
    // advance
    const nextSet = currentSet + 1;
    if (nextSet < ex.sets.length) {
      setCurrentSet(nextSet);
      setWeight(ex.sets[nextSet].weight);
      setReps(ex.sets[nextSet].reps);
      setShowRest(true);
      setTimeout(() => setShowRest(false), 2500);
    } else if (currentEx + 1 < EXERCISES.length) {
      setCurrentEx(currentEx + 1);
      setCurrentSet(0);
      setWeight(EXERCISES[currentEx + 1].sets[0].weight);
      setReps(EXERCISES[currentEx + 1].sets[0].reps);
      setShowRest(true);
      setTimeout(() => setShowRest(false), 2500);
    }
  };

  return (
    <div className="scroll" style={{ position: 'absolute', inset: 0, overflow: 'auto', paddingBottom: 40, background: PALETTE.bg }}>
      {/* Sticky top stat row */}
      <div style={{
        position: 'sticky', top: 0, zIndex: 10,
        paddingTop: 54, background: 'linear-gradient(180deg, #0A0612 70%, rgba(10,6,18,0.9) 100%)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px 12px' }}>
          <button onClick={onClose} style={{ width: 36, height: 36, borderRadius: 18, background: 'rgba(255,107,53,0.15)', border: '1px solid rgba(255,107,53,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="close" size={18} color={PALETTE.streak}/>
          </button>
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ padding: '6px 10px', borderRadius: 10, background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)', display: 'flex', alignItems: 'center', gap: 6 }}>
              <Icon name="clock" size={13} color={PALETTE.violetSoft}/>
              <span className="mono" style={{ fontSize: 12, fontWeight: 700, color: PALETTE.text }}>{fmtTime(elapsed)}</span>
            </div>
            <div style={{ padding: '6px 10px', borderRadius: 10, background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)', display: 'flex', alignItems: 'center', gap: 6 }}>
              <span style={{ fontSize: 10, color: PALETTE.muted, fontWeight: 700, letterSpacing: 0.5 }}>VOL</span>
              <span className="mono" style={{ fontSize: 12, fontWeight: 700, color: PALETTE.text }}>{totalVolume.toLocaleString()}kg</span>
            </div>
            <div style={{ padding: '6px 10px', borderRadius: 10, background: 'rgba(245,166,35,0.15)', border: '1px solid rgba(245,166,35,0.35)' }}>
              <span className="mono" style={{ fontSize: 12, fontWeight: 700, color: PALETTE.amber }}>+{totalXp} XP</span>
            </div>
          </div>
          <button onClick={onFinish} style={{ fontSize: 13, fontWeight: 700, color: PALETTE.teal }}>Finish</button>
        </div>
      </div>

      {/* Active exercise card */}
      <div style={{ padding: '8px 20px 0', position: 'relative' }}>
        <div style={{
          borderRadius: 20, padding: 20,
          background: 'linear-gradient(180deg, rgba(139,92,246,0.18), rgba(139,92,246,0.06))',
          border: '1.5px solid rgba(139,92,246,0.5)',
          boxShadow: '0 0 32px -6px rgba(139,92,246,0.5), inset 0 1px 0 rgba(255,255,255,0.05)',
          animation: 'pulseGlow 2.5s infinite',
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 11, color: PALETTE.violetSoft, fontWeight: 700, letterSpacing: 1 }}>EXERCISE {currentEx + 1} / {EXERCISES.length}</div>
              <div className="display-font" style={{ fontSize: 26, marginTop: 4, lineHeight: 1.1 }}>{ex.name.toUpperCase()}</div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
              <Pill variant="amber" style={{ fontSize: 11 }}>SET {currentSet + 1}</Pill>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'rgba(245,166,35,0.2)', border: '1px solid rgba(245,166,35,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Bebas Neue', fontSize: 18, color: PALETTE.amber }}>A</div>
            </div>
          </div>

          {/* Weight stepper */}
          <div style={{ marginTop: 20 }}>
            <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 600, letterSpacing: 1, marginBottom: 6 }}>WEIGHT</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <button onClick={() => setWeight(Math.max(0, weight - 2.5))} style={{ width: 38, height: 38, borderRadius: 10, background: 'rgba(139,92,246,0.15)', border: '1px solid rgba(139,92,246,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="minus" size={18} color={PALETTE.text}/>
              </button>
              <div style={{ flex: 1, textAlign: 'center' }}>
                <span className="display-font" style={{ fontSize: 44, color: PALETTE.text, lineHeight: 1 }}>{weight}</span>
                <span style={{ fontSize: 14, color: PALETTE.muted, marginLeft: 6, fontWeight: 600 }}>kg</span>
              </div>
              <button onClick={() => setWeight(weight + 2.5)} style={{ width: 38, height: 38, borderRadius: 10, background: 'rgba(139,92,246,0.15)', border: '1px solid rgba(139,92,246,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="plus" size={18} color={PALETTE.text}/>
              </button>
            </div>
          </div>

          {/* Reps stepper */}
          <div style={{ marginTop: 16 }}>
            <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 600, letterSpacing: 1, marginBottom: 6 }}>REPS</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <button onClick={() => setReps(Math.max(0, reps - 1))} style={{ width: 38, height: 38, borderRadius: 10, background: 'rgba(139,92,246,0.15)', border: '1px solid rgba(139,92,246,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="minus" size={18} color={PALETTE.text}/>
              </button>
              <div style={{ flex: 1, textAlign: 'center' }}>
                <span className="display-font" style={{ fontSize: 44, color: PALETTE.text, lineHeight: 1 }}>{reps}</span>
              </div>
              <button onClick={() => setReps(reps + 1)} style={{ width: 38, height: 38, borderRadius: 10, background: 'rgba(139,92,246,0.15)', border: '1px solid rgba(139,92,246,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="plus" size={18} color={PALETTE.text}/>
              </button>
            </div>
          </div>

          {/* Complete button */}
          <button onClick={completeSet} style={{
            width: '100%', height: 54, borderRadius: 14, marginTop: 20,
            background: 'linear-gradient(135deg, #F5A623 0%, #F59E0B 100%)',
            color: '#0A0612', fontWeight: 800, fontSize: 15, letterSpacing: 1.2,
            fontFamily: 'Bebas Neue, sans-serif',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            boxShadow: '0 8px 24px rgba(245,166,35,0.4)',
          }}>
            <Icon name="check" size={18} color="#0A0612"/>COMPLETE SET
          </button>

          {/* XP float */}
          {xpFloat && (
            <div key={xpFloat.id} style={{
              position: 'absolute', top: '55%', left: '50%', transform: 'translateX(-50%)',
              fontFamily: 'Bebas Neue', fontSize: 42, color: PALETTE.amber,
              textShadow: '0 0 20px rgba(245,166,35,0.8)',
              animation: 'xpFloat 0.9s ease-out forwards', pointerEvents: 'none',
            }}>+{xpFloat.amount} XP</div>
          )}
        </div>
      </div>

      {/* Remaining sets */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1, marginBottom: 8 }}>REMAINING SETS</div>
        {ex.sets.map((s, i) => {
          if (i < currentSet) return (
            <div key={i} style={{ padding: '10px 14px', borderRadius: 10, background: 'rgba(34,224,107,0.08)', border: '1px solid rgba(34,224,107,0.2)', marginBottom: 6, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <Icon name="check" size={14} color="#22E06B"/>
                <span className="mono" style={{ fontSize: 12, color: '#22E06B' }}>Set {i + 1}</span>
              </div>
              <span className="mono" style={{ fontSize: 11, color: PALETTE.muted }}>{completedSets.find(c => c.exIdx === currentEx && c.setIdx === i)?.weight}kg × {completedSets.find(c => c.exIdx === currentEx && c.setIdx === i)?.reps}</span>
            </div>
          );
          if (i === currentSet) return null;
          return (
            <div key={i} style={{ padding: '10px 14px', borderRadius: 10, background: 'rgba(139,92,246,0.04)', border: '1px solid rgba(139,92,246,0.12)', marginBottom: 6, display: 'flex', justifyContent: 'space-between' }}>
              <span className="mono" style={{ fontSize: 12, color: PALETTE.dim }}>Set {i + 1}</span>
              <span className="mono" style={{ fontSize: 11, color: PALETTE.dim }}>{s.weight}kg × {s.reps}</span>
            </div>
          );
        })}
      </div>

      {/* Next exercise preview */}
      {currentEx + 1 < EXERCISES.length && (
        <div style={{ padding: '14px 20px 0' }}>
          <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1, marginBottom: 8 }}>UP NEXT</div>
          <div style={{ padding: 14, borderRadius: 12, background: 'rgba(139,92,246,0.05)', border: '1px dashed rgba(139,92,246,0.25)', display: 'flex', alignItems: 'center', gap: 10 }}>
            <Icon name="dumbbell" size={18} color={PALETTE.dim}/>
            <span style={{ fontSize: 13, fontWeight: 600, color: PALETTE.muted, flex: 1 }}>{EXERCISES[currentEx + 1].name}</span>
            <span className="mono" style={{ fontSize: 11, color: PALETTE.dim }}>0/{EXERCISES[currentEx + 1].sets.length}</span>
          </div>
        </div>
      )}

      {/* Rest timer toast */}
      {showRest && (
        <div style={{
          position: 'absolute', bottom: 20, left: 20, right: 20,
          padding: '12px 16px', borderRadius: 14,
          background: 'linear-gradient(135deg, rgba(25,227,227,0.2), rgba(25,227,227,0.08))',
          border: '1px solid rgba(25,227,227,0.4)',
          display: 'flex', alignItems: 'center', gap: 12,
          animation: 'fadeInUp 0.3s ease-out', zIndex: 20,
        }}>
          <Icon name="clock" size={18} color={PALETTE.teal}/>
          <span style={{ fontSize: 13, fontWeight: 600, flex: 1 }}>Rest 90s</span>
          <button style={{ fontSize: 12, fontWeight: 700, color: PALETTE.teal }}>SKIP</button>
        </div>
      )}
    </div>
  );
};

// ─── Muscle body silhouette (front / back with highlighted zones) ───
const BodySilhouette = ({ back = false }) => {
  // Key: highlight chest/shoulders/triceps (push day)
  const highlightColor = 'rgba(167, 139, 250, 0.9)';
  const bodyFill = '#2A1F3D';
  const bodyStroke = 'rgba(167, 139, 250, 0.25)';
  return (
    <svg width="110" height="200" viewBox="0 0 120 220" style={{ display: 'block' }}>
      <defs>
        <radialGradient id={`glow-${back?'b':'f'}`} cx="0.5" cy="0.5">
          <stop offset="0%" stopColor={highlightColor} stopOpacity="0.95"/>
          <stop offset="100%" stopColor="#8B5CF6" stopOpacity="0.3"/>
        </radialGradient>
        <filter id={`blur-${back?'b':'f'}`}><feGaussianBlur stdDeviation="1"/></filter>
      </defs>
      {/* head */}
      <ellipse cx="60" cy="20" rx="14" ry="16" fill={bodyFill} stroke={bodyStroke}/>
      {/* neck */}
      <rect x="54" y="33" width="12" height="8" fill={bodyFill}/>
      {/* shoulders / torso */}
      <path d="M30 50 Q25 48 22 55 L20 75 Q22 80 28 82 L34 75 L34 130 Q36 140 44 142 L60 144 L76 142 Q84 140 86 130 L86 75 L92 82 Q98 80 100 75 L98 55 Q95 48 90 50 L75 45 Q60 42 45 45 Z" fill={bodyFill} stroke={bodyStroke} strokeWidth="1"/>

      {!back && (
        <g>
          {/* chest - HIGHLIGHTED */}
          <path d="M42 55 Q48 52 60 52 L60 78 Q50 80 44 76 Z" fill={`url(#glow-f)`} opacity="0.95"/>
          <path d="M78 55 Q72 52 60 52 L60 78 Q70 80 76 76 Z" fill={`url(#glow-f)`} opacity="0.95"/>
          {/* shoulders - HIGHLIGHTED */}
          <ellipse cx="28" cy="60" rx="9" ry="11" fill={`url(#glow-f)`} opacity="0.85"/>
          <ellipse cx="92" cy="60" rx="9" ry="11" fill={`url(#glow-f)`} opacity="0.85"/>
          {/* abs outline */}
          <rect x="52" y="82" width="16" height="6" rx="2" fill="none" stroke={bodyStroke}/>
          <rect x="52" y="92" width="16" height="6" rx="2" fill="none" stroke={bodyStroke}/>
          <rect x="52" y="102" width="16" height="6" rx="2" fill="none" stroke={bodyStroke}/>
          <rect x="52" y="112" width="16" height="6" rx="2" fill="none" stroke={bodyStroke}/>
        </g>
      )}
      {back && (
        <g>
          {/* traps - HIGHLIGHTED */}
          <path d="M45 48 Q60 44 75 48 L72 60 Q60 58 48 60 Z" fill={`url(#glow-b)`} opacity="0.85"/>
          {/* rear delts - HIGHLIGHTED */}
          <ellipse cx="28" cy="60" rx="9" ry="11" fill={`url(#glow-b)`} opacity="0.85"/>
          <ellipse cx="92" cy="60" rx="9" ry="11" fill={`url(#glow-b)`} opacity="0.85"/>
          {/* triceps outline */}
          <path d="M20 70 Q18 80 22 95 L30 92 L30 72 Z" fill="rgba(139,92,246,0.35)" stroke={bodyStroke}/>
          <path d="M100 70 Q102 80 98 95 L90 92 L90 72 Z" fill="rgba(139,92,246,0.35)" stroke={bodyStroke}/>
          {/* spine */}
          <line x1="60" y1="52" x2="60" y2="130" stroke={bodyStroke} strokeWidth="1" strokeDasharray="2,3"/>
        </g>
      )}

      {/* arms */}
      <ellipse cx="20" cy="95" rx="8" ry="20" fill={bodyFill} stroke={bodyStroke}/>
      <ellipse cx="100" cy="95" rx="8" ry="20" fill={bodyFill} stroke={bodyStroke}/>
      {/* forearms */}
      <ellipse cx="18" cy="130" rx="7" ry="18" fill={bodyFill} stroke={bodyStroke}/>
      <ellipse cx="102" cy="130" rx="7" ry="18" fill={bodyFill} stroke={bodyStroke}/>

      {/* legs */}
      <path d="M44 144 L40 200 Q44 210 50 208 L56 144 Z" fill={bodyFill} stroke={bodyStroke}/>
      <path d="M76 144 L80 200 Q76 210 70 208 L64 144 Z" fill={bodyFill} stroke={bodyStroke}/>
    </svg>
  );
};

// ─── Workout Complete screen (special attention) ──────────
const BreakdownSheet = ({ onClose }) => (
  <div style={{
    position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.6)',
    display: 'flex', alignItems: 'flex-end', zIndex: 100,
    animation: 'fadeIn 0.2s',
  }} onClick={onClose}>
    <div onClick={e => e.stopPropagation()} style={{
      width: '100%', borderRadius: '28px 28px 0 0',
      background: 'linear-gradient(180deg, #1A0F2B 0%, #0A0612 100%)',
      border: '1px solid rgba(139,92,246,0.3)', borderBottom: 'none',
      padding: '12px 20px 40px',
      animation: 'slideUp 0.3s ease-out',
      maxHeight: '88%', overflow: 'auto',
    }}>
      <div style={{ width: 40, height: 4, background: 'rgba(255,255,255,0.2)', borderRadius: 2, margin: '0 auto 16px' }}/>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div>
          <div className="display-font" style={{ fontSize: 26, color: PALETTE.text, lineHeight: 1 }}>FULL BREAKDOWN</div>
          <div style={{ fontSize: 12, color: PALETTE.muted, marginTop: 4 }}>Push Day · 5 exercises · 01:12:34</div>
        </div>
        <button onClick={onClose} style={{ width: 32, height: 32, borderRadius: 16, background: 'rgba(139,92,246,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="close" size={16} color={PALETTE.muted}/>
        </button>
      </div>

      {/* Per-exercise breakdown */}
      {EXERCISES.map((ex, i) => {
        const totalVol = ex.sets.reduce((a, s) => a + s.weight * s.reps, 0);
        const xp = Math.round(totalVol * 0.05);
        return (
          <div key={ex.name} style={{
            padding: 14, borderRadius: 12, marginBottom: 10,
            background: 'rgba(26,15,43,0.6)', border: '1px solid rgba(139,92,246,0.18)',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
              <div>
                <div style={{ fontSize: 14, fontWeight: 700 }}>{ex.name}</div>
                <div style={{ fontSize: 10, color: PALETTE.muted, marginTop: 2 }}>{ex.muscles}</div>
              </div>
              <span className="mono" style={{ fontSize: 11, color: PALETTE.amber, fontWeight: 700 }}>+{xp} XP</span>
            </div>
            <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
              {ex.sets.map((s, si) => (
                <div key={si} style={{
                  padding: '4px 8px', borderRadius: 6,
                  background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.22)',
                  fontSize: 10, fontFamily: 'JetBrains Mono', color: PALETTE.violetSoft,
                }}>{s.weight}×{s.reps}</div>
              ))}
            </div>
            <div style={{ marginTop: 8, display: 'flex', justifyContent: 'space-between', fontSize: 10, color: PALETTE.muted }}>
              <span>Volume: <span className="mono" style={{ color: PALETTE.text }}>{totalVol} kg</span></span>
              <span>Avg RPE: <span className="mono" style={{ color: PALETTE.text }}>8.2</span></span>
            </div>
          </div>
        );
      })}
    </div>
  </div>
);

const WorkoutCompleteScreen = ({ onDone }) => {
  const [showSheet, setShowSheet] = React.useState(false);
  return (
    <div className="scroll" style={{ position: 'absolute', inset: 0, overflow: 'auto', paddingTop: 54, paddingBottom: 40, background: PALETTE.bg }}>
      {/* Header */}
      <div style={{ padding: '22px 24px 8px' }}>
        <div style={{ fontSize: 28, fontWeight: 800, color: PALETTE.text, letterSpacing: -0.5 }}>
          Workout Complete! <span style={{ fontSize: 26 }}>🎉</span>
        </div>
        <div style={{ fontSize: 15, color: PALETTE.violetSoft, marginTop: 4, fontWeight: 500 }}>You crushed it.</div>
      </div>

      {/* Total volume card */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          borderRadius: 20, padding: 20,
          background: 'linear-gradient(180deg, rgba(26,15,43,0.9) 0%, rgba(18,10,31,0.9) 100%)',
          border: '1px solid rgba(139,92,246,0.2)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <div>
            <div style={{ fontSize: 13, color: PALETTE.muted, fontWeight: 500 }}>Total Volume</div>
            <div style={{ marginTop: 10, display: 'flex', alignItems: 'baseline', gap: 6 }}>
              <span style={{ fontSize: 38, fontWeight: 800, color: PALETTE.text, letterSpacing: -1 }}>12,450</span>
              <span style={{ fontSize: 18, color: PALETTE.muted, fontWeight: 600 }}>kg</span>
            </div>
            <div style={{ marginTop: 8, fontSize: 13, color: PALETTE.violetSoft, fontWeight: 600 }}>+18% vs last push day</div>
          </div>
          {/* Dumbbell graphic */}
          <div style={{ filter: 'drop-shadow(0 0 16px rgba(167,139,250,0.5))' }}>
            <svg width="90" height="80" viewBox="0 0 90 80">
              <defs>
                <linearGradient id="dbGrad" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stopColor="#C4B5FD"/>
                  <stop offset="1" stopColor="#8B5CF6"/>
                </linearGradient>
              </defs>
              {/* handle */}
              <rect x="20" y="36" width="50" height="8" rx="2" fill="url(#dbGrad)"/>
              {/* left plates */}
              <rect x="12" y="24" width="10" height="32" rx="3" fill="url(#dbGrad)"/>
              <rect x="6" y="30" width="8" height="20" rx="2" fill="url(#dbGrad)" opacity="0.8"/>
              {/* right plates */}
              <rect x="68" y="24" width="10" height="32" rx="3" fill="url(#dbGrad)"/>
              <rect x="76" y="30" width="8" height="20" rx="2" fill="url(#dbGrad)" opacity="0.8"/>
            </svg>
          </div>
        </div>
      </div>

      {/* Duration + Calories row */}
      <div style={{ padding: '12px 20px 0', display: 'flex', gap: 12 }}>
        <div style={{ flex: 1, padding: 16, borderRadius: 16, background: 'rgba(26,15,43,0.7)', border: '1px solid rgba(139,92,246,0.18)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Icon name="clock" size={14} color={PALETTE.muted}/>
            <span style={{ fontSize: 12, color: PALETTE.muted }}>Duration</span>
          </div>
          <div style={{ marginTop: 10, fontSize: 22, fontWeight: 800, color: PALETTE.text, fontFamily: 'Inter' }}>01:12:34</div>
        </div>
        <div style={{ flex: 1, padding: 16, borderRadius: 16, background: 'rgba(26,15,43,0.7)', border: '1px solid rgba(139,92,246,0.18)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Icon name="target" size={14} color={PALETTE.muted}/>
            <span style={{ fontSize: 12, color: PALETTE.muted }}>Calories</span>
          </div>
          <div style={{ marginTop: 10, fontSize: 22, fontWeight: 800, color: PALETTE.text }}>612 <span style={{ fontSize: 13, color: PALETTE.muted, fontWeight: 600 }}>kcal</span></div>
        </div>
      </div>

      {/* Exercise breakdown */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{
          borderRadius: 20, padding: 18,
          background: 'linear-gradient(180deg, rgba(26,15,43,0.95) 0%, rgba(18,10,31,0.95) 100%)',
          border: '1px solid rgba(139,92,246,0.28)',
          boxShadow: '0 0 24px -8px rgba(139,92,246,0.3), inset 0 1px 0 rgba(255,255,255,0.04)',
          position: 'relative', overflow: 'hidden',
        }}>
          {/* ambient glow */}
          <div style={{
            position: 'absolute', top: -40, left: '50%', transform: 'translateX(-50%)',
            width: 260, height: 260, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(167,139,250,0.2), transparent 65%)',
            pointerEvents: 'none',
          }}/>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4, position: 'relative' }}>
            <div style={{ fontSize: 15, fontWeight: 700, color: PALETTE.text }}>Exercise Breakdown</div>
            <Pill variant="violet" style={{ fontSize: 9, padding: '3px 8px' }}>MUSCLES HIT · 3</Pill>
          </div>
          <div style={{ fontSize: 11, color: PALETTE.muted, marginBottom: 10, position: 'relative' }}>Primary activation zones</div>

          {/* Image frame */}
          <div style={{
            position: 'relative', borderRadius: 14, overflow: 'hidden',
            background: 'radial-gradient(ellipse at center, rgba(139,92,246,0.15), transparent 70%)',
            border: '1px solid rgba(139,92,246,0.18)',
            padding: '8px 0',
          }}>
            <img src="assets/body-full.png" alt="Exercise breakdown" style={{
              width: '100%', height: 'auto', display: 'block',
              filter: 'drop-shadow(0 0 12px rgba(167,139,250,0.3))',
              imageRendering: 'auto',
            }}/>
            {/* front/back labels below */}
            <div style={{ display: 'flex', justifyContent: 'space-around', marginTop: 6, paddingBottom: 2 }}>
              <span style={{ fontSize: 9, fontWeight: 700, letterSpacing: 1.5, color: PALETTE.muted }}>FRONT</span>
              <span style={{ fontSize: 9, fontWeight: 700, letterSpacing: 1.5, color: PALETTE.muted }}>BACK</span>
            </div>
          </div>

          {/* Muscle intensity chips */}
          <div style={{ display: 'flex', gap: 6, marginTop: 14, flexWrap: 'wrap', position: 'relative' }}>
            {[
              { name: 'Chest', pct: 45, intensity: 'high' },
              { name: 'Shoulders', pct: 30, intensity: 'high' },
              { name: 'Triceps', pct: 25, intensity: 'med' },
            ].map(m => (
              <div key={m.name} style={{
                flex: 1, padding: '8px 10px', borderRadius: 10,
                background: m.intensity === 'high' ? 'rgba(167,139,250,0.18)' : 'rgba(167,139,250,0.08)',
                border: `1px solid ${m.intensity === 'high' ? 'rgba(167,139,250,0.45)' : 'rgba(167,139,250,0.25)'}`,
                textAlign: 'center',
              }}>
                <div style={{ fontSize: 10, fontWeight: 700, color: PALETTE.violetSoft, letterSpacing: 0.5 }}>{m.name.toUpperCase()}</div>
                <div className="mono" style={{ fontSize: 13, fontWeight: 700, color: PALETTE.text, marginTop: 2 }}>{m.pct}%</div>
              </div>
            ))}
          </div>

          {/* View Full Breakdown - functional */}
          <button onClick={() => setShowSheet(true)} style={{
            width: '100%', height: 48, borderRadius: 24, marginTop: 16,
            background: 'linear-gradient(135deg, #A78BFA 0%, #8B5CF6 100%)',
            color: '#fff', fontWeight: 700, fontSize: 14,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            boxShadow: '0 8px 20px rgba(139,92,246,0.4), inset 0 1px 0 rgba(255,255,255,0.15)',
            position: 'relative',
          }}>
            View Full Breakdown
            <Icon name="arrow-right" size={16} color="#fff"/>
          </button>
        </div>
      </div>

      {/* XP earned banner */}
      <div style={{ padding: '12px 20px 0' }}>
        <div style={{
          padding: 16, borderRadius: 16,
          background: 'linear-gradient(135deg, rgba(245,166,35,0.2), rgba(245,166,35,0.08))',
          border: '1px solid rgba(245,166,35,0.4)',
          display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{ padding: 10, borderRadius: 12, background: 'rgba(245,166,35,0.2)' }}>
            <Icon name="bolt" size={22} color={PALETTE.amber}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, color: PALETTE.muted, fontWeight: 600 }}>XP Earned</div>
            <div className="display-font" style={{ fontSize: 28, color: PALETTE.amber, lineHeight: 1, marginTop: 2, textShadow: '0 0 12px rgba(245,166,35,0.5)' }}>+ 420 XP</div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: 11, color: PALETTE.muted }}>New PRs</div>
            <div className="display-font" style={{ fontSize: 22, color: PALETTE.text }}>2</div>
          </div>
        </div>
      </div>

      {/* Done */}
      <div style={{ padding: '16px 20px 0' }}>
        <button onClick={onDone} style={{
          width: '100%', height: 52, borderRadius: 14,
          background: 'rgba(139,92,246,0.15)', border: '1px solid rgba(139,92,246,0.4)',
          color: PALETTE.text, fontWeight: 700, fontSize: 14, letterSpacing: 1,
          fontFamily: 'Bebas Neue, sans-serif',
        }}>BACK TO HOME</button>
      </div>
      {showSheet && <BreakdownSheet onClose={() => setShowSheet(false)}/>}
    </div>
  );
};

Object.assign(window, { LoggerScreen, WorkoutCompleteScreen, BodySilhouette, BreakdownSheet });

// Wrap complete screen with sheet
const WorkoutCompleteWithSheet = WorkoutCompleteScreen;
