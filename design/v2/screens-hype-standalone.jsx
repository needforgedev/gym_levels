// Two intro hype slides — swipeable carousel

const TIER_CHIPS = [
  { tier: 'BRONZE', color: '#CD7F32' },
  { tier: 'SILVER', color: '#B8B8C8' },
  { tier: 'GOLD', color: '#F5A623' },
  { tier: 'PLATINUM', color: '#6FC9FF' },
  { tier: 'DIAMOND', color: '#19E3E3' },
  { tier: 'MASTER', color: '#C4B5FD' },
];

const HypeSlides = ({ onContinue }) => {
  const [idx, setIdx] = React.useState(0);

  const next = () => {
    if (idx < 1) setIdx(idx + 1);
    else onContinue();
  };

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: '#0A0612',
      display: 'flex', flexDirection: 'column',
      overflow: 'hidden',
    }}>
      {/* ambient bg glows */}
      <div style={{
        position: 'absolute', inset: 0,
        background: idx === 0
          ? 'radial-gradient(circle at 50% 30%, rgba(139,92,246,0.25), transparent 60%)'
          : 'radial-gradient(circle at 50% 30%, rgba(245,166,35,0.22), transparent 60%), radial-gradient(circle at 50% 70%, rgba(139,92,246,0.18), transparent 60%)',
        pointerEvents: 'none',
      }}/>

      {/* skip */}
      <div style={{ padding: '70px 24px 0', display: 'flex', justifyContent: 'flex-end', position: 'relative', zIndex: 2 }}>
        <button onClick={onContinue} style={{ fontSize: 13, color: '#8A809B', letterSpacing: 0.5 }}>Skip</button>
      </div>

      {/* content */}
      <div style={{ flex: 1, position: 'relative', zIndex: 2, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '24px 28px 0' }}>
        {idx === 0 ? <Slide1 /> : <Slide2 />}
      </div>

      {/* dots + CTA */}
      <div style={{ padding: '0 28px 100px', position: 'relative', zIndex: 2 }}>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginBottom: 20 }}>
          {[0, 1].map(i => (
            <div key={i} style={{
              width: i === idx ? 24 : 6, height: 6, borderRadius: 3,
              background: i === idx ? '#F5A623' : 'rgba(139,92,246,0.3)',
              transition: 'width 0.3s',
            }}/>
          ))}
        </div>
        <button onClick={next} style={{
          width: '100%', height: 56, borderRadius: 28,
          background: 'linear-gradient(135deg, #F5A623, #FBBF24)',
          color: '#0A0612', fontWeight: 800, fontSize: 14, letterSpacing: 2,
          textTransform: 'uppercase',
          boxShadow: '0 0 24px rgba(245,166,35,0.45)',
        }}>{idx === 0 ? 'Continue' : 'Level Up IRL →'}</button>
      </div>
    </div>
  );
};

const Slide1 = () => (
  <>
    {/* Hero art */}
    <div style={{ position: 'relative', width: 230, height: 270, marginBottom: 20, animation: 'fadeInUp 0.5s' }}>
      <div style={{ position: 'absolute', inset: -16, borderRadius: 20, background: 'radial-gradient(ellipse, rgba(139,92,246,0.4), transparent 65%)', filter: 'blur(20px)' }}/>
      <img src="assets/hero-bust.png" alt="" style={{
        position: 'relative', width: '100%', height: '100%', objectFit: 'cover',
        borderRadius: 20,
        border: '1px solid rgba(139,92,246,0.4)',
        boxShadow: '0 20px 50px rgba(0,0,0,0.6), 0 0 40px rgba(139,92,246,0.3)',
      }}/>
      {/* corner decoration */}
      <div style={{ position: 'absolute', top: -8, right: -8, width: 24, height: 24 }}>
        <Icon name="sparkle" size={24} color="#F5A623"/>
      </div>
    </div>

    <div className="display-font" style={{ fontSize: 44, lineHeight: 1.05, textAlign: 'center', color: '#ECE9F5', marginBottom: 14 }}>
      TRACK EVERY <span style={{ color: '#F5A623', textShadow: '0 0 20px rgba(245,166,35,0.6)' }}>GAIN</span>
    </div>
    <div style={{ fontSize: 14, color: '#8A809B', textAlign: 'center', lineHeight: 1.5, marginBottom: 20, padding: '0 10px' }}>
      Every muscle gets a rank. Every rep moves you forward. Your body is the game.
    </div>

    {/* Tier chips row */}
    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', justifyContent: 'center', marginTop: 8 }}>
      {TIER_CHIPS.map(t => (
        <span key={t.tier} style={{
          padding: '6px 12px', borderRadius: 6,
          border: `1px solid ${t.color}55`,
          background: `${t.color}18`,
          color: t.color, fontSize: 10, fontWeight: 700, letterSpacing: 1.5,
        }}>{t.tier}</span>
      ))}
    </div>
  </>
);

const Slide2 = () => (
  <>
    {/* XP burst art */}
    <div style={{ position: 'relative', width: 260, height: 240, marginBottom: 12, animation: 'fadeInUp 0.5s', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      {/* Glowing burst */}
      <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: 'radial-gradient(circle, rgba(245,166,35,0.5), transparent 65%)', filter: 'blur(10px)' }}/>
      {[0, 45, 90, 135].map(angle => (
        <div key={angle} style={{
          position: 'absolute', top: '50%', left: '50%',
          width: 2, height: 90,
          background: 'linear-gradient(180deg, #F5A623, transparent)',
          transform: `translate(-50%, -50%) rotate(${angle}deg)`,
          transformOrigin: 'center',
          opacity: 0.5,
        }}/>
      ))}
      {/* Central XP badge */}
      <div style={{
        position: 'relative', width: 120, height: 120, borderRadius: '50%',
        background: 'conic-gradient(from 0deg, #F5A623, #FBBF24, #F5A623)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 0 40px rgba(245,166,35,0.6), inset 0 0 0 4px rgba(0,0,0,0.3)',
      }}>
        <div style={{
          width: 100, height: 100, borderRadius: '50%',
          background: '#0A0612', display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexDirection: 'column',
        }}>
          <span className="display-font" style={{ fontSize: 36, color: '#F5A623', lineHeight: 1 }}>+XP</span>
          <span style={{ fontSize: 9, color: '#C4B5FD', letterSpacing: 2, fontWeight: 700 }}>EARNED</span>
        </div>
      </div>
    </div>

    <div className="display-font" style={{ fontSize: 44, lineHeight: 1.05, textAlign: 'center', color: '#ECE9F5', marginBottom: 14 }}>
      LEVEL UP <span style={{ color: '#A78BFA', textShadow: '0 0 20px rgba(139,92,246,0.7)' }}>IRL</span>
    </div>
    <div style={{ fontSize: 14, color: '#8A809B', textAlign: 'center', lineHeight: 1.5, marginBottom: 16, padding: '0 10px' }}>
      Real reps. Real XP. Real gains. Every session counts towards your next rank.
    </div>

    {/* Attribute rows */}
    <div style={{ width: '100%', maxWidth: 300, display: 'flex', flexDirection: 'column', gap: 8 }}>
      {[
        { label: 'STRENGTH', value: '+42 XP', color: '#F5A623' },
        { label: 'ENDURANCE', value: '+28 XP', color: '#8B5CF6' },
        { label: 'POWER', value: '+56 XP', color: '#19E3E3' },
      ].map(a => (
        <div key={a.label} style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '10px 14px', borderRadius: 10,
          background: 'rgba(139,92,246,0.08)',
          border: `1px solid ${a.color}44`,
        }}>
          <span style={{ fontSize: 11, letterSpacing: 1.5, fontWeight: 700, color: '#ECE9F5' }}>{a.label}</span>
          <span className="mono" style={{ fontSize: 13, color: a.color, fontWeight: 700 }}>{a.value}</span>
        </div>
      ))}
    </div>
  </>
);

window.HypeSlides = HypeSlides;
