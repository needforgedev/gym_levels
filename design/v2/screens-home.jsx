// Home + Today's Workout screens

// ─── Anime character placeholder (stylized silhouette) ────
const HeroAvatar = ({ size = 64, style = {} }) => (
  <div style={{
    width: size, height: size, borderRadius: size/2,
    background: 'linear-gradient(135deg, #2D1B4E 0%, #1A0F2B 100%)',
    border: '2px solid rgba(139, 92, 246, 0.5)',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    position: 'relative', overflow: 'hidden',
    boxShadow: '0 0 16px rgba(139, 92, 246, 0.3)',
    ...style,
  }}>
    {/* stylized hair/head silhouette */}
    <svg width={size} height={size} viewBox="0 0 64 64" style={{ position: 'absolute' }}>
      <defs>
        <linearGradient id="hairGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#1a0f2b"/>
          <stop offset="1" stopColor="#0A0612"/>
        </linearGradient>
      </defs>
      {/* hair shape */}
      <path d="M10 30 Q10 12 32 10 Q54 12 54 30 L54 24 L48 28 L42 22 L38 30 L32 24 L26 30 L22 22 L16 28 L10 24 Z" fill="url(#hairGrad)"/>
      {/* face */}
      <ellipse cx="32" cy="38" rx="14" ry="16" fill="#F0D5B8" opacity="0.85"/>
      {/* eyes - violet glow */}
      <ellipse cx="27" cy="38" rx="1.8" ry="2.5" fill="#8B5CF6"/>
      <ellipse cx="37" cy="38" rx="1.8" ry="2.5" fill="#8B5CF6"/>
      {/* hair over forehead */}
      <path d="M18 28 L22 24 L26 30 L32 24 L38 30 L42 24 L46 28 L46 34 L18 34 Z" fill="url(#hairGrad)"/>
      {/* neck/body hint */}
      <path d="M18 56 Q18 50 32 50 Q46 50 46 56 L46 64 L18 64 Z" fill="#1a0f2b"/>
    </svg>
    {/* sparkle */}
    <div style={{ position: 'absolute', top: 4, right: 6, width: 3, height: 3, background: '#fff', borderRadius: '50%', animation: 'sparkle 2s infinite' }}/>
  </div>
);

// ─── Home screen ──────────────────────────────────────────
const HomeScreen = ({ onStartWorkout, onOpenNext, onOpenStreak, onOpenClass }) => {
  const levelPct = (USER.xpIntoLevel / USER.xpToNext) * 100;

  return (
    <div className="scroll" style={{ position: 'absolute', inset: 0, overflow: 'auto', paddingTop: 54, paddingBottom: 110 }}>
      {/* Top bar: greeting + avatar */}
      <div style={{ padding: '24px 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontSize: 13, color: PALETTE.muted, fontWeight: 500, letterSpacing: 0.2 }}>Welcome back,</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 2 }}>
            <span style={{ fontSize: 26, fontWeight: 800, color: PALETTE.text }}>{USER.name}</span>
            <span style={{ fontSize: 22 }}>🔥</span>
          </div>
          <div style={{ marginTop: 6 }}>
            <span style={{
              fontFamily: 'Bebas Neue, sans-serif',
              fontSize: 14, letterSpacing: 2,
              background: 'linear-gradient(90deg, #F5A623, #FBBF24)',
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
              fontWeight: 400,
            }} className="display-font">CLASS • {USER.class}</span>
          </div>
        </div>
        <button onClick={() => {}} style={{ position: 'relative' }}>
          <HeroAvatar size={48}/>
          <div style={{ position: 'absolute', top: -2, right: -2, width: 10, height: 10, borderRadius: '50%', background: PALETTE.amber, border: '2px solid #0A0612' }}/>
        </button>
      </div>

      {/* Level + XP strip */}
      <div style={{ padding: '12px 20px 0', display: 'flex', gap: 10 }}>
        <div style={{
          flex: 1, padding: '10px 14px', borderRadius: 12,
          background: 'linear-gradient(135deg, rgba(245,166,35,0.18), rgba(245,166,35,0.08))',
          border: '1px solid rgba(245,166,35,0.4)',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <Icon name="star" size={18} color={PALETTE.amber}/>
          <div>
            <div style={{ fontSize: 10, color: PALETTE.muted, letterSpacing: 1, fontWeight: 700 }}>LEVEL</div>
            <div className="display-font" style={{ fontSize: 22, color: PALETTE.amber, lineHeight: 1 }}>LV {USER.level}</div>
          </div>
        </div>
        <div style={{
          flex: 1.3, padding: '10px 14px', borderRadius: 12,
          background: 'linear-gradient(135deg, rgba(139,92,246,0.2), rgba(139,92,246,0.08))',
          border: '1px solid rgba(139,92,246,0.4)',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <Icon name="bolt" size={18} color={PALETTE.violetSoft}/>
          <div>
            <div style={{ fontSize: 10, color: PALETTE.muted, letterSpacing: 1, fontWeight: 700 }}>TOTAL XP</div>
            <div className="display-font" style={{ fontSize: 22, color: PALETTE.violetSoft, lineHeight: 1 }}>{USER.xp.toLocaleString()}</div>
          </div>
        </div>
      </div>

      {/* XP progress bar */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
          <span style={{ fontSize: 12, color: PALETTE.muted, fontWeight: 600 }}>Progress to Level {USER.level + 1}</span>
          <span className="mono" style={{ fontSize: 12, color: PALETTE.amber, fontWeight: 700 }}>{Math.round(levelPct)}%</span>
        </div>
        <XPBar pct={levelPct} height={10}/>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
          <span className="mono" style={{ fontSize: 10, color: PALETTE.dim }}>{USER.xpIntoLevel} XP</span>
          <span className="mono" style={{ fontSize: 10, color: PALETTE.dim }}>{USER.xpToNext} XP</span>
        </div>
      </div>

      {/* Row: Total workouts + Streak */}
      <div style={{ padding: '16px 20px 0', display: 'flex', gap: 12 }}>
        <Card style={{ flex: 1, padding: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }}>Total</div>
              <div className="display-font" style={{ fontSize: 34, color: PALETTE.text, lineHeight: 1, marginTop: 4 }}>{USER.totalWorkouts}</div>
              <div style={{ fontSize: 11, color: PALETTE.muted, marginTop: 4 }}>Workouts</div>
            </div>
            <div style={{ padding: 6, borderRadius: 10, background: 'rgba(139,92,246,0.15)' }}>
              <Icon name="dumbbell" size={18} color={PALETTE.violetSoft}/>
            </div>
          </div>
        </Card>
        <Card onClick={onOpenStreak} style={{ flex: 1, padding: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }}>Streak</div>
              <div className="display-font" style={{ fontSize: 34, color: PALETTE.streak, lineHeight: 1, marginTop: 4, textShadow: '0 0 12px rgba(255,107,53,0.6)' }}>{USER.streak}</div>
              <div style={{ fontSize: 11, color: PALETTE.streak, marginTop: 4, fontStyle: 'italic', fontWeight: 500 }}>On fire!</div>
            </div>
            <div style={{ animation: 'flamePulse 1.8s infinite' }}>
              <Icon name="fire" size={22} color={PALETTE.streak}/>
            </div>
          </div>
        </Card>
      </div>

      {/* Next workout card */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 8 }}>Next Workout</div>
        <Card onClick={onOpenNext} glow padding={0} style={{ overflow: 'hidden' }}>
          <div style={{ display: 'flex', alignItems: 'stretch' }}>
            <div style={{
              width: 80,
              background: 'linear-gradient(135deg, rgba(139,92,246,0.3), rgba(139,92,246,0.1))',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              borderRight: '1px solid rgba(139,92,246,0.2)',
            }}>
              <Icon name="dumbbell" size={36} color={PALETTE.violetSoft}/>
            </div>
            <div style={{ flex: 1, padding: '14px 16px' }}>
              <div className="display-font" style={{ fontSize: 22, color: PALETTE.text, lineHeight: 1 }}>{USER.nextWorkout.title.toUpperCase()}</div>
              <div style={{ fontSize: 12, color: PALETTE.muted, marginTop: 6 }}>{USER.nextWorkout.category} · ~{USER.nextWorkout.duration} · {USER.nextWorkout.exercises} exercises</div>
              <div style={{ marginTop: 8, display: 'flex', gap: 6 }}>
                <Pill variant="violet" style={{ fontSize: 10, padding: '3px 8px' }}>Chest</Pill>
                <Pill variant="violet" style={{ fontSize: 10, padding: '3px 8px' }}>Shoulders</Pill>
                <Pill variant="violet" style={{ fontSize: 10, padding: '3px 8px' }}>Triceps</Pill>
              </div>
            </div>
            <div style={{ padding: 16, display: 'flex', alignItems: 'center' }}>
              <Icon name="chevron-right" size={20} color={PALETTE.muted}/>
            </div>
          </div>
        </Card>
      </div>

      {/* Daily quest */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 8 }}>Today's Quest</div>
        <Card padding={14}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
            <div style={{ padding: 8, borderRadius: 10, background: 'rgba(245,166,35,0.15)', border: '1px solid rgba(245,166,35,0.3)' }}>
              <Icon name="target" size={20} color={PALETTE.amber}/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: PALETTE.text }}>Hit 3 sets at RPE 8+</div>
              <div style={{ fontSize: 11, color: PALETTE.muted, marginTop: 4 }}>Progress: 1 / 3 sets</div>
              <div style={{ marginTop: 8 }}>
                <div style={{ height: 4, background: 'rgba(245,166,35,0.15)', borderRadius: 2, overflow: 'hidden' }}>
                  <div style={{ width: '33%', height: '100%', background: PALETTE.amber, boxShadow: `0 0 6px ${PALETTE.amber}` }}/>
                </div>
              </div>
            </div>
            <div className="mono" style={{ fontSize: 12, fontWeight: 700, color: PALETTE.amber }}>+80 XP</div>
          </div>
        </Card>
      </div>

      {/* Start Workout CTA */}
      <div style={{ padding: '20px 20px 0' }}>
        <button onClick={onStartWorkout} style={{
          width: '100%', height: 58, borderRadius: 16,
          background: 'linear-gradient(135deg, #19E3E3 0%, #0EC6C6 100%)',
          color: '#0A0612', fontWeight: 800, fontSize: 16,
          letterSpacing: 1.2, textTransform: 'uppercase',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          boxShadow: '0 8px 24px rgba(25,227,227,0.3), inset 0 1px 0 rgba(255,255,255,0.3)',
          fontFamily: 'Bebas Neue, sans-serif',
        }}>
          <Icon name="play" size={18} color="#0A0612"/>
          START WORKOUT
        </button>
      </div>
    </div>
  );
};

// ─── Today's Workout screen ───────────────────────────────
const TodaysWorkoutScreen = ({ onBack, onStart }) => {
  const [expanded, setExpanded] = React.useState(false);
  return (
    <div className="scroll" style={{ position: 'absolute', inset: 0, overflow: 'auto', paddingTop: 54, paddingBottom: 110 }}>
      {/* Header */}
      <div style={{ padding: '20px 20px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onBack} style={{ width: 38, height: 38, borderRadius: 19, background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="chevron-left" size={20} color={PALETTE.text}/>
        </button>
        <div style={{ fontSize: 17, fontWeight: 700 }}>Today's Workout</div>
        <button style={{ fontSize: 13, color: PALETTE.teal, fontWeight: 600 }}>Edit</button>
      </div>

      {/* Title & summary */}
      <div style={{ padding: '8px 20px 0' }}>
        <div className="display-font" style={{ fontSize: 40, color: PALETTE.text, lineHeight: 1 }}>PUSH DAY</div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 12 }}>
          <Pill variant="violet">Upper Body</Pill>
          <Pill variant="ghost">~60 min</Pill>
          <Pill variant="ghost">5 exercises</Pill>
        </div>
      </div>

      {/* Muscle split */}
      <div style={{ padding: '16px 20px 0' }}>
        <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 8 }}>Volume Split</div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <div style={{ padding: '6px 12px', borderRadius: 8, background: 'rgba(245,166,35,0.15)', border: '1px solid rgba(245,166,35,0.3)', fontSize: 11, fontWeight: 600, color: PALETTE.amberSoft }}>
            chest 45%
          </div>
          <div style={{ padding: '6px 12px', borderRadius: 8, background: 'rgba(139,92,246,0.15)', border: '1px solid rgba(139,92,246,0.3)', fontSize: 11, fontWeight: 600, color: PALETTE.violetSoft }}>
            shoulders 30%
          </div>
          <div style={{ padding: '6px 12px', borderRadius: 8, background: 'rgba(34,224,107,0.15)', border: '1px solid rgba(34,224,107,0.3)', fontSize: 11, fontWeight: 600, color: '#22E06B' }}>
            triceps 25%
          </div>
        </div>
      </div>

      {/* Why this workout? */}
      <div style={{ padding: '14px 20px 0' }}>
        <button onClick={() => setExpanded(!expanded)} style={{
          width: '100%', padding: '12px 14px', borderRadius: 12,
          background: 'rgba(139,92,246,0.08)', border: '1px solid rgba(139,92,246,0.2)',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Icon name="info" size={16} color={PALETTE.violetSoft}/>
            <span style={{ fontSize: 13, fontWeight: 600, color: PALETTE.text }}>Why this workout?</span>
          </div>
          <Icon name="chevron-down" size={16} color={PALETTE.muted}/>
        </button>
        {expanded && (
          <div style={{
            marginTop: 8, padding: 14, borderRadius: 12,
            background: 'rgba(139,92,246,0.06)', border: '1px solid rgba(139,92,246,0.15)',
            fontSize: 12, color: PALETTE.muted, lineHeight: 1.6, fontStyle: 'italic',
          }}>
            <span style={{ color: PALETTE.violetSoft, fontWeight: 700 }}>[System]</span> Your priority muscles (Chest, Shoulders) are 72 hrs recovered. Previous leg day loaded posterior chain — pushing today to maintain split balance.
          </div>
        )}
      </div>

      {/* Exercises list */}
      <div style={{ padding: '20px 20px 0' }}>
        <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 10 }}>Exercises</div>
        {EXERCISES.map((ex, i) => (
          <Card key={ex.name} padding={14} style={{ marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
              <div style={{
                width: 42, height: 42, borderRadius: 10,
                background: 'linear-gradient(135deg, rgba(139,92,246,0.25), rgba(139,92,246,0.08))',
                border: '1px solid rgba(139,92,246,0.3)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>
                <Icon name="dumbbell" size={20} color={PALETTE.violetSoft}/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15, fontWeight: 700, color: PALETTE.text }}>{ex.name}</div>
                <div style={{ fontSize: 11, color: PALETTE.muted, marginTop: 2 }}>{ex.muscles}</div>
                <div className="mono" style={{ fontSize: 11, color: PALETTE.dim, marginTop: 6 }}>
                  {ex.sets.length} × {ex.sets[0].reps} @ {ex.sets[0].weight}kg
                </div>
              </div>
              <button style={{
                padding: '6px 10px', borderRadius: 8,
                background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)',
                fontSize: 11, fontWeight: 600, color: PALETTE.violetSoft,
                display: 'flex', alignItems: 'center', gap: 4,
              }}>
                <Icon name="swap" size={12}/>Swap
              </button>
            </div>
          </Card>
        ))}
      </div>

      {/* Start CTA */}
      <div style={{ padding: '16px 20px 0' }}>
        <button onClick={onStart} style={{
          width: '100%', height: 58, borderRadius: 16,
          background: 'linear-gradient(135deg, #19E3E3 0%, #0EC6C6 100%)',
          color: '#0A0612', fontWeight: 800, fontSize: 16,
          letterSpacing: 1.2, textTransform: 'uppercase',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          boxShadow: '0 8px 24px rgba(25,227,227,0.3)',
          fontFamily: 'Bebas Neue, sans-serif',
        }}>
          <Icon name="play" size={16} color="#0A0612"/>START WORKOUT
        </button>
      </div>
    </div>
  );
};

Object.assign(window, { HomeScreen, TodaysWorkoutScreen, HeroAvatar });
