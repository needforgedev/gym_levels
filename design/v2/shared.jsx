// Shared components, icons, data

const PALETTE = {
  bg: '#0A0612',
  bgCard: '#120A1F',
  bgCard2: '#1A0F2B',
  violet: '#8B5CF6',
  violetSoft: '#A78BFA',
  amber: '#F5A623',
  amberSoft: '#FBBF24',
  streak: '#FF6B35',
  teal: '#19E3E3',
  text: '#ECE9F5',
  muted: '#8A809B',
  dim: '#5A5169',
};

// ─── Icons (minimal, geometric) ───────────────────────────
const Icon = ({ name, size = 22, color = 'currentColor', strokeWidth = 2 }) => {
  const p = { width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: color, strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round' };
  const s = { ...p, fill: color, stroke: 'none' };
  switch (name) {
    case 'home': return <svg {...p}><path d="M3 10.5L12 3l9 7.5V20a1 1 0 01-1 1h-5v-7h-6v7H4a1 1 0 01-1-1v-9.5z"/></svg>;
    case 'scroll': return <svg {...p}><path d="M8 3h11a2 2 0 012 2v14a2 2 0 01-2 2H8"/><path d="M5 3a2 2 0 00-2 2v4h5"/><path d="M8 3v18"/></svg>;
    case 'flame': return <svg {...s}><path d="M12 2s4 4 4 8a4 4 0 01-8 0c0-1.5.5-2.5 1-3 0 2 1 3 2 3 0-3-1-5 1-8z M6 14c0 3.3 2.7 6 6 6s6-2.7 6-6c0-2-1-4-2-5 0 3-2 5-4 5s-3-1-3-3c-2 1-3 3-3 3z"/></svg>;
    case 'crown': return <svg {...p}><path d="M3 8l3 10h12l3-10-5 4-4-7-4 7-5-4z"/></svg>;
    case 'dumbbell': return <svg {...p}><path d="M6 6v12M18 6v12M3 9v6M21 9v6M6 12h12"/></svg>;
    case 'clock': return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>;
    case 'fire': return <svg {...s}><path d="M12 2c1 3 3 5 3 8 0 1.5-.5 2.5-1 3 0-2-1-3-2-3-1 3-3 4-3 7a5 5 0 0010 0c0-4-4-6-7-15z"/></svg>;
    case 'plus': return <svg {...p}><path d="M12 5v14M5 12h14"/></svg>;
    case 'minus': return <svg {...p}><path d="M5 12h14"/></svg>;
    case 'close': return <svg {...p}><path d="M6 6l12 12M18 6L6 18"/></svg>;
    case 'check': return <svg {...p}><path d="M4 12l5 5L20 6"/></svg>;
    case 'chevron-right': return <svg {...p}><path d="M9 6l6 6-6 6"/></svg>;
    case 'chevron-left': return <svg {...p}><path d="M15 6l-6 6 6 6"/></svg>;
    case 'chevron-down': return <svg {...p}><path d="M6 9l6 6 6-6"/></svg>;
    case 'arrow-right': return <svg {...p}><path d="M5 12h14M13 5l7 7-7 7"/></svg>;
    case 'arrow-up': return <svg {...p}><path d="M12 19V5M5 12l7-7 7 7"/></svg>;
    case 'arrow-down': return <svg {...p}><path d="M12 5v14M5 12l7 7 7-7"/></svg>;
    case 'bell': return <svg {...p}><path d="M6 9a6 6 0 1112 0v3l2 4H4l2-4V9z"/><path d="M10 19a2 2 0 004 0"/></svg>;
    case 'bolt': return <svg {...s}><path d="M13 2L3 14h7l-1 8 10-12h-7l1-8z"/></svg>;
    case 'trophy': return <svg {...p}><path d="M8 3h8v6a4 4 0 01-8 0V3z"/><path d="M4 5h4v2a3 3 0 01-3 3H4V5zM20 5h-4v2a3 3 0 003 3h1V5z"/><path d="M9 13h6v3H9zM7 21h10"/><path d="M10 16h4v5h-4z"/></svg>;
    case 'target': return <svg {...p}><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1" fill={color}/></svg>;
    case 'edit': return <svg {...p}><path d="M4 20h4L20 8l-4-4L4 16v4z"/></svg>;
    case 'sparkle': return <svg {...s}><path d="M12 2l2 7 7 3-7 3-2 7-2-7-7-3 7-3 2-7z"/></svg>;
    case 'swap': return <svg {...p}><path d="M7 4l-4 4 4 4M3 8h14M17 12l4 4-4 4M21 16H7"/></svg>;
    case 'play': return <svg {...s}><path d="M8 5v14l11-7z"/></svg>;
    case 'cal': return <svg {...p}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>;
    case 'chart': return <svg {...p}><path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/></svg>;
    case 'user': return <svg {...p}><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/></svg>;
    case 'scale': return <svg {...p}><path d="M12 3v3M5 9h14l-2 8H7L5 9zM8 9a4 4 0 118 0"/></svg>;
    case 'shield': return <svg {...p}><path d="M12 2l8 4v6c0 5-3.5 9-8 10-4.5-1-8-5-8-10V6l8-4z"/></svg>;
    case 'snowflake': return <svg {...p}><path d="M12 2v20M2 12h20M5 5l14 14M19 5L5 19"/></svg>;
    case 'logout': return <svg {...p}><path d="M9 3H5a2 2 0 00-2 2v14a2 2 0 002 2h4M16 17l5-5-5-5M21 12H9"/></svg>;
    case 'info': return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M12 8v.01M11 12h1v4h1"/></svg>;
    case 'star': return <svg {...s}><path d="M12 2l3 7 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1 3-7z"/></svg>;
    default: return null;
  }
};

// ─── Status bar (dark mode) ───────────────────────────────
const StatusBar = () => (
  <div style={{
    height: 54, padding: '14px 30px 0', display: 'flex',
    justifyContent: 'space-between', alignItems: 'center',
    color: '#fff', fontSize: 17, fontWeight: 600,
    position: 'absolute', top: 0, left: 0, right: 0, zIndex: 20,
  }}>
    <span>9:41</span>
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      {/* signal */}
      <svg width="18" height="11" viewBox="0 0 18 11"><rect x="0" y="7" width="3" height="4" rx="0.5" fill="#fff"/><rect x="5" y="5" width="3" height="6" rx="0.5" fill="#fff"/><rect x="10" y="3" width="3" height="8" rx="0.5" fill="#fff"/><rect x="15" y="0" width="3" height="11" rx="0.5" fill="#fff"/></svg>
      {/* battery */}
      <svg width="26" height="12" viewBox="0 0 26 12"><rect x="0.5" y="0.5" width="22" height="11" rx="2.5" fill="none" stroke="#fff" strokeOpacity="0.5"/><rect x="2" y="2" width="19" height="8" rx="1.5" fill="#fff"/><rect x="23.5" y="4" width="1.5" height="4" rx="0.5" fill="#fff" fillOpacity="0.5"/></svg>
    </div>
  </div>
);

// ─── Card ─────────────────────────────────────────────────
const Card = ({ children, style = {}, glow = false, onClick, padding = 16 }) => (
  <div onClick={onClick} style={{
    background: 'linear-gradient(180deg, rgba(26, 15, 43, 0.9) 0%, rgba(18, 10, 31, 0.9) 100%)',
    border: glow ? '1px solid rgba(139, 92, 246, 0.4)' : '1px solid rgba(139, 92, 246, 0.15)',
    borderRadius: 18, padding,
    boxShadow: glow ? '0 0 24px -8px rgba(139, 92, 246, 0.4), inset 0 1px 0 rgba(255,255,255,0.03)' : 'inset 0 1px 0 rgba(255,255,255,0.03)',
    cursor: onClick ? 'pointer' : 'default',
    transition: 'transform 0.15s',
    ...style,
  }}
  onMouseDown={e => onClick && (e.currentTarget.style.transform = 'scale(0.98)')}
  onMouseUp={e => onClick && (e.currentTarget.style.transform = 'scale(1)')}
  onMouseLeave={e => onClick && (e.currentTarget.style.transform = 'scale(1)')}
  >
    {children}
  </div>
);

// ─── Pill ─────────────────────────────────────────────────
const Pill = ({ children, variant = 'violet', style = {} }) => {
  const variants = {
    violet: { bg: 'rgba(139, 92, 246, 0.18)', border: 'rgba(139, 92, 246, 0.4)', color: '#C4B5FD' },
    amber: { bg: 'rgba(245, 166, 35, 0.15)', border: 'rgba(245, 166, 35, 0.4)', color: '#FBBF24' },
    teal: { bg: 'rgba(25, 227, 227, 0.12)', border: 'rgba(25, 227, 227, 0.4)', color: '#19E3E3' },
    streak: { bg: 'rgba(255, 107, 53, 0.15)', border: 'rgba(255, 107, 53, 0.4)', color: '#FF6B35' },
    ghost: { bg: 'rgba(139, 92, 246, 0.08)', border: 'rgba(139, 92, 246, 0.2)', color: '#A78BFA' },
  };
  const v = variants[variant] || variants.violet;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '6px 12px', borderRadius: 999,
      background: v.bg, border: `1px solid ${v.border}`,
      color: v.color, fontSize: 12, fontWeight: 600,
      letterSpacing: 0.3, textTransform: 'uppercase',
      ...style,
    }}>{children}</span>
  );
};

// ─── XP progress bar with amber gradient ──────────────────
const XPBar = ({ pct, height = 10 }) => (
  <div style={{
    width: '100%', height, borderRadius: height/2,
    background: 'rgba(139, 92, 246, 0.15)',
    overflow: 'hidden', position: 'relative',
    border: '1px solid rgba(139, 92, 246, 0.2)',
  }}>
    <div style={{
      width: `${pct}%`, height: '100%',
      background: 'linear-gradient(90deg, #F59E0B 0%, #F5A623 50%, #FBBF24 100%)',
      borderRadius: height/2,
      boxShadow: '0 0 10px rgba(245, 166, 35, 0.6)',
      position: 'relative',
    }}>
      <div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent)',
        backgroundSize: '200% 100%',
        animation: 'shimmer 2.5s linear infinite',
      }}/>
    </div>
  </div>
);

// ─── Tab bar ──────────────────────────────────────────────
const TabBar = ({ active, onChange }) => {
  const tabs = [
    { id: 'home', label: 'Home', icon: 'home' },
    { id: 'quests', label: 'Quests', icon: 'scroll' },
    { id: 'streak', label: 'Streak', icon: 'flame' },
    { id: 'profile', label: 'Profile', icon: 'crown' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 24, left: 16, right: 16,
      zIndex: 30,
      pointerEvents: 'none',
    }}>
      <div style={{
        position: 'relative',
        height: 66, borderRadius: 33,
        display: 'flex', alignItems: 'center', justifyContent: 'space-around',
        padding: '0 10px',
        pointerEvents: 'auto',
        // translucent glass
        background: 'linear-gradient(180deg, rgba(26,15,43,0.72) 0%, rgba(10,6,18,0.78) 100%)',
        backdropFilter: 'blur(24px) saturate(180%)',
        WebkitBackdropFilter: 'blur(24px) saturate(180%)',
        border: '1px solid rgba(139, 92, 246, 0.3)',
        boxShadow:
          '0 12px 40px rgba(0,0,0,0.55), ' +
          '0 0 0 1px rgba(255,255,255,0.04), ' +
          '0 0 30px -8px rgba(139,92,246,0.4), ' +
          'inset 0 1px 0 rgba(255,255,255,0.08), ' +
          'inset 0 -1px 0 rgba(0,0,0,0.4)',
        overflow: 'visible',
      }}>
        {/* top shine highlight */}
        <div style={{
          position: 'absolute', top: 0, left: '10%', right: '10%', height: 1,
          background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.25), transparent)',
          borderRadius: 1, pointerEvents: 'none',
        }}/>
        {/* inner violet ambient */}
        <div style={{
          position: 'absolute', inset: 0, borderRadius: 33,
          background: 'radial-gradient(ellipse at 50% 150%, rgba(139,92,246,0.2), transparent 60%)',
          pointerEvents: 'none',
        }}/>

        {tabs.map(t => {
          const isActive = t.id === active;
          return (
            <button key={t.id} onClick={() => onChange(t.id)} style={{
              position: 'relative', zIndex: 2,
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
              gap: 3,
              width: 66, height: 54, borderRadius: 27,
              background: isActive
                ? 'linear-gradient(180deg, rgba(245,166,35,0.22) 0%, rgba(245,166,35,0.08) 100%)'
                : 'transparent',
              border: isActive ? '1px solid rgba(245,166,35,0.45)' : '1px solid transparent',
              boxShadow: isActive
                ? '0 0 18px -2px rgba(245,166,35,0.55), inset 0 1px 0 rgba(255,255,255,0.12)'
                : 'none',
              transition: 'all 0.25s cubic-bezier(0.2, 0.9, 0.3, 1)',
            }}>
              <div style={{
                filter: isActive ? 'drop-shadow(0 0 6px rgba(245,166,35,0.8))' : 'none',
                transform: isActive ? 'translateY(-1px)' : 'none',
                transition: 'transform 0.2s',
              }}>
                <Icon name={t.icon} size={21} color={isActive ? PALETTE.amber : PALETTE.muted}/>
              </div>
              <span style={{
                fontSize: 9.5, fontWeight: 700, letterSpacing: 0.9,
                textTransform: 'uppercase',
                color: isActive ? PALETTE.amber : PALETTE.muted,
                textShadow: isActive ? '0 0 8px rgba(245,166,35,0.4)' : 'none',
              }}>{t.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
};

// ─── Phone shell (pure black bezel, dark app bg) ─────────
const Phone = ({ children, tab, onTab, showTabs = true }) => (
  <div style={{
    width: 402, height: 874,
    borderRadius: 54, overflow: 'hidden', position: 'relative',
    background: PALETTE.bg,
    boxShadow: '0 40px 80px rgba(0,0,0,0.6), 0 0 0 12px #0a0a0f, 0 0 0 13px rgba(139,92,246,0.15), 0 0 60px rgba(139,92,246,0.15)',
    color: PALETTE.text,
  }}>
    {/* dynamic island */}
    <div style={{
      position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
      width: 126, height: 37, borderRadius: 24, background: '#000', zIndex: 50,
    }}/>
    <StatusBar />
    {/* background ambient glow */}
    <div style={{
      position: 'absolute', inset: 0,
      background: 'radial-gradient(circle at 50% 0%, rgba(139,92,246,0.18), transparent 50%), radial-gradient(circle at 100% 100%, rgba(245,166,35,0.06), transparent 50%)',
      pointerEvents: 'none', zIndex: 1,
    }}/>
    <div style={{ position: 'absolute', inset: 0, zIndex: 2 }}>
      {children}
    </div>
    {showTabs && <TabBar active={tab} onChange={onTab} />}
    {/* home indicator */}
    <div style={{
      position: 'absolute', bottom: 8, left: '50%', transform: 'translateX(-50%)',
      width: 139, height: 5, borderRadius: 3, background: 'rgba(255,255,255,0.35)', zIndex: 60,
    }}/>
  </div>
);

// ─── Sample data ──────────────────────────────────────────
const USER = {
  name: 'Alex',
  class: 'MASS BUILDER',
  classKey: 'mass',
  level: 12,
  xp: 14250,
  xpToNext: 1000,
  xpIntoLevel: 250,
  totalWorkouts: 89,
  streak: 47,
  streakMonth: 14,
  freezes: 2,
  weight: 79.9,
  weightDelta: -0.2,
  weightTarget: 74.8,
  age: 25,
  height: 175,
  bmi: 24.5,
  email: 'alex@leveluprl.app',
  nextWorkout: { title: 'Push Day', duration: '60–75 min', exercises: 5, category: 'Upper Body' },
};

const MUSCLES = [
  { name: 'Chest', tier: 'Gold II', xp: 2840, color: '#F5A623', pct: 72 },
  { name: 'Back', tier: 'Silver III', xp: 1420, color: '#8B5CF6', pct: 64 },
  { name: 'Shoulders', tier: 'Gold I', xp: 1620, color: '#F5A623', pct: 58 },
  { name: 'Biceps', tier: 'Silver II', xp: 1140, color: '#8B5CF6', pct: 48 },
  { name: 'Triceps', tier: 'Silver III', xp: 1380, color: '#8B5CF6', pct: 55 },
  { name: 'Core', tier: 'Bronze III', xp: 420, color: '#CD7F32', pct: 42 },
  { name: 'Quadriceps', tier: 'Silver I', xp: 780, color: '#B8B8C8', pct: 50 },
  { name: 'Hamstrings', tier: 'Silver II', xp: 1090, color: '#B8B8C8', pct: 46 },
  { name: 'Glutes', tier: 'Silver I', xp: 620, color: '#B8B8C8', pct: 40 },
  { name: 'Calves', tier: 'Bronze II', xp: 280, color: '#CD7F32', pct: 35 },
];

const EXERCISES = [
  { name: 'Bench Press', muscles: 'chest, triceps, shoulders', sets: [
    { reps: 10, weight: 80 }, { reps: 10, weight: 80 }, { reps: 8, weight: 85 }, { reps: 8, weight: 85 },
  ]},
  { name: 'Incline Dumbbell Press', muscles: 'chest, shoulders, +2 more', sets: [
    { reps: 10, weight: 28 }, { reps: 10, weight: 28 }, { reps: 10, weight: 28 }, { reps: 8, weight: 30 },
  ]},
  { name: 'Shoulder Press', muscles: 'shoulders, triceps', sets: [
    { reps: 10, weight: 22 }, { reps: 10, weight: 22 }, { reps: 8, weight: 24 },
  ]},
  { name: 'Lateral Raises', muscles: 'shoulders', sets: [
    { reps: 15, weight: 10 }, { reps: 15, weight: 10 }, { reps: 12, weight: 12 },
  ]},
  { name: 'Tricep Pushdown', muscles: 'triceps', sets: [
    { reps: 15, weight: 20 }, { reps: 12, weight: 22 }, { reps: 12, weight: 22 },
  ]},
];

Object.assign(window, {
  PALETTE, Icon, StatusBar, Card, Pill, XPBar, TabBar, Phone,
  USER, MUSCLES, EXERCISES,
});
