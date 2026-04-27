// Onboarding Quiz — all 19 question screens

const BODY_TYPES = [
{ key: 'lean', label: 'Lean & Toned', desc: 'Defined muscle, low body fat', icon: 'user' },
{ key: 'muscular', label: 'Muscular & Defined', desc: 'Visible size with shape', icon: 'shield' },
{ key: 'powerful', label: 'Strong & Powerful', desc: 'Max strength + mass', icon: 'bolt' },
{ key: 'balanced', label: 'Balanced & Functional', desc: 'Athletic and versatile', icon: 'target' }];


const MUSCLE_CHIPS = ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Core/Abs', 'Quads', 'Hamstrings', 'Glutes', 'Calves'];
const REWARDS = [
{ key: 'badges', label: 'Achievements & Badges', icon: 'trophy' },
{ key: 'levels', label: 'Leveling Up & Ranks', icon: 'star' },
{ key: 'streaks', label: 'Daily Streaks', icon: 'fire' },
{ key: 'challenges', label: 'Completing Challenges', icon: 'target' }];

const TENURES = [
{ key: 'none', label: 'Complete Beginner', desc: 'First time training' },
{ key: 'starting', label: 'Just Starting Out', desc: 'Under 6 months' },
{ key: 'some', label: 'Some Experience', desc: '6 months – 1 year' },
{ key: 'exp', label: 'Experienced', desc: '1–3 years consistent' }];

const EQUIPMENT = ['Barbell & Plates', 'Dumbbells', 'Kettlebells', 'Resistance Bands', 'Pull-up Bar', 'Cable Machine', 'Bench', 'Squat Rack', 'Bodyweight Only'];
const INJURIES = ['None', 'Lower Back', 'Knee', 'Shoulder', 'Wrist/Elbow', 'Hip', 'Neck', 'Other Joint', 'Chronic Condition'];
const STYLES = ['Weightlifting', 'Powerlifting', 'CrossFit', 'Calisthenics', 'HIIT/Cardio', 'Never trained formally'];
const DAY_PRESETS = [
{ key: '3day', label: '3 Days', days: [1, 3, 5] },
{ key: '5day', label: '5 Days', days: [0, 1, 2, 3, 4] },
{ key: 'daily', label: 'Every Day', days: [0, 1, 2, 3, 4, 5, 6] }];

const DAY_NAMES = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const SESSION_LENGTHS = ['15–30 min', '30–45 min', '45–60 min', '60–90 min'];

// ─── Question screens ───────────────────────────────────

// Q3: Display name
const QName = ({ answers, set, next, back, step, total }) => {
  const valid = answers.name && answers.name.length >= 2;
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Scanning biological signature..." title="What shall the System call you, Player?" />
      <div style={{ padding: '0 28px', animation: 'fadeInUp 0.5s' }}>
        <div style={{ position: 'relative' }}>
          <input
            type="text" maxLength={20} value={answers.name || ''}
            onChange={(e) => set({ name: e.target.value })}
            placeholder="Enter codename"
            style={{
              width: '100%', height: 60, padding: '0 20px',
              background: 'rgba(139,92,246,0.1)',
              border: '1.5px solid rgba(139,92,246,0.4)',
              borderRadius: 14,
              fontSize: 20, fontWeight: 700, color: '#ECE9F5',
              fontFamily: 'inherit', outline: 'none',
              boxShadow: 'inset 0 0 20px rgba(139,92,246,0.1)'
            }} />
          
          <span className="mono" style={{ position: 'absolute', right: 16, top: '50%', transform: 'translateY(-50%)', fontSize: 10, color: '#5A5169' }}>
            {(answers.name || '').length}/20
          </span>
        </div>
        <div style={{ marginTop: 16, padding: 12, borderRadius: 10, background: 'rgba(139,92,246,0.06)', border: '1px solid rgba(139,92,246,0.15)' }}>
          <div className="mono" style={{ fontSize: 10, color: '#F5A623', letterSpacing: 1.5, marginBottom: 4, fontWeight: 700 }}>[SYS NOTE]</div>
          <div style={{ fontSize: 12, color: '#8A809B', lineHeight: 1.5, fontStyle: 'italic' }}>
            Your codename appears on the leaderboard, in notifications, and on your Player profile.
          </div>
        </div>
      </div>
      <OBContinue onContinue={next} disabled={!valid} />
    </OBShell>);

};

// Q4: Age slider
const QAge = ({ answers, set, next, back, step, total }) =>
<OBShell step={step} total={total} onBack={back}>
    <OBHeader subtitle="Recording temporal coordinates..." title="Current age detected:" />
    <div style={{ padding: '0 28px', animation: 'fadeInUp 0.5s' }}>
      <OBSlider min={16} max={80} value={answers.age || 25} onChange={(v) => set({ age: v })} unit="years" />
    </div>
    <OBContinue onContinue={next} />
  </OBShell>;


// Q5: Height
const QHeight = ({ answers, set, next, back, step, total }) => {
  const unit = answers.heightUnit || 'CM';
  const v = answers.height || 175;
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Measuring spatial dimensions..." title="Height measurement:" />
      <div style={{ padding: '0 28px', animation: 'fadeInUp 0.5s' }}>
        {/* unit toggle */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 8 }}>
          <div style={{ display: 'flex', padding: 4, borderRadius: 22, background: 'rgba(139,92,246,0.1)', border: '1px solid rgba(139,92,246,0.2)' }}>
            {['CM', 'FT/IN'].map((u) =>
            <button key={u} onClick={() => set({ heightUnit: u })} style={{
              padding: '6px 16px', borderRadius: 18,
              background: unit === u ? 'rgba(245,166,35,0.25)' : 'transparent',
              color: unit === u ? '#F5A623' : '#8A809B',
              fontSize: 11, fontWeight: 700, letterSpacing: 1
            }}>{u}</button>
            )}
          </div>
        </div>
        <OBSlider
          min={140} max={220} value={v}
          onChange={(h) => set({ height: h })}
          unit={unit === 'CM' ? 'cm' : `${Math.floor(v / 2.54 / 12)}' ${Math.round(v / 2.54 % 12)}"`} />
        
      </div>
      <OBContinue onContinue={next} />
    </OBShell>);

};

// Q6: Body type
const BODY_TYPE_MORPH = {
  lean:     { scaleX: 0.90, scaleY: 1.03, contrast: 1.12, saturate: 1.10, hue: '#19E3E3' },
  muscular: { scaleX: 1.06, scaleY: 1.00, contrast: 1.08, saturate: 1.18, hue: '#A78BFA' },
  powerful: { scaleX: 1.20, scaleY: 0.97, contrast: 1.00, saturate: 1.00, hue: '#F5A623' },
  balanced: { scaleX: 1.00, scaleY: 1.00, contrast: 1.05, saturate: 1.10, hue: '#22E06B' },
};

const QBodyType = ({ answers, set, next, back, step, total }) => {
  const selected = answers.bodyType || 'balanced';
  const p = BODY_TYPE_MORPH[selected];
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Selecting combat archetype..." title="Which body type represents your goal?" />
      <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
        {/* Reference body, morphs with selection */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 14 }}>
          <div style={{
            width: 170, height: 220, position: 'relative',
            borderRadius: 14, overflow: 'hidden',
            background: `radial-gradient(ellipse at center, ${p.hue}18, transparent 70%)`,
            border: `1px solid ${p.hue}55`,
            boxShadow: `0 0 28px -8px ${p.hue}88`,
            transition: 'all 0.4s',
          }}>
            {/* Readout */}
            <div style={{ position: 'absolute', top: 8, left: 10, right: 10, display: 'flex', justifyContent: 'space-between', zIndex: 3 }}>
              <span className="mono" style={{ fontSize: 8, color: '#8A809B', letterSpacing: 1.5 }}>[SCAN]</span>
              <span className="mono" style={{ fontSize: 8, letterSpacing: 1.5, fontWeight: 700, color: p.hue, transition: 'color 0.4s' }}>
                {(BODY_TYPES.find((b) => b.key === selected)?.label || '').toUpperCase()}
              </span>
            </div>
            {/* HUD brackets */}
            {[{t:6,l:6,b:null,r:null},{t:6,l:null,b:null,r:6},{t:null,l:6,b:6,r:null},{t:null,l:null,b:6,r:6}].map((c,i)=>(
              <div key={i} style={{
                position:'absolute', top:c.t, left:c.l, right:c.r, bottom:c.b,
                width:10, height:10,
                borderTop: c.t!==null ? `1.5px solid ${p.hue}` : 'none',
                borderBottom: c.b!==null ? `1.5px solid ${p.hue}` : 'none',
                borderLeft: c.l!==null ? `1.5px solid ${p.hue}` : 'none',
                borderRight: c.r!==null ? `1.5px solid ${p.hue}` : 'none',
                opacity:0.8, transition:'border-color 0.4s', zIndex: 3,
              }}/>
            ))}
            <img src="assets/body-front.png" alt="body" style={{
              width: '100%', height: '100%', objectFit: 'contain',
              transform: `scale(${p.scaleX}, ${p.scaleY})`,
              transformOrigin: 'center bottom',
              filter: `contrast(${p.contrast}) saturate(${p.saturate}) drop-shadow(0 0 14px ${p.hue}55)`,
              transition: 'transform 0.45s cubic-bezier(.2,.8,.2,1), filter 0.4s',
            }}/>
            {/* scanline */}
            <div style={{
              position: 'absolute', left: 0, right: 0, height: 1,
              background: p.hue, boxShadow: `0 0 8px ${p.hue}`, opacity: 0.7,
              animation: 'scanY 3s linear infinite', zIndex: 2,
            }}/>
          </div>
        </div>

        {/* 4 compact cards in 2x2 grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {BODY_TYPES.map((bt) => {
            const isSel = answers.bodyType === bt.key;
            const hue = BODY_TYPE_MORPH[bt.key].hue;
            return (
              <button key={bt.key} onClick={() => set({ bodyType: bt.key })} style={{
                padding: '10px 10px', borderRadius: 12, textAlign: 'left',
                background: isSel ? `linear-gradient(135deg, ${hue}22, rgba(18,10,31,0.9))` : 'rgba(18,10,31,0.8)',
                border: `1px solid ${isSel ? hue + 'aa' : 'rgba(139,92,246,0.25)'}`,
                boxShadow: isSel ? `0 0 16px -4px ${hue}88` : 'none',
                cursor: 'pointer', transition: 'all 0.25s'
              }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: '#ECE9F5', lineHeight: 1.2 }}>{bt.label}</div>
                <div style={{ fontSize: 10, color: '#8A809B', marginTop: 2, lineHeight: 1.3 }}>{bt.desc}</div>
              </button>);

          })}
        </div>
      </div>
      <OBContinue onContinue={next} disabled={!answers.bodyType} />
    </OBShell>);

};

// Q7: Priority muscles (max 3)
const QMuscles = ({ answers, set, next, back, step, total }) => {
  const selected = answers.muscles || [];
  const toggle = (m) => {
    if (selected.includes(m)) set({ muscles: selected.filter((x) => x !== m) });else
    if (selected.length < 3) set({ muscles: [...selected, m] });
  };
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Prioritizing target zones..." title="Select up to 3 muscle groups to prioritize:" />
      <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
        <div style={{ marginBottom: 14, fontSize: 11, color: '#F5A623', letterSpacing: 1.5, fontWeight: 700, textAlign: 'center' }}>
          {selected.length} / 3 SELECTED
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center' }}>
          {MUSCLE_CHIPS.map((m) => {
            const isSel = selected.includes(m);
            const disabled = !isSel && selected.length >= 3;
            return <OBChip key={m} selected={isSel} disabled={disabled} onClick={() => toggle(m)}>{m}</OBChip>;
          })}
        </div>
      </div>
      <OBContinue onContinue={next} disabled={selected.length === 0} />
    </OBShell>);

};

// Q8: Reward style
const QRewards = ({ answers, set, next, back, step, total }) =>
<OBShell step={step} total={total} onBack={back}>
    <OBHeader subtitle="Configuring dopamine circuits..." title="What type of rewards excite you most?" />
    <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
      {REWARDS.map((r) =>
    <OBRadioCard key={r.key} selected={answers.reward === r.key} onClick={() => set({ reward: r.key })} icon={r.icon}>
          <div style={{ fontSize: 15, fontWeight: 700, color: '#ECE9F5' }}>{r.label}</div>
        </OBRadioCard>
    )}
    </div>
    <OBContinue onContinue={next} disabled={!answers.reward} />
  </OBShell>;


// Q9: Tenure
const QTenure = ({ answers, set, next, back, step, total }) =>
<OBShell step={step} total={total} onBack={back}>
    <OBHeader subtitle="Assessing combat history..." title="How long have you been training?" />
    <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
      {TENURES.map((t) =>
    <OBRadioCard key={t.key} selected={answers.tenure === t.key} onClick={() => set({ tenure: t.key })}>
          <div style={{ fontSize: 15, fontWeight: 700, color: '#ECE9F5' }}>{t.label}</div>
          <div style={{ fontSize: 12, color: '#8A809B', marginTop: 2 }}>{t.desc}</div>
        </OBRadioCard>
    )}
    </div>
    <OBContinue onContinue={next} disabled={!answers.tenure} />
  </OBShell>;


// Q10: Equipment
const QEquipment = ({ answers, set, next, back, step, total }) => {
  const sel = answers.equipment || [];
  const toggle = (m) => set({ equipment: sel.includes(m) ? sel.filter((x) => x !== m) : [...sel, m] });
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Scanning inventory..." title="Select all equipment you have access to:" />
      <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center' }}>
          {EQUIPMENT.map((e) => <OBChip key={e} selected={sel.includes(e)} onClick={() => toggle(e)}>{e}</OBChip>)}
        </div>
      </div>
      <OBContinue onContinue={next} disabled={sel.length === 0} />
    </OBShell>);

};

// Q11: Injuries
const QInjuries = ({ answers, set, next, back, step, total }) => {
  const sel = answers.injuries || [];
  const toggle = (m) => {
    if (m === 'None') return set({ injuries: sel.includes('None') ? [] : ['None'] });
    const without = sel.filter((x) => x !== 'None');
    set({ injuries: without.includes(m) ? without.filter((x) => x !== m) : [...without, m] });
  };
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Mapping constraint flags..." title="Do you have any injuries or limitations?" />
      <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center' }}>
          {INJURIES.map((e) => <OBChip key={e} selected={sel.includes(e)} onClick={() => toggle(e)}>{e}</OBChip>)}
        </div>
      </div>
      <OBContinue onContinue={next} disabled={sel.length === 0} />
    </OBShell>);

};

// Q12: Styles
const QStyles = ({ answers, set, next, back, step, total }) => {
  const sel = answers.styles || [];
  const toggle = (m) => set({ styles: sel.includes(m) ? sel.filter((x) => x !== m) : [...sel, m] });
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Cross-referencing disciplines..." title="What training styles have you tried before?" />
      <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center' }}>
          {STYLES.map((e) => <OBChip key={e} selected={sel.includes(e)} onClick={() => toggle(e)}>{e}</OBChip>)}
        </div>
      </div>
      <OBContinue onContinue={next} disabled={sel.length === 0} />
    </OBShell>);

};

// Q13: Weight
const QWeight = ({ answers, set, next, back, step, total }) => {
  const unit = answers.weightUnit || 'KG';
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Measuring mass vector..." title="Current body weight:" />
      <div style={{ padding: '0 28px', animation: 'fadeInUp 0.5s' }}>
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 8 }}>
          <div style={{ display: 'flex', padding: 4, borderRadius: 22, background: 'rgba(139,92,246,0.1)', border: '1px solid rgba(139,92,246,0.2)' }}>
            {['KG', 'LBS'].map((u) =>
            <button key={u} onClick={() => set({ weightUnit: u })} style={{
              padding: '6px 16px', borderRadius: 18,
              background: unit === u ? 'rgba(245,166,35,0.25)' : 'transparent',
              color: unit === u ? '#F5A623' : '#8A809B',
              fontSize: 11, fontWeight: 700, letterSpacing: 1
            }}>{u}</button>
            )}
          </div>
        </div>
        <OBSlider min={30} max={250} value={answers.weight || 75} onChange={(w) => set({ weight: w })} unit={unit.toLowerCase()} />
      </div>
      <OBContinue onContinue={next} />
    </OBShell>);

};

// Q14: Weight direction
const QWeightDirection = ({ answers, set, next, back, step, total }) => {
  const options = [
  { key: 'gain', label: 'Gain Weight', desc: 'Build mass and strength', icon: 'arrow-up' },
  { key: 'lose', label: 'Lose Weight', desc: 'Cut body fat', icon: 'arrow-down' },
  { key: 'maintain', label: 'Maintain', desc: 'Stay at current weight', icon: 'target' }];

  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Setting mission directive..." title="Do you have a target weight goal?" />
      <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
        {options.map((o) =>
        <OBRadioCard key={o.key} selected={answers.weightDir === o.key} onClick={() => set({ weightDir: o.key })} icon={o.icon}>
            <div style={{ fontSize: 15, fontWeight: 700, color: '#ECE9F5' }}>{o.label}</div>
            <div style={{ fontSize: 12, color: '#8A809B', marginTop: 2 }}>{o.desc}</div>
          </OBRadioCard>
        )}
      </div>
      <OBContinue onContinue={next} disabled={!answers.weightDir} />
    </OBShell>);

};

// Q15: Target weight (skipped if maintain)
const QTargetWeight = ({ answers, set, next, back, step, total }) => {
  React.useEffect(() => {
    if (answers.weightDir === 'maintain') next();
  }, []);
  if (answers.weightDir === 'maintain') return null;
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Locking target parameters..." title="Target body weight:" />
      <div style={{ padding: '0 28px', animation: 'fadeInUp 0.5s' }}>
        <OBSlider min={30} max={250} value={answers.targetWeight || answers.weight || 75} onChange={(w) => set({ targetWeight: w })} unit={(answers.weightUnit || 'KG').toLowerCase()} />
      </div>
      <OBContinue onContinue={next} />
    </OBShell>);

};

// Q16: Body fat
const QBodyFat = ({ answers, set, next, back, step, total }) => {
  const v = answers.bodyFat ?? 1;
  const levels = ['Very Lean', 'Lean', 'Average', 'Above Average'];
  const hues = ['#19E3E3', '#A78BFA', '#F5A623', '#FF6B35'];
  // Scale & saturate the reference figure by level:
  //  Very Lean → narrower (scaleX 0.88), high contrast
  //  Lean → scaleX 0.95
  //  Average → scaleX 1.0
  //  Above Average → wider (scaleX 1.12)
  const scaleX = [0.88, 0.95, 1.0, 1.12][v];
  const scaleY = [1.02, 1.0, 1.0, 0.98][v];
  const contrast = [1.15, 1.05, 1.0, 0.9][v];
  const saturate = [1.2, 1.05, 1.0, 0.9][v];
  const hue = hues[v];
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Estimating adipose composition..." title="Estimate your current body fat level:" />
      <div style={{ padding: '0 28px', animation: 'fadeInUp 0.5s' }}>
        <div style={{ textAlign: 'center', marginBottom: 18 }}>
          <div className="display-font" style={{ fontSize: 32, color: hue, lineHeight: 1, textShadow: `0 0 20px ${hue}88`, transition: 'color 0.4s, text-shadow 0.4s' }}>{levels[v]}</div>
          <div style={{ fontSize: 11, color: '#8A809B', marginTop: 6, fontStyle: 'italic' }}>estimate only · not medical advice</div>
        </div>
        {/* Morphing reference body */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 22 }}>
          <div style={{
            width: 150, height: 200, position: 'relative',
            borderRadius: 14, overflow: 'hidden',
            background: `radial-gradient(ellipse at center, ${hue}18, transparent 70%)`,
            border: `1px solid ${hue}55`,
            boxShadow: `0 0 28px -8px ${hue}77`,
            transition: 'all 0.4s',
          }}>
            {/* HUD brackets */}
            {[{t:6,l:6,b:null,r:null},{t:6,l:null,b:null,r:6},{t:null,l:6,b:6,r:null},{t:null,l:null,b:6,r:6}].map((c,i)=>(
              <div key={i} style={{
                position:'absolute', top:c.t, left:c.l, right:c.r, bottom:c.b,
                width:10, height:10,
                borderTop: c.t!==null ? `1.5px solid ${hue}` : 'none',
                borderBottom: c.b!==null ? `1.5px solid ${hue}` : 'none',
                borderLeft: c.l!==null ? `1.5px solid ${hue}` : 'none',
                borderRight: c.r!==null ? `1.5px solid ${hue}` : 'none',
                opacity:0.8, transition:'border-color 0.4s',
              }}/>
            ))}
            <img src="assets/body-front.png" alt="body" style={{
              width: '100%', height: '100%', objectFit: 'contain',
              transform: `scale(${scaleX}, ${scaleY})`,
              transformOrigin: 'center bottom',
              filter: `contrast(${contrast}) saturate(${saturate}) drop-shadow(0 0 16px ${hue}55)`,
              transition: 'transform 0.45s cubic-bezier(.2,.8,.2,1), filter 0.4s',
            }}/>
            {/* scanline */}
            <div style={{
              position: 'absolute', left: 0, right: 0, height: 1,
              background: hue, boxShadow: `0 0 8px ${hue}`, opacity: 0.7,
              animation: 'scanY 3s linear infinite',
            }}/>
          </div>
        </div>
        <OBSlider min={0} max={3} value={v} onChange={(bf) => set({ bodyFat: bf })} unit="" step={1} />
        {/* level dots */}
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 10, padding: '0 4px' }}>
          {levels.map((lvl, i) => (
            <span key={lvl} className="mono" style={{
              fontSize: 9, letterSpacing: 1,
              color: v === i ? hues[i] : '#5A5169',
              fontWeight: v === i ? 700 : 500,
              transition: 'color 0.3s',
            }}>{lvl.toUpperCase()}</span>
          ))}
        </div>
      </div>
      <OBContinue onContinue={next} />
    </OBShell>);

};

// Q17: Training days
const QDays = ({ answers, set, next, back, step, total }) => {
  const days = answers.days || [];
  const toggleDay = (i) => set({ days: days.includes(i) ? days.filter((x) => x !== i) : [...days, i].sort() });
  const applyPreset = (preset) => set({ days: preset.days });
  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Scheduling operations..." title="Which days can you train?" />
      <div style={{ padding: '0 24px', animation: 'fadeInUp 0.5s' }}>
        {/* Presets */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
          {DAY_PRESETS.map((p) =>
          <button key={p.key} onClick={() => applyPreset(p)} style={{
            flex: 1, padding: '10px 4px', borderRadius: 10,
            background: 'rgba(139,92,246,0.08)', border: '1px solid rgba(139,92,246,0.25)',
            color: '#ECE9F5', fontSize: 12, fontWeight: 700
          }}>{p.label}</button>
          )}
        </div>
        {/* Day toggles */}
        <div style={{ display: 'flex', gap: 6, justifyContent: 'space-between' }}>
          {DAY_NAMES.map((d, i) => {
            const sel = days.includes(i);
            return (
              <button key={i} onClick={() => toggleDay(i)} style={{
                flex: 1, height: 52, borderRadius: 12,
                background: sel ? 'linear-gradient(180deg, rgba(245,166,35,0.3), rgba(245,166,35,0.1))' : 'rgba(139,92,246,0.08)',
                border: `1.5px solid ${sel ? 'rgba(245,166,35,0.6)' : 'rgba(139,92,246,0.25)'}`,
                color: sel ? '#F5A623' : '#ECE9F5',
                fontSize: 15, fontWeight: 700,
                boxShadow: sel ? '0 0 14px -4px rgba(245,166,35,0.6)' : 'none',
                transition: 'all 0.2s'
              }}>{d}</button>);

          })}
        </div>
        <div style={{ textAlign: 'center', marginTop: 14, fontSize: 12, color: '#8A809B' }}>
          {days.length} day{days.length !== 1 ? 's' : ''} selected {days.length < 2 && '· minimum 2'}
        </div>
      </div>
      <OBContinue onContinue={next} disabled={days.length < 2} />
    </OBShell>);

};

// Q18: Session length
const QSessionLength = ({ answers, set, next, back, step, total }) =>
<OBShell step={step} total={total} onBack={back}>
    <OBHeader subtitle="Allocating session duration..." title="How long are your typical workouts?" />
    <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
      {SESSION_LENGTHS.map((s) =>
    <OBRadioCard key={s} selected={answers.sessionLen === s} onClick={() => set({ sessionLen: s })} icon="clock">
          <div style={{ fontSize: 15, fontWeight: 700, color: '#ECE9F5' }}>{s}</div>
        </OBRadioCard>
    )}
    </div>
    <OBContinue onContinue={next} disabled={!answers.sessionLen} />
  </OBShell>;


// Q19: Notifications
const QNotifications = ({ answers, set, next, back, step, total }) => {
  const notifs = answers.notifs || { reminders: true, streaks: true, reports: true };
  const toggle = (k) => set({ notifs: { ...notifs, [k]: !notifs[k] } });
  const rows = [
  { key: 'reminders', label: 'Workout Reminders', desc: 'Nudge 1hr before your usual time' },
  { key: 'streaks', label: 'Streak Warnings', desc: 'Alert before your streak breaks' },
  { key: 'reports', label: 'Weekly Progress Reports', desc: 'Sunday summary of gains' }];

  return (
    <OBShell step={step} total={total} onBack={back}>
      <OBHeader subtitle="Configuring alert channels..." title="Which notifications would you like?" />
      <div style={{ padding: '0 20px', animation: 'fadeInUp 0.5s' }}>
        {rows.map((r) => {
          const on = notifs[r.key];
          return (
            <div key={r.key} style={{
              padding: '16px 18px', borderRadius: 14, marginBottom: 8,
              background: 'rgba(18,10,31,0.7)',
              border: '1px solid rgba(139,92,246,0.18)',
              display: 'flex', alignItems: 'center', gap: 12
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 700, color: '#ECE9F5' }}>{r.label}</div>
                <div style={{ fontSize: 11, color: '#8A809B', marginTop: 2 }}>{r.desc}</div>
              </div>
              <button onClick={() => toggle(r.key)} style={{
                width: 46, height: 26, borderRadius: 13,
                background: on ? '#F5A623' : 'rgba(139,92,246,0.2)',
                border: `1px solid ${on ? '#F5A623' : 'rgba(139,92,246,0.3)'}`,
                position: 'relative', flexShrink: 0,
                boxShadow: on ? '0 0 12px rgba(245,166,35,0.5)' : 'none',
                transition: 'all 0.2s'
              }}>
                <div style={{
                  position: 'absolute', top: 2, left: on ? 22 : 2,
                  width: 20, height: 20, borderRadius: 10,
                  background: '#fff', boxShadow: '0 2px 4px rgba(0,0,0,0.3)',
                  transition: 'left 0.2s'
                }} />
              </button>
            </div>);

        })}
      </div>
      <OBContinue onContinue={next} label="Finalize Setup" />
    </OBShell>);

};

Object.assign(window, { QName, QAge, QHeight, QBodyType, QMuscles, QRewards, QTenure, QEquipment, QInjuries, QStyles, QWeight, QWeightDirection, QTargetWeight, QBodyFat, QDays, QSessionLength, QNotifications });