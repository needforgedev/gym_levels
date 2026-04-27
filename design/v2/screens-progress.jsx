// Ranks, Streak, Weight Tracker, Profile screens + Class detail sheet

// ─── Ranks screen ─────────────────────────────────────────
const RanksScreen = ({ onBack }) => {
  return (
    <div className="scroll" style={{ position: 'absolute', inset: 0, overflow: 'auto', paddingTop: 54, paddingBottom: 110 }}>
      <div style={{ padding: '20px 20px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onBack} style={{ width: 38, height: 38, borderRadius: 19, background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="chevron-left" size={20} color={PALETTE.text}/>
        </button>
        <div style={{ fontSize: 17, fontWeight: 700 }}>Muscle Rankings</div>
        <div style={{ width: 38 }}/>
      </div>

      {/* Hero silhouette */}
      <div style={{ padding: '12px 20px 0', display: 'flex', justifyContent: 'center' }}>
        <div style={{ position: 'relative', filter: 'drop-shadow(0 0 20px rgba(139,92,246,0.5))' }}>
          <BodySilhouette back={false}/>
          {/* pulse accent */}
          <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', animation: 'pulseGlow 2s infinite', pointerEvents: 'none' }}/>
        </div>
      </div>

      {/* Overall rank badge */}
      <div style={{ padding: '8px 20px 0', display: 'flex', justifyContent: 'center' }}>
        <div style={{
          padding: '12px 28px', borderRadius: 14,
          background: 'linear-gradient(135deg, rgba(245,166,35,0.2), rgba(245,166,35,0.08))',
          border: '1.5px solid rgba(245,166,35,0.5)',
          boxShadow: '0 0 24px -6px rgba(245,166,35,0.5)',
          textAlign: 'center',
        }}>
          <div style={{ fontSize: 10, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1.5 }}>OVERALL RANK</div>
          <div className="display-font" style={{ fontSize: 28, color: PALETTE.amber, lineHeight: 1, marginTop: 4, textShadow: '0 0 12px rgba(245,166,35,0.5)' }}>SILVER III</div>
        </div>
      </div>

      {/* Per-muscle list */}
      <div style={{ padding: '18px 20px 0' }}>
        {MUSCLES.map((m, i) => (
          <div key={m.name} style={{
            padding: '12px 14px', borderRadius: 12, marginBottom: 8,
            background: 'rgba(26,15,43,0.6)',
            border: '1px solid rgba(139,92,246,0.15)',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: `linear-gradient(135deg, ${m.color}33, ${m.color}15)`,
              border: `1px solid ${m.color}50`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <span style={{ fontFamily: 'Bebas Neue', fontSize: 16, color: m.color }}>{m.name[0]}</span>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700 }}>{m.name}</div>
              <div style={{ marginTop: 4, height: 3, background: 'rgba(139,92,246,0.1)', borderRadius: 2, overflow: 'hidden' }}>
                <div style={{ width: `${m.pct}%`, height: '100%', background: m.color, boxShadow: `0 0 6px ${m.color}` }}/>
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: m.color, fontFamily: 'Bebas Neue', letterSpacing: 1 }}>{m.tier.toUpperCase()}</div>
              <div className="mono" style={{ fontSize: 10, color: PALETTE.muted, marginTop: 2 }}>{m.xp} XP</div>
            </div>
            <Icon name="chevron-right" size={14} color={PALETTE.dim}/>
          </div>
        ))}
      </div>
    </div>
  );
};

// ─── Streak screen ────────────────────────────────────────
const StreakScreen = () => {
  // generate month calendar (Feb 2026)
  const days = [];
  const completed = new Set([1,2,3,5,6,8,9,10,12,13,15,16,17,19,20,22,23]);
  const frozen = new Set([7]);
  const missed = new Set([14]);
  const today = 24;
  for (let d = 1; d <= 28; d++) days.push(d);
  // leading blanks (Feb 2026 starts Sunday)
  const leading = new Array(0).fill(null);

  return (
    <div className="scroll" style={{ position: 'absolute', inset: 0, overflow: 'auto', paddingTop: 54, paddingBottom: 110 }}>
      <div style={{ padding: '20px 20px 12px', textAlign: 'center' }}>
        <div style={{ fontSize: 17, fontWeight: 700 }}>Streak</div>
      </div>

      {/* Hero number */}
      <div style={{ padding: '12px 20px 0', textAlign: 'center' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 12, animation: 'flamePulse 1.8s infinite' }}>
          <Icon name="fire" size={52} color={PALETTE.streak}/>
          <span className="display-font" style={{ fontSize: 96, color: PALETTE.streak, lineHeight: 0.9, textShadow: '0 0 24px rgba(255,107,53,0.6)' }}>47</span>
        </div>
        <div style={{ fontSize: 14, color: PALETTE.muted, marginTop: 4 }}>day streak · <span style={{ color: PALETTE.streak, fontStyle: 'italic', fontWeight: 600 }}>On fire!</span></div>
      </div>

      {/* This month pill */}
      <div style={{ padding: '16px 20px 0', display: 'flex', justifyContent: 'center' }}>
        <Pill variant="streak" style={{ fontSize: 12 }}>
          <Icon name="cal" size={12} color={PALETTE.streak}/> 14 THIS MONTH
        </Pill>
      </div>

      {/* Streak Freezes */}
      <div style={{ padding: '16px 20px 0' }}>
        <Card padding={14}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ padding: 10, borderRadius: 12, background: 'rgba(25,227,227,0.12)', border: '1px solid rgba(25,227,227,0.3)' }}>
              <Icon name="snowflake" size={20} color={PALETTE.teal}/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700 }}>Streak Freezes — 2/2 available</div>
              <div style={{ fontSize: 11, color: PALETTE.muted, marginTop: 2 }}>All freezes available</div>
            </div>
            <div style={{ display: 'flex', gap: 4 }}>
              <div style={{ width: 28, height: 28, borderRadius: 8, background: 'rgba(25,227,227,0.15)', border: '1px solid rgba(25,227,227,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="snowflake" size={14} color={PALETTE.teal}/></div>
              <div style={{ width: 28, height: 28, borderRadius: 8, background: 'rgba(25,227,227,0.15)', border: '1px solid rgba(25,227,227,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="snowflake" size={14} color={PALETTE.teal}/></div>
            </div>
          </div>
        </Card>
      </div>

      {/* Calendar */}
      <div style={{ padding: '16px 20px 0' }}>
        <Card padding={16}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <button><Icon name="chevron-left" size={16} color={PALETTE.muted}/></button>
            <div style={{ fontSize: 13, fontWeight: 700 }}>February 2026</div>
            <button><Icon name="chevron-right" size={16} color={PALETTE.muted}/></button>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6, marginBottom: 6 }}>
            {['S','M','T','W','T','F','S'].map((d, i) => (
              <div key={i} style={{ textAlign: 'center', fontSize: 10, color: PALETTE.muted, fontWeight: 700 }}>{d}</div>
            ))}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6 }}>
            {leading.map((_, i) => <div key={`l${i}`}/>)}
            {days.map(d => {
              const isToday = d === today;
              const isCompleted = completed.has(d);
              const isFrozen = frozen.has(d);
              const isMissed = missed.has(d);
              let bg = 'rgba(139,92,246,0.05)';
              let border = '1px solid rgba(139,92,246,0.1)';
              let color = PALETTE.dim;
              if (isCompleted) { bg = 'linear-gradient(135deg, rgba(245,166,35,0.6), rgba(245,166,35,0.3))'; border = '1px solid rgba(245,166,35,0.6)'; color = '#0A0612'; }
              if (isFrozen) { bg = 'rgba(25,227,227,0.2)'; border = '1px solid rgba(25,227,227,0.5)'; color = PALETTE.teal; }
              if (isMissed) { bg = 'rgba(255,107,53,0.12)'; border = '1px dashed rgba(255,107,53,0.4)'; color = PALETTE.streak; }
              return (
                <div key={d} style={{
                  aspectRatio: '1', borderRadius: 8,
                  background: bg, border, color,
                  fontSize: 12, fontWeight: 700,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  position: 'relative',
                  boxShadow: isToday ? '0 0 0 2px rgba(139,92,246,0.6)' : 'none',
                  animation: isToday ? 'pulseGlow 2s infinite' : 'none',
                }}>
                  {d}
                  {isFrozen && <div style={{ position: 'absolute', top: 2, right: 2, fontSize: 8 }}>❄</div>}
                </div>
              );
            })}
          </div>
          <div style={{ marginTop: 14, display: 'flex', gap: 12, flexWrap: 'wrap', fontSize: 10, color: PALETTE.muted }}>
            <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: PALETTE.amber, marginRight: 4 }}/>Completed</span>
            <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: PALETTE.teal, marginRight: 4 }}/>Freeze</span>
            <span><span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: 2, background: PALETTE.streak, marginRight: 4 }}/>Missed</span>
          </div>
        </Card>
      </div>
    </div>
  );
};

// ─── Weight Tracker ───────────────────────────────────────
const WeightScreen = ({ onBack }) => {
  const [range, setRange] = React.useState('30D');
  // Sample data points
  const pts = [80.8, 80.6, 80.9, 80.4, 80.2, 80.5, 80.1, 79.9, 80.0, 79.8, 79.7, 79.9];
  const maxY = Math.max(...pts) + 0.3;
  const minY = Math.min(...pts) - 0.3;
  const w = 322, h = 140;
  const stepX = w / (pts.length - 1);
  const toY = v => h - ((v - minY) / (maxY - minY)) * h;
  const path = pts.map((v, i) => `${i === 0 ? 'M' : 'L'} ${i * stepX} ${toY(v)}`).join(' ');
  const areaPath = `${path} L ${(pts.length - 1) * stepX} ${h} L 0 ${h} Z`;

  return (
    <div className="scroll" style={{ position: 'absolute', inset: 0, overflow: 'auto', paddingTop: 54, paddingBottom: 110 }}>
      <div style={{ padding: '20px 20px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onBack} style={{ width: 38, height: 38, borderRadius: 19, background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="chevron-left" size={20} color={PALETTE.text}/>
        </button>
        <div style={{ fontSize: 17, fontWeight: 700 }}>Weight Tracker</div>
        <button style={{ fontSize: 13, color: PALETTE.teal, fontWeight: 600 }}>+ Log</button>
      </div>

      {/* Current weight card */}
      <div style={{ padding: '12px 20px 0' }}>
        <Card padding={18} glow>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
            <div>
              <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1 }}>CURRENT WEIGHT</div>
              <div style={{ marginTop: 8, display: 'flex', alignItems: 'baseline', gap: 6 }}>
                <span className="display-font" style={{ fontSize: 52, color: PALETTE.text, lineHeight: 1 }}>79.9</span>
                <span style={{ fontSize: 16, color: PALETTE.muted, fontWeight: 600 }}>kg</span>
              </div>
              <div style={{ marginTop: 8, display: 'flex', gap: 8 }}>
                <Pill variant="ghost" style={{ fontSize: 10, color: '#22E06B', background: 'rgba(34,224,107,0.12)', border: '1px solid rgba(34,224,107,0.3)' }}>
                  <Icon name="arrow-down" size={10} color="#22E06B"/> 0.2 kg
                </Pill>
                <Pill variant="amber" style={{ fontSize: 10 }}>5.1 KG TO GO</Pill>
              </div>
            </div>
            <div style={{ padding: 10, borderRadius: 12, background: 'rgba(139,92,246,0.12)' }}>
              <Icon name="scale" size={24} color={PALETTE.violetSoft}/>
            </div>
          </div>
        </Card>
      </div>

      {/* Tabs: Start / Current / Target */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{ display: 'flex', gap: 6, padding: 4, borderRadius: 12, background: 'rgba(26,15,43,0.8)', border: '1px solid rgba(139,92,246,0.15)' }}>
          {['Start 85.0', 'Current 79.9', 'Target 74.8'].map((t, i) => (
            <button key={t} style={{
              flex: 1, padding: '8px 4px', borderRadius: 8,
              background: i === 1 ? 'rgba(139,92,246,0.25)' : 'transparent',
              border: i === 1 ? '1px solid rgba(139,92,246,0.4)' : '1px solid transparent',
              fontSize: 11, fontWeight: 700, color: i === 1 ? PALETTE.violetSoft : PALETTE.muted,
            }}>{t}</button>
          ))}
        </div>
      </div>

      {/* Weight trend */}
      <div style={{ padding: '14px 20px 0' }}>
        <Card padding={16}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <div style={{ fontSize: 14, fontWeight: 700 }}>Weight Trend</div>
            <div style={{ display: 'flex', gap: 4 }}>
              {['30D', '90D', '1Y'].map(r => (
                <button key={r} onClick={() => setRange(r)} style={{
                  padding: '4px 10px', borderRadius: 8,
                  background: range === r ? 'rgba(139,92,246,0.2)' : 'transparent',
                  border: range === r ? '1px solid rgba(139,92,246,0.4)' : '1px solid rgba(139,92,246,0.1)',
                  fontSize: 10, fontWeight: 700, color: range === r ? PALETTE.violetSoft : PALETTE.muted,
                }}>{r}</button>
              ))}
            </div>
          </div>
          <svg width={w} height={h + 20} style={{ display: 'block' }}>
            <defs>
              <linearGradient id="weightGrad" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0" stopColor="#19E3E3"/>
                <stop offset="1" stopColor="#8B5CF6"/>
              </linearGradient>
              <linearGradient id="weightArea" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor="#8B5CF6" stopOpacity="0.3"/>
                <stop offset="1" stopColor="#8B5CF6" stopOpacity="0"/>
              </linearGradient>
            </defs>
            <path d={areaPath} fill="url(#weightArea)"/>
            <path d={path} stroke="url(#weightGrad)" strokeWidth="2.5" fill="none" strokeLinecap="round"/>
            {pts.map((v, i) => (
              <circle key={i} cx={i * stepX} cy={toY(v)} r="3" fill="#A78BFA" stroke="#0A0612" strokeWidth="1.5" style={{ filter: 'drop-shadow(0 0 4px rgba(167,139,250,0.8))' }}/>
            ))}
          </svg>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: PALETTE.dim, marginTop: 4 }}>
            <span>Mar 25</span><span>Apr 8</span><span>Apr 24</span>
          </div>
        </Card>
      </div>
    </div>
  );
};

// ─── Player Class detail sheet ────────────────────────────
const ClassSheet = ({ onClose }) => (
  <div style={{
    position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.6)',
    display: 'flex', alignItems: 'flex-end', zIndex: 100,
    animation: 'fadeIn 0.2s',
  }} onClick={onClose}>
    <div onClick={e => e.stopPropagation()} style={{
      width: '100%', borderRadius: '28px 28px 0 0',
      background: 'linear-gradient(180deg, #1A0F2B 0%, #0A0612 100%)',
      border: '1px solid rgba(245,166,35,0.3)',
      borderBottom: 'none',
      padding: '12px 24px 40px',
      animation: 'slideUp 0.3s ease-out',
      maxHeight: '85%', overflow: 'auto',
    }}>
      <div style={{ width: 40, height: 4, background: 'rgba(255,255,255,0.2)', borderRadius: 2, margin: '0 auto 20px' }}/>

      {/* Class art */}
      <div style={{ textAlign: 'center' }}>
        <div style={{
          width: 140, height: 140, margin: '0 auto',
          borderRadius: 24,
          background: 'linear-gradient(135deg, rgba(245,166,35,0.25), rgba(139,92,246,0.2))',
          border: '2px solid rgba(245,166,35,0.5)',
          boxShadow: '0 0 40px rgba(245,166,35,0.4), inset 0 1px 0 rgba(255,255,255,0.1)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative', overflow: 'hidden',
        }}>
          <Icon name="dumbbell" size={64} color={PALETTE.amber}/>
          {/* sparkles */}
          <div style={{ position: 'absolute', top: 12, left: 14, color: '#fff', fontSize: 16, animation: 'sparkle 2s infinite' }}>✦</div>
          <div style={{ position: 'absolute', bottom: 16, right: 18, color: PALETTE.amber, fontSize: 12, animation: 'sparkle 2.5s infinite' }}>✦</div>
          <div style={{ position: 'absolute', top: 20, right: 20, color: '#fff', fontSize: 10, animation: 'sparkle 1.8s infinite' }}>✦</div>
        </div>
        <div className="display-font" style={{ fontSize: 38, color: PALETTE.amber, marginTop: 16, lineHeight: 1, textShadow: '0 0 14px rgba(245,166,35,0.5)' }}>MASS BUILDER</div>
        <div style={{ fontSize: 13, color: PALETTE.muted, marginTop: 6 }}>Building size through volume and dedication.</div>
      </div>

      {/* Buffs */}
      <div style={{ marginTop: 24 }}>
        <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1 }}>CLASS BUFFS</div>
        <div style={{ marginTop: 10 }}>
          {[
            { icon: 'bolt', label: '+15% XP on compound lifts' },
            { icon: 'target', label: 'Volume quests 2× more frequent' },
            { icon: 'star', label: 'Unlock exclusive hypertrophy boss challenges' },
          ].map((b, i) => (
            <div key={i} style={{ padding: '10px 0', display: 'flex', alignItems: 'center', gap: 12, borderTop: i > 0 ? '1px solid rgba(139,92,246,0.1)' : 'none' }}>
              <div style={{ padding: 6, borderRadius: 8, background: 'rgba(245,166,35,0.15)' }}>
                <Icon name={b.icon} size={14} color={PALETTE.amber}/>
              </div>
              <span style={{ fontSize: 13, color: PALETTE.text }}>{b.label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Evolutions */}
      <div style={{ marginTop: 20 }}>
        <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1 }}>POSSIBLE EVOLUTIONS</div>
        <div style={{ marginTop: 10, display: 'flex', gap: 8 }}>
          {['Iron Titan', 'Colossus'].map(e => (
            <div key={e} style={{
              flex: 1, padding: 12, borderRadius: 12,
              background: 'rgba(139,92,246,0.1)', border: '1px dashed rgba(139,92,246,0.3)',
              textAlign: 'center',
            }}>
              <div style={{ fontSize: 20, marginBottom: 4 }}>⚔️</div>
              <div style={{ fontSize: 11, fontWeight: 700, color: PALETTE.violetSoft, fontFamily: 'Bebas Neue', letterSpacing: 1 }}>{e.toUpperCase()}</div>
              <div style={{ fontSize: 9, color: PALETTE.dim, marginTop: 2 }}>LV 25 required</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  </div>
);

// ─── Profile screen ───────────────────────────────────────
const ProfileScreen = ({ onOpenClass, onOpenRanks, onOpenWeight }) => {
  const levelPct = (USER.xpIntoLevel / USER.xpToNext) * 100;
  return (
    <div className="scroll" style={{ position: 'absolute', inset: 0, overflow: 'auto', paddingTop: 54, paddingBottom: 110 }}>
      <div style={{ padding: '20px 20px 12px', textAlign: 'center' }}>
        <div style={{ fontSize: 17, fontWeight: 700 }}>Profile</div>
      </div>

      {/* Profile header */}
      <div style={{ padding: '8px 20px 0' }}>
        <Card padding={16}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <HeroAvatar size={64}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 18, fontWeight: 800 }}>{USER.name}</div>
              <div style={{ fontSize: 12, color: PALETTE.muted, marginTop: 2 }}>{USER.email}</div>
            </div>
            <button style={{ padding: 8, borderRadius: 10, background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)' }}>
              <Icon name="edit" size={16} color={PALETTE.violetSoft}/>
            </button>
          </div>

          {/* Level row */}
          <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
            <div style={{ padding: '8px 12px', borderRadius: 10, background: 'rgba(245,166,35,0.15)', border: '1px solid rgba(245,166,35,0.35)' }}>
              <span className="display-font" style={{ fontSize: 16, color: PALETTE.amber, letterSpacing: 1 }}>LV {USER.level}</span>
            </div>
            <div style={{ padding: '8px 12px', borderRadius: 10, background: 'rgba(139,92,246,0.15)', border: '1px solid rgba(139,92,246,0.35)' }}>
              <span className="display-font" style={{ fontSize: 16, color: PALETTE.violetSoft, letterSpacing: 0.5 }}>{USER.xp.toLocaleString()} XP</span>
            </div>
          </div>

          {/* Progress bar */}
          <div style={{ marginTop: 14 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
              <span style={{ fontSize: 11, color: PALETTE.muted }}>Progress to Level {USER.level + 1}</span>
              <span className="mono" style={{ fontSize: 11, color: PALETTE.amber, fontWeight: 700 }}>{Math.round(levelPct)}%</span>
            </div>
            <XPBar pct={levelPct} height={8}/>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
              <span className="mono" style={{ fontSize: 9, color: PALETTE.dim }}>{USER.xpIntoLevel} XP</span>
              <span className="mono" style={{ fontSize: 9, color: PALETTE.dim }}>{USER.xpToNext} XP</span>
            </div>
          </div>

          <div style={{ marginTop: 14 }}>
            <Pill variant="amber" style={{ fontSize: 10, padding: '5px 12px' }}>
              <Icon name="shield" size={11}/> PRO MEMBER
            </Pill>
          </div>
        </Card>
      </div>

      {/* Player Class card */}
      <div style={{ padding: '14px 20px 0' }}>
        <Card onClick={onOpenClass} padding={0} style={{
          background: 'linear-gradient(135deg, rgba(245,166,35,0.15), rgba(139,92,246,0.1))',
          border: '1.5px solid rgba(245,166,35,0.45)',
          overflow: 'hidden', position: 'relative',
          boxShadow: '0 0 24px -4px rgba(245,166,35,0.25)',
        }}>
          <div style={{ padding: 18, display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{
              width: 76, height: 76, borderRadius: 16,
              background: 'linear-gradient(135deg, rgba(245,166,35,0.3), rgba(139,92,246,0.15))',
              border: '1.5px solid rgba(245,166,35,0.5)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              position: 'relative', overflow: 'hidden',
              boxShadow: '0 0 20px rgba(245,166,35,0.3)',
            }}>
              <Icon name="dumbbell" size={38} color={PALETTE.amber}/>
              <div style={{ position: 'absolute', top: 4, left: 6, fontSize: 10, color: '#fff', animation: 'sparkle 2s infinite' }}>✦</div>
              <div style={{ position: 'absolute', bottom: 6, right: 8, fontSize: 8, color: PALETTE.amber, animation: 'sparkle 2.5s infinite' }}>✦</div>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 10, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1 }}>PLAYER CLASS</div>
              <div className="display-font" style={{ fontSize: 24, color: PALETTE.amber, lineHeight: 1, marginTop: 4, textShadow: '0 0 10px rgba(245,166,35,0.4)' }}>MASS BUILDER</div>
              <div style={{ fontSize: 11, color: PALETTE.muted, marginTop: 4 }}>Building size through volume and dedication.</div>
            </div>
            <Icon name="chevron-right" size={18} color={PALETTE.muted}/>
          </div>
        </Card>
      </div>

      {/* Body stats */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{ fontSize: 11, color: PALETTE.muted, fontWeight: 700, letterSpacing: 1, marginBottom: 8, textTransform: 'uppercase' }}>Body Stats</div>
        <Card padding={0}>
          {[
            { label: 'Age', value: '25 years', icon: 'user' },
            { label: 'Height', value: '175 cm', icon: 'chart' },
            { label: 'BMI', value: '24.5 (Normal)', icon: 'target' },
            { label: 'Weight', value: '79.9 kg', icon: 'scale', onClick: onOpenWeight },
          ].map((r, i) => (
            <button key={r.label} onClick={r.onClick} style={{
              width: '100%', padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12,
              borderTop: i > 0 ? '1px solid rgba(139,92,246,0.08)' : 'none',
              textAlign: 'left', cursor: r.onClick ? 'pointer' : 'default',
            }}>
              <div style={{ padding: 6, borderRadius: 8, background: 'rgba(139,92,246,0.12)' }}>
                <Icon name={r.icon} size={14} color={PALETTE.violetSoft}/>
              </div>
              <span style={{ flex: 1, fontSize: 13, fontWeight: 500 }}>{r.label}</span>
              <span style={{ fontSize: 13, color: PALETTE.muted }}>{r.value}</span>
              {r.onClick && <Icon name="chevron-right" size={14} color={PALETTE.dim}/>}
            </button>
          ))}
        </Card>
      </div>

      {/* Menu list */}
      <div style={{ padding: '14px 20px 0' }}>
        <Card padding={0}>
          {[
            { label: 'Muscle Rankings', icon: 'trophy', onClick: onOpenRanks },
            { label: 'Edit Onboarding', icon: 'edit' },
            { label: 'Notifications', icon: 'bell' },
            { label: 'Subscription', icon: 'shield' },
            { label: 'Sign Out', icon: 'logout', danger: true },
          ].map((r, i) => (
            <button key={r.label} onClick={r.onClick} style={{
              width: '100%', padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12,
              borderTop: i > 0 ? '1px solid rgba(139,92,246,0.08)' : 'none',
              textAlign: 'left',
            }}>
              <div style={{ padding: 6, borderRadius: 8, background: r.danger ? 'rgba(255,107,53,0.12)' : 'rgba(139,92,246,0.12)' }}>
                <Icon name={r.icon} size={14} color={r.danger ? PALETTE.streak : PALETTE.violetSoft}/>
              </div>
              <span style={{ flex: 1, fontSize: 13, fontWeight: 500, color: r.danger ? PALETTE.streak : PALETTE.text }}>{r.label}</span>
              <Icon name="chevron-right" size={14} color={PALETTE.dim}/>
            </button>
          ))}
        </Card>
      </div>
    </div>
  );
};

Object.assign(window, { RanksScreen, StreakScreen, WeightScreen, ProfileScreen, ClassSheet });
