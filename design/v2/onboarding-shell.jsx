// Onboarding quiz — shared shell, 19 screens, fully interactive

const { useState: useStateOB, useEffect: useEffectOB } = React;

// ─── Shell: progress bar + System header + back button ───
const OBShell = ({ step, total, onBack, children, accent = '#8B5CF6' }) => {
  const pct = (step / total) * 100;
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: '#0A0612',
      display: 'flex', flexDirection: 'column',
      overflow: 'hidden',
    }}>
      {/* ambient bg */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(ellipse at 50% -10%, ${accent}33, transparent 55%)`,
        pointerEvents: 'none',
      }}/>

      {/* Top: progress + back */}
      <div style={{ padding: '60px 20px 0', position: 'relative', zIndex: 2 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
          <button onClick={onBack} style={{
            width: 34, height: 34, borderRadius: 17,
            background: 'rgba(139,92,246,0.12)', border: '1px solid rgba(139,92,246,0.25)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <Icon name="chevron-left" size={18} color="#ECE9F5"/>
          </button>
          <div style={{ flex: 1, height: 6, borderRadius: 3, background: 'rgba(139,92,246,0.15)', overflow: 'hidden', border: '1px solid rgba(139,92,246,0.2)' }}>
            <div style={{
              width: `${pct}%`, height: '100%',
              background: `linear-gradient(90deg, ${accent}, #F5A623)`,
              borderRadius: 3,
              boxShadow: `0 0 10px ${accent}88`,
              transition: 'width 0.4s cubic-bezier(0.2, 0.9, 0.3, 1)',
            }}/>
          </div>
          <span className="mono" style={{ fontSize: 10, color: '#8A809B', fontWeight: 700 }}>{Math.round(pct)}%</span>
        </div>
      </div>

      <div style={{ flex: 1, position: 'relative', zIndex: 2, overflow: 'auto' }} className="scroll">
        {children}
      </div>
    </div>
  );
};

// Section title header (System voice)
const OBHeader = ({ subtitle, title, accent = '#8B5CF6' }) => (
  <div style={{ padding: '6px 28px 20px', animation: 'fadeInUp 0.4s' }}>
    <div className="mono" style={{ fontSize: 10, letterSpacing: 2, color: accent, fontWeight: 700, textTransform: 'uppercase', marginBottom: 8, fontStyle: 'italic' }}>
      [SYS] {subtitle}
    </div>
    <div className="display-font" style={{ fontSize: 28, color: '#ECE9F5', lineHeight: 1.05, letterSpacing: 0.5 }}>
      {title}
    </div>
  </div>
);

// CTA bar
const OBContinue = ({ onContinue, disabled, label = 'CONTINUE' }) => (
  <div style={{ padding: '16px 24px 100px' }}>
    <button disabled={disabled} onClick={onContinue} style={{
      width: '100%', height: 54, borderRadius: 27,
      background: disabled ? 'rgba(139,92,246,0.2)' : 'linear-gradient(135deg, #F5A623, #FBBF24)',
      color: disabled ? '#5A5169' : '#0A0612',
      fontWeight: 800, fontSize: 13, letterSpacing: 2,
      textTransform: 'uppercase',
      boxShadow: disabled ? 'none' : '0 0 24px rgba(245,166,35,0.5)',
      cursor: disabled ? 'not-allowed' : 'pointer',
      transition: 'all 0.2s',
    }}>{label} <Icon name="arrow-right" size={14} color={disabled ? '#5A5169' : '#0A0612'}/></button>
  </div>
);

// ─── Custom Slider component ────────────────────────────
const OBSlider = ({ min, max, value, onChange, unit, step = 1 }) => {
  const pct = ((value - min) / (max - min)) * 100;
  return (
    <div style={{ padding: '20px 0' }}>
      <div style={{ textAlign: 'center', marginBottom: 30 }}>
        <span className="display-font" style={{ fontSize: 72, color: '#F5A623', lineHeight: 1, textShadow: '0 0 30px rgba(245,166,35,0.5)' }}>{value}</span>
        <span style={{ fontSize: 18, color: '#8A809B', fontWeight: 600, marginLeft: 6 }}>{unit}</span>
      </div>
      <div style={{ position: 'relative', padding: '0 8px' }}>
        <div style={{
          position: 'relative', height: 8, borderRadius: 4,
          background: 'rgba(139,92,246,0.15)', border: '1px solid rgba(139,92,246,0.25)',
        }}>
          <div style={{
            width: `${pct}%`, height: '100%', borderRadius: 4,
            background: 'linear-gradient(90deg, #8B5CF6, #F5A623)',
            boxShadow: '0 0 12px rgba(245,166,35,0.5)',
          }}/>
          <div style={{
            position: 'absolute', left: `calc(${pct}% - 12px)`, top: -8,
            width: 24, height: 24, borderRadius: 12,
            background: '#F5A623',
            border: '3px solid #0A0612',
            boxShadow: '0 0 18px rgba(245,166,35,0.7)',
            pointerEvents: 'none',
          }}/>
        </div>
        <input
          type="range" min={min} max={max} step={step} value={value}
          onChange={e => onChange(Number(e.target.value))}
          style={{
            position: 'absolute', inset: 0, width: '100%', height: '100%',
            opacity: 0, cursor: 'pointer',
          }}
        />
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 11, color: '#5A5169', fontWeight: 600 }}>
          <span>{min}</span>
          <span>{max}</span>
        </div>
      </div>
    </div>
  );
};

// Radio option card (for single-select card-style options)
const OBRadioCard = ({ selected, onClick, children, icon }) => (
  <button onClick={onClick} style={{
    width: '100%', padding: '16px 18px', borderRadius: 14,
    textAlign: 'left', display: 'flex', alignItems: 'center', gap: 14,
    background: selected ? 'linear-gradient(135deg, rgba(245,166,35,0.16), rgba(139,92,246,0.12))' : 'rgba(18,10,31,0.7)',
    border: selected ? '1px solid rgba(245,166,35,0.55)' : '1px solid rgba(139,92,246,0.18)',
    boxShadow: selected ? '0 0 20px -4px rgba(245,166,35,0.45)' : 'none',
    transition: 'all 0.2s',
    marginBottom: 8,
  }}>
    {icon && (
      <div style={{
        width: 40, height: 40, borderRadius: 10,
        background: selected ? 'rgba(245,166,35,0.2)' : 'rgba(139,92,246,0.12)',
        border: `1px solid ${selected ? 'rgba(245,166,35,0.4)' : 'rgba(139,92,246,0.25)'}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
      }}><Icon name={icon} size={18} color={selected ? '#F5A623' : '#A78BFA'}/></div>
    )}
    <div style={{ flex: 1 }}>{children}</div>
    <div style={{
      width: 22, height: 22, borderRadius: 11,
      border: `2px solid ${selected ? '#F5A623' : 'rgba(139,92,246,0.4)'}`,
      background: selected ? '#F5A623' : 'transparent',
      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
    }}>
      {selected && <div style={{ width: 8, height: 8, borderRadius: 4, background: '#0A0612' }}/>}
    </div>
  </button>
);

// Chip (for multi-select pills)
const OBChip = ({ selected, onClick, children, disabled }) => (
  <button disabled={disabled} onClick={onClick} style={{
    padding: '10px 16px', borderRadius: 22,
    background: selected ? 'rgba(245,166,35,0.18)' : 'rgba(139,92,246,0.08)',
    border: `1px solid ${selected ? 'rgba(245,166,35,0.55)' : 'rgba(139,92,246,0.25)'}`,
    color: selected ? '#F5A623' : disabled ? '#5A5169' : '#ECE9F5',
    fontSize: 13, fontWeight: 600,
    boxShadow: selected ? '0 0 14px -4px rgba(245,166,35,0.5)' : 'none',
    opacity: disabled ? 0.5 : 1,
    transition: 'all 0.15s',
  }}>{children}</button>
);

// Calibrating loader interstitial
const CalibratingLoader = ({ onDone }) => {
  const [pct, setPct] = useStateOB(0);
  useEffectOB(() => {
    const interval = setInterval(() => {
      setPct(p => {
        const next = p + 2.5;
        if (next >= 100) { clearInterval(interval); setTimeout(onDone, 250); return 100; }
        return next;
      });
    }, 25);
    return () => clearInterval(interval);
  }, []);
  return (
    <div style={{ position: 'absolute', inset: 0, background: '#0A0612', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 24 }}>
      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(circle at 50% 50%, rgba(139,92,246,0.2), transparent 60%)',
        pointerEvents: 'none',
      }}/>
      <div style={{ position: 'relative', zIndex: 2, textAlign: 'center' }}>
        <div className="mono" style={{ fontSize: 11, letterSpacing: 3, color: '#F5A623', marginBottom: 24, fontStyle: 'italic' }}>[SYS] CALIBRATING PLAYER DATA</div>
        <div style={{ width: 220, height: 6, borderRadius: 3, background: 'rgba(139,92,246,0.15)', overflow: 'hidden', border: '1px solid rgba(139,92,246,0.3)', position: 'relative' }}>
          <div style={{ width: `${pct}%`, height: '100%', background: 'linear-gradient(90deg, #8B5CF6, #F5A623)', borderRadius: 3, boxShadow: '0 0 10px rgba(245,166,35,0.6)', transition: 'width 0.1s linear' }}/>
          <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent)', backgroundSize: '200% 100%', animation: 'shimmer 1.5s linear infinite' }}/>
        </div>
        <div className="mono" style={{ fontSize: 10, letterSpacing: 2, color: '#8A809B', marginTop: 14 }}>{Math.round(pct).toString().padStart(3, '0')}%</div>
      </div>
    </div>
  );
};

Object.assign(window, { OBShell, OBHeader, OBContinue, OBSlider, OBRadioCard, OBChip, CalibratingLoader });
