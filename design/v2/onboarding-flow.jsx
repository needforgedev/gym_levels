// Onboarding orchestrator — runs the full 19-question flow with section interstitials

const SECTIONS = [
  { name: 'PLAYER REGISTRATION', color: '#19E3E3', subtitle: 'Identifying recruit.' },
  { name: 'MISSION OBJECTIVES', color: '#8B5CF6', subtitle: 'Defining target outcomes.' },
  { name: 'COMBAT EXPERIENCE', color: '#F5D742', subtitle: 'Assessing prior training.' },
  { name: 'PHYSICAL ATTRIBUTES', color: '#19E3E3', subtitle: 'Recording biometrics.' },
  { name: 'DAILY OPERATIONS', color: '#22E06B', subtitle: 'Scheduling sessions.' },
  { name: 'SYSTEM SETTINGS', color: '#E6EEF5', subtitle: 'Configuring alerts.' },
];

const QUESTION_SECTIONS = [0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 5]; // which section each Q belongs to

const QUESTIONS = [
  QName, QAge, QHeight,
  QBodyType, QMuscles, QRewards,
  QTenure, QEquipment, QInjuries, QStyles,
  QWeight, QWeightDirection, QTargetWeight, QBodyFat,
  QDays, QSessionLength,
  QNotifications,
];

const SectionIntro = ({ section, onContinue }) => {
  React.useEffect(() => {
    const t = setTimeout(onContinue, 1100);
    return () => clearTimeout(t);
  }, []);
  return (
    <div style={{
      position: 'absolute', inset: 0, background: '#0A0612',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      animation: 'fadeIn 0.3s',
    }}>
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(circle at 50% 50%, ${section.color}22, transparent 60%)`,
        pointerEvents: 'none',
      }}/>
      <div style={{ position: 'relative', zIndex: 2, textAlign: 'center', padding: '0 30px' }}>
        <div className="mono" style={{ fontSize: 10, letterSpacing: 3, color: section.color, marginBottom: 16, fontStyle: 'italic', opacity: 0, animation: 'fadeInUp 0.4s 0.1s forwards' }}>
          [SYS] {section.subtitle}
        </div>
        <div className="display-font" style={{
          fontSize: 34, lineHeight: 1, color: '#ECE9F5', letterSpacing: 1,
          textShadow: `0 0 30px ${section.color}66`,
          opacity: 0, animation: 'fadeInUp 0.5s 0.2s forwards',
        }}>
          {section.name}
        </div>
        <div style={{ width: 140, height: 2, margin: '20px auto 0', background: section.color, boxShadow: `0 0 12px ${section.color}`, opacity: 0, animation: 'fadeInUp 0.5s 0.4s forwards' }}/>
      </div>
    </div>
  );
};

const OnboardingFlow = ({ onComplete, onBackToHype }) => {
  // Phase: 'sectionIntro' | 'question' | 'loader'
  const [phase, setPhase] = React.useState('sectionIntro');
  const [qIdx, setQIdx] = React.useState(0);
  const [answers, setAnswers] = React.useState({ name: '', age: 25, height: 175, weight: 75 });

  const set = (patch) => setAnswers(a => ({ ...a, ...patch }));

  const currentSection = QUESTION_SECTIONS[qIdx];
  const section = SECTIONS[currentSection];

  const next = () => {
    // If this is the last question in its section, show loader
    const nextIdx = qIdx + 1;
    if (nextIdx >= QUESTIONS.length) {
      onComplete(answers);
      return;
    }
    const nextSection = QUESTION_SECTIONS[nextIdx];
    if (nextSection !== currentSection) {
      setPhase('loader');
    } else {
      setQIdx(nextIdx);
    }
  };

  const back = () => {
    if (qIdx === 0) { onBackToHype(); return; }
    setQIdx(qIdx - 1);
    setPhase('question');
  };

  const afterLoader = () => {
    setQIdx(qIdx + 1);
    setPhase('sectionIntro');
  };

  const afterSectionIntro = () => setPhase('question');

  if (phase === 'sectionIntro') return <SectionIntro section={section} onContinue={afterSectionIntro}/>;
  if (phase === 'loader') return <CalibratingLoader onDone={afterLoader}/>;

  const Q = QUESTIONS[qIdx];
  return <Q
    answers={answers}
    set={set}
    next={next}
    back={back}
    step={qIdx + 1}
    total={QUESTIONS.length}
  />;
};

window.OnboardingFlow = OnboardingFlow;
