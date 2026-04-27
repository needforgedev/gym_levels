// Outro: Challenge System intro + Paywall comparison table

const ChallengeIntroScreen = ({ onContinue, onBack }) => (
  <div style={{ position: 'absolute', inset: 0, background: '#0A0612', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
    <div style={{
      position: 'absolute', inset: 0,
      background: 'radial-gradient(ellipse at 50% 20%, rgba(245,166,35,0.25), transparent 55%), radial-gradient(ellipse at 50% 80%, rgba(139,92,246,0.2), transparent 55%)',
      pointerEvents: 'none',
    }}/>

    <div style={{ padding: '60px 20px 0', position: 'relative', zIndex: 2 }}>
      <button onClick={onBack} style={{ width: 34, height: 34, borderRadius: 17, background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Icon name="chevron-left" size={18} color="#ECE9F5"/>
      </button>
    </div>

    <div style={{ flex: 1, position: 'relative', zIndex: 2, padding: '20px 28px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      {/* Trophy visual */}
      <div style={{ position: 'relative', width: 160, height: 160, marginBottom: 20, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: 'radial-gradient(circle, rgba(245,166,35,0.5), transparent 65%)', filter: 'blur(15px)' }}/>
        <div style={{
          width: 110, height: 110, borderRadius: '50%',
          background: 'linear-gradient(135deg, #F5A623, #FBBF24)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 0 40px rgba(245,166,35,0.6)',
          position: 'relative', zIndex: 2,
        }}>
          <Icon name="trophy" size={54} color="#0A0612" strokeWidth={2.5}/>
        </div>
      </div>

      <div className="display-font" style={{ fontSize: 42, textAlign: 'center', lineHeight: 0.95, color: '#ECE9F5', marginBottom: 6 }}>
        BRING ON THE<br/><span style={{ color: '#F5A623', textShadow: '0 0 20px rgba(245,166,35,0.6)' }}>CHALLENGES</span>
      </div>
      <div style={{ fontSize: 13, color: '#8A809B', textAlign: 'center', lineHeight: 1.5, marginBottom: 24, padding: '0 8px' }}>
        Three quest tiers. Infinite motivation.
      </div>

      {/* Quest tier cards */}
      <div style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {[
          { label: 'DAILY', xp: '40–100 XP', desc: 'Fresh every 24hrs', color: '#F5A623' },
          { label: 'WEEKLY', xp: '200–500 XP', desc: 'Resets Monday', color: '#A78BFA' },
          { label: 'BOSS', xp: '2000+ XP', desc: 'Multi-week hunt', color: '#FF6B35', premium: true },
        ].map(q => (
          <div key={q.label} style={{
            padding: '12px 14px', borderRadius: 12,
            background: 'rgba(18,10,31,0.7)',
            border: `1px solid ${q.color}55`,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ width: 40, height: 40, borderRadius: 10, background: `${q.color}22`, border: `1px solid ${q.color}66`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name={q.label === 'BOSS' ? 'shield' : q.label === 'WEEKLY' ? 'cal' : 'target'} size={20} color={q.color}/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 800, letterSpacing: 1.2, color: q.color, display: 'flex', gap: 6, alignItems: 'center' }}>
                {q.label}
                {q.premium && <span style={{ fontSize: 8, padding: '2px 5px', borderRadius: 4, background: 'rgba(245,166,35,0.2)', border: '1px solid rgba(245,166,35,0.4)', color: '#F5A623', letterSpacing: 1 }}>PRO</span>}
              </div>
              <div style={{ fontSize: 11, color: '#8A809B', marginTop: 1 }}>{q.desc}</div>
            </div>
            <div className="mono" style={{ fontSize: 12, color: q.color, fontWeight: 700 }}>{q.xp}</div>
          </div>
        ))}
      </div>
    </div>

    <div style={{ padding: '20px 24px 100px', position: 'relative', zIndex: 2 }}>
      <button onClick={onContinue} style={{
        width: '100%', height: 54, borderRadius: 27,
        background: 'linear-gradient(135deg, #F5A623, #FBBF24)',
        color: '#0A0612', fontWeight: 800, fontSize: 13, letterSpacing: 2,
        textTransform: 'uppercase',
        boxShadow: '0 0 24px rgba(245,166,35,0.5)',
      }}>Bring It On →</button>
    </div>
  </div>
);

// ─── Paywall — comparison table ─────────────────────────
const PaywallScreen = ({ onContinue, onSkip, onBack }) => {
  const [selectedTier, setSelectedTier] = React.useState('best');

  const features = [
    { label: 'Daily Quests', free: true, weekly: true, best: true, annual: true },
    { label: 'Muscle Ranks (E → S)', free: true, weekly: true, best: true, annual: true },
    { label: 'Workouts / week', free: '3', weekly: '∞', best: '∞', annual: '∞' },
    { label: 'Weekly Quests', free: false, weekly: true, best: true, annual: true },
    { label: 'Boss Challenges', free: false, weekly: true, best: true, annual: true },
    { label: 'Advanced Analytics', free: false, weekly: true, best: true, annual: true },
    { label: 'AI Form Check', free: false, weekly: false, best: true, annual: true },
    { label: 'Cosmetic Skins', free: false, weekly: false, best: true, annual: true },
    { label: 'Data Export', free: false, weekly: false, best: true, annual: true },
  ];

  const tiers = [
    { key: 'weekly', label: 'WEEKLY', price: '₹1,050', period: '/ wk', color: '#8A809B' },
    { key: 'best', label: 'BEST VALUE', price: '₹3,200', period: '/ 3 mo', color: '#F5A623', badge: 'SAVE 64%' },
    { key: 'annual', label: 'ANNUAL', price: '₹8,800', period: '/ yr', color: '#A78BFA', badge: '7d TRIAL' },
  ];

  return (
    <div style={{ position: 'absolute', inset: 0, background: '#0A0612', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(ellipse at 50% 10%, rgba(245,166,35,0.2), transparent 55%)',
        pointerEvents: 'none',
      }}/>

      {/* Header */}
      <div style={{ padding: '60px 20px 16px', position: 'relative', zIndex: 2, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onBack} style={{ width: 34, height: 34, borderRadius: 17, background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="chevron-left" size={18} color="#ECE9F5"/>
        </button>
        <button onClick={onSkip} style={{ fontSize: 12, color: '#5A5169', letterSpacing: 0.5 }}>Maybe later</button>
      </div>

      {/* Scrollable */}
      <div className="scroll" style={{ flex: 1, overflow: 'auto', position: 'relative', zIndex: 2 }}>
        {/* Title */}
        <div style={{ padding: '0 24px 20px' }}>
          <div className="display-font" style={{ fontSize: 34, lineHeight: 1.05, color: '#ECE9F5' }}>
            TURN YOUR WORKOUTS
          </div>
          <div className="display-font" style={{ fontSize: 34, lineHeight: 1.05 }}>
            <span style={{ background: 'linear-gradient(135deg, #F5A623, #FBBF24)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>INTO A GAME</span>
          </div>
          <div style={{ fontSize: 13, color: '#8A809B', marginTop: 10, lineHeight: 1.5 }}>
            Unlock boss challenges, advanced analytics, and the full System.
          </div>
        </div>

        {/* Tier pills */}
        <div style={{ padding: '0 16px', display: 'flex', gap: 8, marginBottom: 16 }}>
          {tiers.map(t => {
            const sel = selectedTier === t.key;
            return (
              <button key={t.key} onClick={() => setSelectedTier(t.key)} style={{
                flex: 1, padding: '10px 4px', borderRadius: 12,
                background: sel ? `linear-gradient(180deg, ${t.color}33, ${t.color}11)` : 'rgba(18,10,31,0.7)',
                border: `1.5px solid ${sel ? t.color : 'rgba(139,92,246,0.18)'}`,
                boxShadow: sel ? `0 0 16px -4px ${t.color}88` : 'none',
                position: 'relative', textAlign: 'center',
                transition: 'all 0.2s',
              }}>
                {t.badge && (
                  <div style={{
                    position: 'absolute', top: -8, left: '50%', transform: 'translateX(-50%)',
                    padding: '2px 6px', borderRadius: 4,
                    background: t.color, color: '#0A0612',
                    fontSize: 8, fontWeight: 800, letterSpacing: 1, whiteSpace: 'nowrap',
                  }}>{t.badge}</div>
                )}
                <div className="mono" style={{ fontSize: 9, letterSpacing: 1.5, color: sel ? t.color : '#8A809B', fontWeight: 700, marginBottom: 4 }}>{t.label}</div>
                <div className="display-font" style={{ fontSize: 20, color: '#ECE9F5', lineHeight: 1 }}>{t.price}</div>
                <div style={{ fontSize: 10, color: '#8A809B', marginTop: 2 }}>{t.period}</div>
              </button>
            );
          })}
        </div>

        {/* Comparison table */}
        <div style={{ padding: '8px 16px 16px' }}>
          <div style={{
            background: 'rgba(18,10,31,0.85)',
            border: '1px solid rgba(139,92,246,0.2)',
            borderRadius: 14, overflow: 'hidden',
          }}>
            {/* Header row */}
            <div style={{
              display: 'grid', gridTemplateColumns: '2fr 1fr 1.1fr',
              padding: '10px 12px', gap: 4,
              background: 'rgba(139,92,246,0.1)',
              borderBottom: '1px solid rgba(139,92,246,0.2)',
            }}>
              <div style={{ fontSize: 10, color: '#8A809B', letterSpacing: 1, fontWeight: 700 }}>FEATURE</div>
              <div style={{ fontSize: 10, color: '#8A809B', letterSpacing: 1, fontWeight: 700, textAlign: 'center' }}>FREE</div>
              <div style={{ fontSize: 10, color: '#F5A623', letterSpacing: 1, fontWeight: 800, textAlign: 'center' }}>PRO</div>
            </div>
            {features.map((f, i) => (
              <div key={f.label} style={{
                display: 'grid', gridTemplateColumns: '2fr 1fr 1.1fr',
                padding: '11px 12px', gap: 4, alignItems: 'center',
                borderBottom: i < features.length - 1 ? '1px solid rgba(139,92,246,0.08)' : 'none',
              }}>
                <div style={{ fontSize: 12.5, color: '#ECE9F5' }}>{f.label}</div>
                <div style={{ textAlign: 'center' }}>
                  {typeof f.free === 'boolean'
                    ? (f.free
                        ? <Icon name="check" size={16} color="#A78BFA"/>
                        : <span style={{ color: '#5A5169', fontSize: 14 }}>—</span>)
                    : <span className="mono" style={{ fontSize: 11, color: '#8A809B', fontWeight: 700 }}>{f.free}</span>}
                </div>
                <div style={{ textAlign: 'center' }}>
                  {typeof f.best === 'boolean'
                    ? <Icon name="check" size={16} color="#F5A623"/>
                    : <span className="mono" style={{ fontSize: 11, color: '#F5A623', fontWeight: 700 }}>{f.best}</span>}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ padding: '0 24px', fontSize: 10, color: '#5A5169', textAlign: 'center', lineHeight: 1.5, marginBottom: 20 }}>
          Auto-renews. Cancel anytime from settings.
        </div>
      </div>

      {/* CTA */}
      <div style={{ padding: '12px 24px 100px', position: 'relative', zIndex: 2 }}>
        <button onClick={onContinue} style={{
          width: '100%', height: 56, borderRadius: 28,
          background: 'linear-gradient(135deg, #F5A623, #FBBF24)',
          color: '#0A0612', fontWeight: 800, fontSize: 13, letterSpacing: 2,
          textTransform: 'uppercase',
          boxShadow: '0 0 24px rgba(245,166,35,0.5)',
        }}>Activate Pro</button>
      </div>
    </div>
  );
};

Object.assign(window, { ChallengeIntroScreen, PaywallScreen });
