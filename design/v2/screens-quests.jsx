// Quests screen — 3 tabs (Daily / Weekly / Boss), rich cards

const QUESTS_DATA = {
  daily: [
    { title: "Complete today's workout", desc: 'Finish your generated Push Day session', xp: 80, progress: 0, of: 1, icon: 'target' },
    { title: 'Hit 3 sets at RPE 8+', desc: 'Push close to failure on 3 working sets', xp: 60, progress: 1, of: 3, icon: 'bolt' },
    { title: 'Finish under 45 min', desc: 'Keep rest short, stay moving', xp: 50, progress: 0, of: 1, icon: 'clock' },
    { title: 'Log every set with RPE', desc: 'Score your intensity honestly', xp: 40, progress: 2, of: 8, icon: 'chart' },
  ],
  weekly: [
    { title: 'Train 4 days this week', desc: 'Stay on schedule', xp: 300, progress: 2, of: 4, icon: 'cal' },
    { title: 'Beat a personal record', desc: 'More weight for reps on any lift', xp: 200, progress: 0, of: 1, icon: 'trophy' },
    { title: 'Total volume: 8,000 kg', desc: 'Sum of weight × reps across the week', xp: 350, progress: 4820, of: 8000, icon: 'dumbbell' },
    { title: 'Log RPE on every set', desc: 'All 7 sessions tracked', xp: 250, progress: 12, of: 21, icon: 'target' },
  ],
  boss: [
    { title: 'Deadlift Bodyweight × 2', desc: 'Pull 160kg for a single rep', xp: 2500, progress: 140, of: 160, unit: 'kg', icon: 'shield', phase: 'WEEK 4 / 6' },
    { title: 'Add 10% to Bench e1RM', desc: 'Estimated one-rep max: 90 → 99kg', xp: 2000, progress: 93, of: 99, unit: 'kg', icon: 'shield', phase: 'WEEK 2 / 6' },
  ],
};

const QuestsScreen = () => {
  const [tab, setTab] = React.useState('daily');
  const quests = QUESTS_DATA[tab];
  const tabColor = tab === 'daily' ? '#F5A623' : tab === 'weekly' ? '#A78BFA' : '#FF6B35';

  return (
    <div className="scroll" style={{ position: 'absolute', inset: 0, overflow: 'auto', paddingTop: 54, paddingBottom: 110 }}>
      <div style={{ padding: '20px 20px 4px', textAlign: 'center' }}>
        <div className="display-font" style={{ fontSize: 28, color: '#ECE9F5', letterSpacing: 2 }}>QUESTS</div>
        <div className="mono" style={{ fontSize: 10, color: '#8A809B', letterSpacing: 2, marginTop: 2 }}>LEVEL UP THROUGH CHALLENGES</div>
      </div>

      {/* Tabs */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{
          display: 'flex', gap: 4, padding: 4, borderRadius: 14,
          background: 'rgba(18,10,31,0.8)', border: '1px solid rgba(139,92,246,0.2)',
        }}>
          {[
            { key: 'daily', label: 'Daily', color: '#F5A623' },
            { key: 'weekly', label: 'Weekly', color: '#A78BFA' },
            { key: 'boss', label: 'Boss', color: '#FF6B35' },
          ].map(t => {
            const active = tab === t.key;
            return (
              <button key={t.key} onClick={() => setTab(t.key)} style={{
                flex: 1, padding: '10px 0', borderRadius: 10,
                background: active ? `linear-gradient(180deg, ${t.color}33, ${t.color}0f)` : 'transparent',
                border: active ? `1px solid ${t.color}66` : '1px solid transparent',
                color: active ? t.color : '#8A809B',
                fontSize: 13, fontWeight: 700, letterSpacing: 1.2,
                boxShadow: active ? `0 0 14px -4px ${t.color}88` : 'none',
                transition: 'all 0.2s',
              }}>{t.label.toUpperCase()}</button>
            );
          })}
        </div>
      </div>

      {/* Reset info */}
      <div style={{ padding: '10px 20px 4px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div className="mono" style={{ fontSize: 10, color: '#5A5169', letterSpacing: 1.5 }}>
          {tab === 'daily' && 'RESETS AT 04:00 LOCAL'}
          {tab === 'weekly' && 'RESETS MONDAY 00:00'}
          {tab === 'boss' && 'MULTI-WEEK OBJECTIVE'}
        </div>
        <div className="mono" style={{ fontSize: 10, color: tabColor, letterSpacing: 1, fontWeight: 700 }}>
          {quests.length} ACTIVE
        </div>
      </div>

      {/* Boss banner */}
      {tab === 'boss' && (
        <div style={{ padding: '8px 20px 0' }}>
          <div style={{
            padding: 16, borderRadius: 16,
            background: 'linear-gradient(135deg, rgba(255,107,53,0.18), rgba(139,92,246,0.15))',
            border: '1px solid rgba(255,107,53,0.4)',
            position: 'relative', overflow: 'hidden',
            boxShadow: '0 0 24px -6px rgba(255,107,53,0.4)',
          }}>
            {/* Boss silhouette */}
            <div style={{ position: 'absolute', right: -10, top: -10, bottom: -10, width: 120, opacity: 0.4 }}>
              <svg viewBox="0 0 120 140" style={{ width: '100%', height: '100%' }}>
                <defs>
                  <linearGradient id="bossGrad" x1="0" x2="0" y1="0" y2="1">
                    <stop offset="0%" stopColor="#FF6B35"/>
                    <stop offset="100%" stopColor="#8B5CF6"/>
                  </linearGradient>
                </defs>
                {/* Brutalist boss silhouette */}
                <path d="M60 15 L75 25 L80 40 L75 50 L80 60 L95 65 L100 85 L92 95 L95 115 L85 130 L75 135 L65 125 L65 105 L55 105 L55 125 L45 135 L35 130 L25 115 L28 95 L20 85 L25 65 L40 60 L45 50 L40 40 L45 25 Z"
                      fill="url(#bossGrad)"/>
                {/* Glowing eyes */}
                <circle cx="52" cy="30" r="2" fill="#FF6B35">
                  <animate attributeName="opacity" values="0.4;1;0.4" dur="1.5s" repeatCount="indefinite"/>
                </circle>
                <circle cx="68" cy="30" r="2" fill="#FF6B35">
                  <animate attributeName="opacity" values="0.4;1;0.4" dur="1.5s" repeatCount="indefinite"/>
                </circle>
              </svg>
            </div>
            <div style={{ position: 'relative', zIndex: 1 }}>
              <div className="mono" style={{ fontSize: 9, letterSpacing: 2, color: '#FF6B35', fontWeight: 800, marginBottom: 4 }}>[BOSS TIER ACTIVE]</div>
              <div className="display-font" style={{ fontSize: 22, color: '#ECE9F5', lineHeight: 1, marginBottom: 4 }}>IRON COLOSSUS</div>
              <div style={{ fontSize: 11, color: '#8A809B', maxWidth: 200, lineHeight: 1.4 }}>Defeat the Colossus to earn the Iron Ascendant title and 5000 bonus XP.</div>
            </div>
          </div>
        </div>
      )}

      {/* Quest cards */}
      <div style={{ padding: '14px 20px 0' }}>
        {quests.map((q, i) => {
          const pct = (q.progress / q.of) * 100;
          const done = q.progress >= q.of;
          return (
            <div key={i} style={{
              padding: 14, borderRadius: 16, marginBottom: 10,
              background: done ? 'linear-gradient(135deg, rgba(34,224,107,0.12), rgba(18,10,31,0.8))' : 'rgba(18,10,31,0.85)',
              border: `1px solid ${done ? 'rgba(34,224,107,0.4)' : `${tabColor}33`}`,
              boxShadow: done ? '0 0 16px -6px rgba(34,224,107,0.4)' : 'none',
              position: 'relative',
            }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 10 }}>
                <div style={{
                  width: 42, height: 42, borderRadius: 11, flexShrink: 0,
                  background: `${tabColor}22`,
                  border: `1px solid ${tabColor}66`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <Icon name={q.icon} size={20} color={tabColor}/>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                    <div style={{ fontSize: 14, fontWeight: 700, color: '#ECE9F5', lineHeight: 1.3 }}>{q.title}</div>
                    <span className="mono" style={{ fontSize: 11, color: tabColor, fontWeight: 700, whiteSpace: 'nowrap' }}>+{q.xp.toLocaleString()} XP</span>
                  </div>
                  <div style={{ fontSize: 11, color: '#8A809B', marginTop: 2, lineHeight: 1.4 }}>{q.desc}</div>
                  {q.phase && (
                    <div className="mono" style={{ fontSize: 9, color: tabColor, letterSpacing: 1.5, marginTop: 6, fontWeight: 700 }}>{q.phase}</div>
                  )}
                </div>
              </div>
              {/* Progress */}
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: '#8A809B', marginBottom: 4 }}>
                <span>Progress</span>
                <span className="mono" style={{ color: done ? '#22E06B' : tabColor, fontWeight: 700 }}>
                  {q.progress.toLocaleString()}{q.unit ? ` ${q.unit}` : ''} / {q.of.toLocaleString()}{q.unit ? ` ${q.unit}` : ''}
                </span>
              </div>
              <div style={{ height: 6, borderRadius: 3, background: 'rgba(139,92,246,0.12)', overflow: 'hidden' }}>
                <div style={{
                  width: `${pct}%`, height: '100%',
                  background: done ? 'linear-gradient(90deg, #22E06B, #4ADE80)' : `linear-gradient(90deg, ${tabColor}, #FBBF24)`,
                  borderRadius: 3,
                  boxShadow: `0 0 8px ${done ? '#22E06B' : tabColor}88`,
                  transition: 'width 0.4s',
                }}/>
              </div>
              {done && (
                <div style={{ marginTop: 8, fontSize: 11, fontWeight: 700, color: '#22E06B', display: 'flex', alignItems: 'center', gap: 6 }}>
                  <Icon name="check" size={14} color="#22E06B"/> CLAIMED
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

window.QuestsScreen = QuestsScreen;
