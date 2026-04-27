// App root — full entry flow: splash → hype → onboarding → challenge intro → paywall → main app

const { useState } = React;

// Phases: splash | hype | onboarding | challengeIntro | paywall | app
function App() {
  const [phase, setPhase] = useState('splash');
  const [onboardingAnswers, setOnboardingAnswers] = useState(null);

  // App phase state (only used when phase === 'app')
  const [tab, setTab] = useState('home');
  const [stack, setStack] = useState([]);
  const [sheet, setSheet] = useState(null);

  const push = s => setStack([...stack, s]);
  const pop = () => setStack(stack.slice(0, -1));
  const clear = () => setStack([]);
  const top = stack[stack.length - 1];

  // ─── Main app renderer (when phase === 'app') ───
  const renderTab = () => {
    switch (tab) {
      case 'home':
        return <HomeScreen
          onStartWorkout={() => push('logger')}
          onOpenNext={() => push('todays-workout')}
          onOpenStreak={() => setTab('streak')}
          onOpenClass={() => setSheet('class')}
        />;
      case 'streak': return <StreakScreen/>;
      case 'quests': return <QuestsScreen/>;
      case 'profile':
        return <ProfileScreen
          onOpenClass={() => setSheet('class')}
          onOpenRanks={() => push('ranks')}
          onOpenWeight={() => push('weight')}
          onRestartOnboarding={() => { clear(); setTab('home'); setPhase('splash'); }}
        />;
      default: return null;
    }
  };

  const renderOverlay = () => {
    if (!top) return null;
    switch (top) {
      case 'todays-workout': return <TodaysWorkoutScreen onBack={pop} onStart={() => setStack(['logger'])}/>;
      case 'logger': return <LoggerScreen onClose={pop} onFinish={() => setStack(['complete'])}/>;
      case 'complete': return <WorkoutCompleteScreen onDone={clear}/>;
      case 'ranks': return <RanksScreen onBack={pop}/>;
      case 'weight': return <WeightScreen onBack={pop}/>;
      default: return null;
    }
  };

  const hideTabsOverlays = ['logger', 'complete'];
  const showTabs = !hideTabsOverlays.includes(top);

  // ─── Entry flow renderer ───
  const renderPhone = () => {
    switch (phase) {
      case 'splash':
        return <SplashScreen onContinue={() => setPhase('hype')}/>;
      case 'hype':
        return <HypeSlides onContinue={() => setPhase('onboarding')}/>;
      case 'onboarding':
        return <OnboardingFlow
          onComplete={(ans) => { setOnboardingAnswers(ans); setPhase('challengeIntro'); }}
          onBackToHype={() => setPhase('hype')}
        />;
      case 'challengeIntro':
        return <ChallengeIntroScreen
          onContinue={() => setPhase('paywall')}
          onBack={() => setPhase('onboarding')}
        />;
      case 'paywall':
        return <PaywallScreen
          onContinue={() => setPhase('app')}
          onSkip={() => setPhase('app')}
          onBack={() => setPhase('challengeIntro')}
        />;
      case 'app':
      default:
        return (
          <>
            {renderTab()}
            {top && (
              <div style={{
                position: 'absolute', inset: 0, background: PALETTE.bg, zIndex: 40,
                animation: 'fadeIn 0.2s',
              }}>
                {renderOverlay()}
                {showTabs && <TabBar active={tab} onChange={t => { setTab(t); clear(); }}/>}
              </div>
            )}
            {sheet === 'class' && <ClassSheet onClose={() => setSheet(null)}/>}
          </>
        );
    }
  };

  const inApp = phase === 'app';
  const tabsForPhone = inApp ? tab : null;

  return (
    <div style={{
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 40, position: 'relative', zIndex: 2,
    }}>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}>
        <div style={{ textAlign: 'center' }}>
          <div className="display-font" style={{
            fontSize: 42, letterSpacing: 2, lineHeight: 1,
            background: 'linear-gradient(135deg, #C4B5FD 0%, #A78BFA 50%, #F5A623 100%)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
          }}>LEVEL UP IRL</div>
          <div style={{ fontSize: 11, color: '#8A809B', letterSpacing: 3, marginTop: 4, fontWeight: 600 }}>TRAIN · TRACK · TRANSFORM</div>
        </div>

        {/* Phase nav chips (dev-friendly jump buttons) */}
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', justifyContent: 'center', maxWidth: 420 }}>
          {[
            { key: 'splash', label: 'Splash' },
            { key: 'hype', label: 'Hype' },
            { key: 'onboarding', label: 'Onboarding' },
            { key: 'challengeIntro', label: 'Challenges' },
            { key: 'paywall', label: 'Paywall' },
            { key: 'app', label: 'Main App' },
          ].map(p => (
            <button key={p.key} onClick={() => setPhase(p.key)} style={{
              padding: '5px 10px', borderRadius: 14,
              background: phase === p.key ? 'rgba(245,166,35,0.2)' : 'rgba(139,92,246,0.08)',
              border: `1px solid ${phase === p.key ? 'rgba(245,166,35,0.5)' : 'rgba(139,92,246,0.25)'}`,
              color: phase === p.key ? '#F5A623' : '#8A809B',
              fontSize: 10, fontWeight: 700, letterSpacing: 0.5,
              cursor: 'pointer',
            }}>{p.label}</button>
          ))}
        </div>

        <Phone tab={tabsForPhone} onTab={t => { setTab(t); clear(); }} showTabs={inApp && showTabs}>
          {renderPhone()}
        </Phone>

        <div style={{ fontSize: 11, color: '#5A5169', marginTop: 4, textAlign: 'center', maxWidth: 380, lineHeight: 1.5 }}>
          {phase === 'app'
            ? <>Tap <span style={{ color: '#19E3E3' }}>Start Workout</span> · swap tabs · tap <span style={{ color: '#F5A623' }}>Mass Builder</span> card on Profile</>
            : phase === 'onboarding'
            ? <>All 17 questions are interactive — drag sliders, toggle chips, pick options</>
            : <>Use the chips above to jump between phases</>
          }
        </div>
      </div>
    </div>
  );
}

window.App = App;

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App/>);
