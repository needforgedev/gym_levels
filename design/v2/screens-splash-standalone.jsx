// Splash / Launch screen

const SplashScreen = ({ onContinue }) => {
  const [ready, setReady] = React.useState(false);
  React.useEffect(() => {
    const t = setTimeout(() => setReady(true), 1800);
    return () => clearTimeout(t);
  }, []);
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'radial-gradient(ellipse at 50% 30%, rgba(139,92,246,0.25), transparent 60%), #0A0612',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      overflow: 'hidden',
    }}>
      {/* starry particles */}
      {[...Array(20)].map((_, i) => {
        const size = 2 + Math.random() * 3;
        const left = Math.random() * 100;
        const top = Math.random() * 100;
        const delay = Math.random() * 2;
        return (
          <div key={i} style={{
            position: 'absolute', left: `${left}%`, top: `${top}%`,
            width: size, height: size, borderRadius: '50%',
            background: i % 3 === 0 ? '#F5A623' : '#C4B5FD',
            boxShadow: `0 0 ${size * 3}px currentColor`,
            color: i % 3 === 0 ? '#F5A623' : '#C4B5FD',
            opacity: 0.6,
            animation: `sparkle ${2 + Math.random() * 2}s ease-in-out infinite`,
            animationDelay: `${delay}s`,
          }}/>
        );
      })}

      {/* Hero art */}
      <div style={{
        position: 'relative',
        width: 260, height: 260, marginBottom: 28,
        animation: 'fadeInUp 0.8s ease-out',
      }}>
        <div style={{
          position: 'absolute', inset: -20, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(139,92,246,0.45), transparent 65%)',
          filter: 'blur(20px)',
        }}/>
        <img src="assets/hero-bust.png" alt="" style={{
          position: 'relative', width: '100%', height: '100%', objectFit: 'cover',
          borderRadius: '50%',
          border: '2px solid rgba(139,92,246,0.5)',
          boxShadow: '0 0 40px rgba(139,92,246,0.5), inset 0 0 30px rgba(0,0,0,0.3)',
        }}/>
      </div>

      {/* Title */}
      <div style={{ textAlign: 'center', padding: '0 40px', animation: 'fadeInUp 1s 0.2s both' }}>
        <div className="display-font" style={{
          fontSize: 64, lineHeight: 0.9,
          background: 'linear-gradient(180deg, #ECE9F5 0%, #A78BFA 100%)',
          WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
          textShadow: '0 0 40px rgba(139,92,246,0.3)',
        }}>LEVEL UP</div>
        <div className="display-font" style={{
          fontSize: 38, color: '#F5A623', marginTop: 4,
          textShadow: '0 0 20px rgba(245,166,35,0.6)',
        }}>— IRL —</div>
        <div style={{
          fontSize: 11, letterSpacing: 4, fontWeight: 700, color: '#8A809B',
          marginTop: 14, textTransform: 'uppercase',
        }}>Train · Track · Transform</div>
      </div>

      {/* Loading / continue */}
      <div style={{
        position: 'absolute', bottom: 90, left: 40, right: 40,
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
      }}>
        {!ready ? (
          <>
            <div style={{
              width: 180, height: 3, borderRadius: 2,
              background: 'rgba(139,92,246,0.15)', overflow: 'hidden', position: 'relative',
            }}>
              <div style={{
                position: 'absolute', top: 0, left: '-40%', width: '40%', height: '100%',
                background: 'linear-gradient(90deg, transparent, #8B5CF6, transparent)',
                animation: 'loaderSlide 1.2s ease-in-out infinite',
              }}/>
            </div>
            <div className="mono" style={{ fontSize: 10, color: '#5A5169', letterSpacing: 2 }}>INITIALIZING SYSTEM...</div>
          </>
        ) : (
          <button onClick={onContinue} style={{
            width: '100%', height: 56, borderRadius: 28,
            background: 'linear-gradient(135deg, #F5A623, #FBBF24)',
            color: '#0A0612', fontWeight: 800, fontSize: 15, letterSpacing: 2,
            textTransform: 'uppercase',
            boxShadow: '0 0 30px rgba(245,166,35,0.5), inset 0 1px 0 rgba(255,255,255,0.3)',
            animation: 'fadeInUp 0.4s',
          }}>Tap to Begin</button>
        )}
      </div>

      <style>{`
        @keyframes loaderSlide {
          0% { left: -40%; }
          100% { left: 100%; }
        }
      `}</style>
    </div>
  );
};

window.SplashScreen = SplashScreen;
