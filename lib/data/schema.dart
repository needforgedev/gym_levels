// Schema — PRD §11.7 translated to raw-sqflite `CREATE TABLE` strings.
// Column names are exported as `const` so services reference them through
// the same source of truth (typo → static analyzer error, not runtime).
//
// Conventions:
// - Timestamps: `INTEGER` Unix-epoch seconds.
// - Array columns (`priority_muscles`, `equipment`, etc.): JSON-encoded `TEXT`.
// - `user_id` is always `1` in v1.0 (single-user, single-device).

/// Local-DB schema version. Bump every time we add an `onUpgrade`
/// migration. The `schema_version` table audits every bump.
///
/// Version history:
///   1 — initial schema (Phase 1.1).
///   2 — Scope B sync columns (`cloud_id`, `cloud_updated_at`,
///       `cloud_deleted_at`) added to every cloud-mirrored table,
///       plus new local `sync_outbox` + `sync_state` tables.
///       Lands with [socials_plan.md](../../socials_plan.md) S3.0.
const int kSchemaVersion = 2;

// Table names
class T {
  T._();
  static const player = 'player';
  static const goals = 'goals';
  static const experience = 'experience';
  static const schedule = 'schedule';
  static const notificationPrefs = 'notification_prefs';
  static const playerClass = 'player_class';
  static const exercises = 'exercises';
  static const workouts = 'workouts';
  static const sets = 'sets';
  static const workoutOverrides = 'workout_overrides';
  static const exerciseSwaps = 'exercise_swaps';
  static const muscleRanks = 'muscle_ranks';
  static const quests = 'quests';
  static const streaks = 'streaks';
  static const streakFreezeEvents = 'streak_freeze_events';
  static const weightLogs = 'weight_logs';
  static const subscriptions = 'subscriptions';
  static const analyticsEvents = 'analytics_events';
  static const crashReports = 'crash_reports';
  static const schemaVersion = 'schema_version';
  // Scope B sync (v2)
  static const syncOutbox = 'sync_outbox';
  static const syncState = 'sync_state';
}

/// Column names added to every cloud-mirrored local table by the v2
/// schema bump (Phase 4.1a S3.0). Each synced row tracks:
///   • `cloud_id` — UUID (stored as TEXT). Generated locally on first
///     push; matches the cloud row's primary key.
///   • `cloud_updated_at` — epoch seconds of the last successful push
///     ack from the server. Used by conflict resolution.
///   • `cloud_deleted_at` — soft-delete flag, NULL when alive. Set
///     locally when a row is removed; the sync engine pushes a delete
///     to the server, then the row is physically removed locally.
class CSync {
  CSync._();
  static const cloudId = 'cloud_id';
  static const cloudUpdatedAt = 'cloud_updated_at';
  static const cloudDeletedAt = 'cloud_deleted_at';
}

/// Pending-push queue. Every local write to a cloud-mirrored table
/// also writes one row here. The `SyncEngine` drains this in FIFO
/// order, marks rows pushed, and prunes them.
class CSyncOutbox {
  CSyncOutbox._();
  static const id = 'id';
  static const tableName = 'table_name';
  /// Local PK of the row being pushed (always int — matches the
  /// origin table's auto-increment).
  static const localRowId = 'local_row_id';
  /// `cloud_id` UUID — same value as the origin row's `cloud_id`
  /// column. Stored here so we don't have to re-read the row when
  /// draining; if the row is later deleted locally, we still know
  /// which cloud_id to delete server-side.
  static const cloudId = 'cloud_id';
  /// `'upsert'` | `'delete'`.
  static const opType = 'op_type';
  /// JSON snapshot of the row at enqueue time. Captures the value to
  /// push *now*, even if the local row is edited again before this
  /// outbox entry drains.
  static const payloadJson = 'payload_json';
  static const createdAt = 'created_at';
  static const attemptCount = 'attempt_count';
  static const lastAttemptAt = 'last_attempt_at';
  static const lastError = 'last_error';
  /// Set when the server has acked the push. Rows with a non-null
  /// pushedAt are pruned by `SyncEngine.prunePushed()`.
  static const pushedAt = 'pushed_at';
}

/// Singleton bookkeeping for resumable initial sync (Phase 4.1a S3b)
/// and outbox-drain telemetry. Always exactly one row, `id = 1`.
class CSyncState {
  CSyncState._();
  static const id = 'id';
  /// Epoch seconds of the most recent successful full initial-sync
  /// completion. NULL until the first sign-in's hydration finishes.
  static const lastFullSyncAt = 'last_full_sync_at';
  /// Which table the in-progress initial-sync is currently pulling.
  /// NULL when no initial-sync is in flight.
  static const initialSyncTable = 'initial_sync_table';
  /// Pagination cursor inside `initialSyncTable` for resumability.
  static const initialSyncOffset = 'initial_sync_offset';
  /// Epoch seconds of the most recent outbox drain attempt
  /// (regardless of success).
  static const lastOutboxDrainAt = 'last_outbox_drain_at';
}

// Column names — grouped by table.
class CPlayer {
  CPlayer._();
  static const id = 'id';
  static const displayName = 'display_name';
  static const age = 'age';
  static const heightCm = 'height_cm';
  static const weightKg = 'weight_kg';
  static const bodyFatEstimate = 'body_fat_estimate';
  static const unitsPref = 'units_pref';
  static const onboardedAt = 'onboarded_at';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class CGoals {
  CGoals._();
  static const userId = 'user_id';
  static const bodyType = 'body_type';
  static const priorityMuscles = 'priority_muscles';
  static const rewardStyle = 'reward_style';
  static const weightDirection = 'weight_direction';
  static const targetWeightKg = 'target_weight_kg';
  static const updatedAt = 'updated_at';
}

class CExperience {
  CExperience._();
  static const userId = 'user_id';
  static const tenure = 'tenure';
  static const equipment = 'equipment';
  static const limitations = 'limitations';
  static const styles = 'styles';
  static const updatedAt = 'updated_at';
}

class CSchedule {
  CSchedule._();
  static const userId = 'user_id';
  static const days = 'days';
  static const sessionMinutes = 'session_minutes';
  static const updatedAt = 'updated_at';
}

class CNotificationPrefs {
  CNotificationPrefs._();
  static const userId = 'user_id';
  static const workoutReminders = 'workout_reminders';
  static const streakWarnings = 'streak_warnings';
  static const weeklyReports = 'weekly_reports';
}

class CPlayerClass {
  CPlayerClass._();
  static const userId = 'user_id';
  static const classKey = 'class_key';
  static const assignedAt = 'assigned_at';
  static const lastChangedAt = 'last_changed_at';
  static const evolutionHistory = 'evolution_history';
}

class CExercise {
  CExercise._();
  static const id = 'id';
  static const name = 'name';
  static const primaryMuscle = 'primary_muscle';
  static const secondaryMuscles = 'secondary_muscles';
  static const equipment = 'equipment';
  static const baseXp = 'base_xp';
  static const demoVideoUrl = 'demo_video_url';
  static const cueText = 'cue_text';
}

class CWorkout {
  CWorkout._();
  static const id = 'id';
  static const userId = 'user_id';
  static const startedAt = 'started_at';
  static const endedAt = 'ended_at';
  static const xpEarned = 'xp_earned';
  static const volumeKg = 'volume_kg';
  static const note = 'note';
}

class CSet {
  CSet._();
  static const id = 'id';
  static const workoutId = 'workout_id';
  static const exerciseId = 'exercise_id';
  static const setNumber = 'set_number';
  static const weightKg = 'weight_kg';
  static const reps = 'reps';
  static const rpe = 'rpe';
  static const isPr = 'is_pr';
  static const xpEarned = 'xp_earned';
  static const completedAt = 'completed_at';
}

class CWorkoutOverride {
  CWorkoutOverride._();
  static const id = 'id';
  static const userId = 'user_id';
  static const scheduledFor = 'scheduled_for';
  static const overridesJson = 'overrides_json';
  static const createdAt = 'created_at';
}

class CExerciseSwap {
  CExerciseSwap._();
  static const id = 'id';
  static const userId = 'user_id';
  static const originalExerciseId = 'original_exercise_id';
  static const swappedToId = 'swapped_to_id';
  static const workoutId = 'workout_id';
  static const reason = 'reason';
  static const createdAt = 'created_at';
}

class CMuscleRank {
  CMuscleRank._();
  static const userId = 'user_id';
  static const muscle = 'muscle';
  static const rank = 'rank';
  static const subRank = 'sub_rank';
  static const rankXp = 'rank_xp';
  static const updatedAt = 'updated_at';
}

class CQuest {
  CQuest._();
  static const id = 'id';
  static const userId = 'user_id';
  static const type = 'type';
  static const title = 'title';
  static const description = 'description';
  static const target = 'target';
  static const progress = 'progress';
  static const xpReward = 'xp_reward';
  static const issuedAt = 'issued_at';
  static const expiresAt = 'expires_at';
  static const completedAt = 'completed_at';
  static const locked = 'locked';
}

class CStreak {
  CStreak._();
  static const userId = 'user_id';
  static const current = 'current';
  static const longest = 'longest';
  static const lastActiveDate = 'last_active_date';
  static const freezesRemaining = 'freezes_remaining';
  static const freezesPeriodStart = 'freezes_period_start';
}

class CStreakFreezeEvent {
  CStreakFreezeEvent._();
  static const id = 'id';
  static const userId = 'user_id';
  static const usedOn = 'used_on';
  static const reason = 'reason';
}

class CWeightLog {
  CWeightLog._();
  static const id = 'id';
  static const userId = 'user_id';
  static const loggedOn = 'logged_on';
  static const weightKg = 'weight_kg';
  static const note = 'note';
}

class CSubscription {
  CSubscription._();
  static const userId = 'user_id';
  static const tier = 'tier';
  static const status = 'status';
  static const purchasedAt = 'purchased_at';
  static const renewsAt = 'renews_at';
  static const receiptData = 'receipt_data';
  static const lastVerifiedAt = 'last_verified_at';
  static const updatedAt = 'updated_at';
}

class CAnalyticsEvent {
  CAnalyticsEvent._();
  static const id = 'id';
  static const name = 'name';
  static const payloadJson = 'payload_json';
  static const createdAt = 'created_at';
  static const uploadedAt = 'uploaded_at';
}

class CCrashReport {
  CCrashReport._();
  static const id = 'id';
  static const createdAt = 'created_at';
  static const payloadJson = 'payload_json';
  static const uploadedAt = 'uploaded_at';
}

class CSchemaVersion {
  CSchemaVersion._();
  static const version = 'version';
  static const appliedAt = 'applied_at';
  static const note = 'note';
}

/// All `CREATE TABLE` + `CREATE INDEX` statements, executed in order by
/// [AppDb.onCreate] on first launch. Order matters: tables referenced by
/// foreign keys must come before their referencers.
const List<String> createStatements = [
  // ───────── Player (root) ─────────
  '''
  CREATE TABLE ${T.player} (
    ${CPlayer.id}                INTEGER PRIMARY KEY CHECK (${CPlayer.id} = 1),
    ${CPlayer.displayName}       TEXT    NOT NULL,
    ${CPlayer.age}               INTEGER NOT NULL DEFAULT 0,
    ${CPlayer.heightCm}          REAL    NOT NULL DEFAULT 0,
    ${CPlayer.weightKg}          REAL    NOT NULL DEFAULT 0,
    ${CPlayer.bodyFatEstimate}   TEXT,
    ${CPlayer.unitsPref}         TEXT    NOT NULL DEFAULT 'metric',
    ${CPlayer.onboardedAt}       INTEGER,
    ${CPlayer.createdAt}         INTEGER NOT NULL,
    ${CPlayer.updatedAt}         INTEGER NOT NULL,
    ${CSync.cloudId}             TEXT,
    ${CSync.cloudUpdatedAt}      INTEGER,
    ${CSync.cloudDeletedAt}      INTEGER
  )
  ''',

  // ───────── Profile children ─────────
  '''
  CREATE TABLE ${T.goals} (
    ${CGoals.userId}           INTEGER PRIMARY KEY REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CGoals.bodyType}         TEXT,
    ${CGoals.priorityMuscles}  TEXT NOT NULL DEFAULT '[]',
    ${CGoals.rewardStyle}      TEXT,
    ${CGoals.weightDirection}  TEXT,
    ${CGoals.targetWeightKg}   REAL,
    ${CGoals.updatedAt}        INTEGER NOT NULL,
    ${CSync.cloudId}           TEXT,
    ${CSync.cloudUpdatedAt}    INTEGER,
    ${CSync.cloudDeletedAt}    INTEGER
  )
  ''',

  '''
  CREATE TABLE ${T.experience} (
    ${CExperience.userId}      INTEGER PRIMARY KEY REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CExperience.tenure}      TEXT,
    ${CExperience.equipment}   TEXT NOT NULL DEFAULT '[]',
    ${CExperience.limitations} TEXT NOT NULL DEFAULT '[]',
    ${CExperience.styles}      TEXT NOT NULL DEFAULT '[]',
    ${CExperience.updatedAt}   INTEGER NOT NULL,
    ${CSync.cloudId}           TEXT,
    ${CSync.cloudUpdatedAt}    INTEGER,
    ${CSync.cloudDeletedAt}    INTEGER
  )
  ''',

  '''
  CREATE TABLE ${T.schedule} (
    ${CSchedule.userId}         INTEGER PRIMARY KEY REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CSchedule.days}           TEXT NOT NULL DEFAULT '[]',
    ${CSchedule.sessionMinutes} INTEGER,
    ${CSchedule.updatedAt}      INTEGER NOT NULL,
    ${CSync.cloudId}            TEXT,
    ${CSync.cloudUpdatedAt}     INTEGER,
    ${CSync.cloudDeletedAt}     INTEGER
  )
  ''',

  '''
  CREATE TABLE ${T.notificationPrefs} (
    ${CNotificationPrefs.userId}           INTEGER PRIMARY KEY REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CNotificationPrefs.workoutReminders} INTEGER NOT NULL DEFAULT 1,
    ${CNotificationPrefs.streakWarnings}   INTEGER NOT NULL DEFAULT 1,
    ${CNotificationPrefs.weeklyReports}    INTEGER NOT NULL DEFAULT 1,
    ${CSync.cloudId}                       TEXT,
    ${CSync.cloudUpdatedAt}                INTEGER,
    ${CSync.cloudDeletedAt}                INTEGER
  )
  ''',

  '''
  CREATE TABLE ${T.playerClass} (
    ${CPlayerClass.userId}           INTEGER PRIMARY KEY REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CPlayerClass.classKey}         TEXT NOT NULL,
    ${CPlayerClass.assignedAt}       INTEGER NOT NULL,
    ${CPlayerClass.lastChangedAt}    INTEGER NOT NULL,
    ${CPlayerClass.evolutionHistory} TEXT NOT NULL DEFAULT '[]',
    ${CSync.cloudId}                 TEXT,
    ${CSync.cloudUpdatedAt}          INTEGER,
    ${CSync.cloudDeletedAt}          INTEGER
  )
  ''',

  // ───────── Exercise catalog ─────────
  '''
  CREATE TABLE ${T.exercises} (
    ${CExercise.id}               INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CExercise.name}             TEXT NOT NULL UNIQUE,
    ${CExercise.primaryMuscle}    TEXT NOT NULL,
    ${CExercise.secondaryMuscles} TEXT NOT NULL DEFAULT '[]',
    ${CExercise.equipment}        TEXT NOT NULL DEFAULT '[]',
    ${CExercise.baseXp}           INTEGER NOT NULL DEFAULT 3,
    ${CExercise.demoVideoUrl}     TEXT,
    ${CExercise.cueText}          TEXT
  )
  ''',
  'CREATE INDEX idx_exercises_primary_muscle ON ${T.exercises}(${CExercise.primaryMuscle})',

  // ───────── Workouts + sets ─────────
  '''
  CREATE TABLE ${T.workouts} (
    ${CWorkout.id}         INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CWorkout.userId}     INTEGER NOT NULL REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CWorkout.startedAt}  INTEGER NOT NULL,
    ${CWorkout.endedAt}    INTEGER,
    ${CWorkout.xpEarned}   INTEGER NOT NULL DEFAULT 0,
    ${CWorkout.volumeKg}   REAL    NOT NULL DEFAULT 0,
    ${CWorkout.note}       TEXT,
    ${CSync.cloudId}       TEXT,
    ${CSync.cloudUpdatedAt}  INTEGER,
    ${CSync.cloudDeletedAt}  INTEGER
  )
  ''',
  'CREATE INDEX idx_workouts_user_started ON ${T.workouts}(${CWorkout.userId}, ${CWorkout.startedAt} DESC)',

  '''
  CREATE TABLE ${T.sets} (
    ${CSet.id}          INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CSet.workoutId}   INTEGER NOT NULL REFERENCES ${T.workouts}(${CWorkout.id}) ON DELETE CASCADE,
    ${CSet.exerciseId}  INTEGER NOT NULL REFERENCES ${T.exercises}(${CExercise.id}),
    ${CSet.setNumber}   INTEGER NOT NULL,
    ${CSet.weightKg}    REAL,
    ${CSet.reps}        INTEGER NOT NULL,
    ${CSet.rpe}         INTEGER,
    ${CSet.isPr}        INTEGER NOT NULL DEFAULT 0,
    ${CSet.xpEarned}    INTEGER NOT NULL DEFAULT 0,
    ${CSet.completedAt} INTEGER NOT NULL,
    ${CSync.cloudId}        TEXT,
    ${CSync.cloudUpdatedAt} INTEGER,
    ${CSync.cloudDeletedAt} INTEGER
  )
  ''',
  'CREATE INDEX idx_sets_workout ON ${T.sets}(${CSet.workoutId})',
  'CREATE INDEX idx_sets_exercise ON ${T.sets}(${CSet.exerciseId})',

  '''
  CREATE TABLE ${T.workoutOverrides} (
    ${CWorkoutOverride.id}             INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CWorkoutOverride.userId}         INTEGER NOT NULL REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CWorkoutOverride.scheduledFor}   INTEGER NOT NULL,
    ${CWorkoutOverride.overridesJson}  TEXT NOT NULL,
    ${CWorkoutOverride.createdAt}      INTEGER NOT NULL
  )
  ''',

  '''
  CREATE TABLE ${T.exerciseSwaps} (
    ${CExerciseSwap.id}                 INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CExerciseSwap.userId}             INTEGER NOT NULL REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CExerciseSwap.originalExerciseId} INTEGER NOT NULL REFERENCES ${T.exercises}(${CExercise.id}),
    ${CExerciseSwap.swappedToId}        INTEGER NOT NULL REFERENCES ${T.exercises}(${CExercise.id}),
    ${CExerciseSwap.workoutId}          INTEGER REFERENCES ${T.workouts}(${CWorkout.id}) ON DELETE SET NULL,
    ${CExerciseSwap.reason}             TEXT,
    ${CExerciseSwap.createdAt}          INTEGER NOT NULL
  )
  ''',

  // ───────── Progression ─────────
  '''
  CREATE TABLE ${T.muscleRanks} (
    ${CMuscleRank.userId}    INTEGER NOT NULL REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CMuscleRank.muscle}    TEXT NOT NULL,
    ${CMuscleRank.rank}      TEXT NOT NULL,
    ${CMuscleRank.subRank}   TEXT,
    ${CMuscleRank.rankXp}    INTEGER NOT NULL DEFAULT 0,
    ${CMuscleRank.updatedAt} INTEGER NOT NULL,
    ${CSync.cloudId}         TEXT,
    ${CSync.cloudUpdatedAt}  INTEGER,
    ${CSync.cloudDeletedAt}  INTEGER,
    PRIMARY KEY (${CMuscleRank.userId}, ${CMuscleRank.muscle})
  )
  ''',

  '''
  CREATE TABLE ${T.quests} (
    ${CQuest.id}          INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CQuest.userId}      INTEGER NOT NULL REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CQuest.type}        TEXT NOT NULL,
    ${CQuest.title}       TEXT NOT NULL,
    ${CQuest.description} TEXT,
    ${CQuest.target}      INTEGER NOT NULL,
    ${CQuest.progress}    INTEGER NOT NULL DEFAULT 0,
    ${CQuest.xpReward}    INTEGER NOT NULL,
    ${CQuest.issuedAt}    INTEGER NOT NULL,
    ${CQuest.expiresAt}   INTEGER,
    ${CQuest.completedAt} INTEGER,
    ${CQuest.locked}      INTEGER NOT NULL DEFAULT 0,
    ${CSync.cloudId}        TEXT,
    ${CSync.cloudUpdatedAt} INTEGER,
    ${CSync.cloudDeletedAt} INTEGER
  )
  ''',
  'CREATE INDEX idx_quests_user_type_active ON ${T.quests}(${CQuest.userId}, ${CQuest.type}, ${CQuest.completedAt}, ${CQuest.expiresAt})',

  '''
  CREATE TABLE ${T.streaks} (
    ${CStreak.userId}              INTEGER PRIMARY KEY REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CStreak.current}             INTEGER NOT NULL DEFAULT 0,
    ${CStreak.longest}             INTEGER NOT NULL DEFAULT 0,
    ${CStreak.lastActiveDate}      INTEGER,
    ${CStreak.freezesRemaining}    INTEGER NOT NULL DEFAULT 1,
    ${CStreak.freezesPeriodStart}  INTEGER NOT NULL,
    ${CSync.cloudId}               TEXT,
    ${CSync.cloudUpdatedAt}        INTEGER,
    ${CSync.cloudDeletedAt}        INTEGER
  )
  ''',

  '''
  CREATE TABLE ${T.streakFreezeEvents} (
    ${CStreakFreezeEvent.id}     INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CStreakFreezeEvent.userId} INTEGER NOT NULL REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CStreakFreezeEvent.usedOn} INTEGER NOT NULL,
    ${CStreakFreezeEvent.reason} TEXT,
    ${CSync.cloudId}             TEXT,
    ${CSync.cloudUpdatedAt}      INTEGER,
    ${CSync.cloudDeletedAt}      INTEGER
  )
  ''',

  // ───────── Body metrics ─────────
  '''
  CREATE TABLE ${T.weightLogs} (
    ${CWeightLog.id}        INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CWeightLog.userId}    INTEGER NOT NULL REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CWeightLog.loggedOn}  INTEGER NOT NULL,
    ${CWeightLog.weightKg}  REAL NOT NULL,
    ${CWeightLog.note}      TEXT,
    ${CSync.cloudId}        TEXT,
    ${CSync.cloudUpdatedAt} INTEGER,
    ${CSync.cloudDeletedAt} INTEGER,
    UNIQUE (${CWeightLog.userId}, ${CWeightLog.loggedOn})
  )
  ''',
  'CREATE INDEX idx_weight_logs_user_date ON ${T.weightLogs}(${CWeightLog.userId}, ${CWeightLog.loggedOn} DESC)',

  // ───────── Subscription ─────────
  '''
  CREATE TABLE ${T.subscriptions} (
    ${CSubscription.userId}          INTEGER PRIMARY KEY REFERENCES ${T.player}(${CPlayer.id}) ON DELETE CASCADE,
    ${CSubscription.tier}            TEXT NOT NULL DEFAULT 'free',
    ${CSubscription.status}          TEXT NOT NULL DEFAULT 'inactive',
    ${CSubscription.purchasedAt}     INTEGER,
    ${CSubscription.renewsAt}        INTEGER,
    ${CSubscription.receiptData}     TEXT,
    ${CSubscription.lastVerifiedAt}  INTEGER,
    ${CSubscription.updatedAt}       INTEGER NOT NULL
  )
  ''',

  // ───────── Offline outbox ─────────
  '''
  CREATE TABLE ${T.analyticsEvents} (
    ${CAnalyticsEvent.id}          INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CAnalyticsEvent.name}        TEXT NOT NULL,
    ${CAnalyticsEvent.payloadJson} TEXT NOT NULL,
    ${CAnalyticsEvent.createdAt}   INTEGER NOT NULL,
    ${CAnalyticsEvent.uploadedAt}  INTEGER
  )
  ''',
  'CREATE INDEX idx_analytics_pending ON ${T.analyticsEvents}(${CAnalyticsEvent.uploadedAt}) WHERE ${CAnalyticsEvent.uploadedAt} IS NULL',

  '''
  CREATE TABLE ${T.crashReports} (
    ${CCrashReport.id}          INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CCrashReport.createdAt}   INTEGER NOT NULL,
    ${CCrashReport.payloadJson} TEXT NOT NULL,
    ${CCrashReport.uploadedAt}  INTEGER
  )
  ''',

  // ───────── Schema bookkeeping ─────────
  '''
  CREATE TABLE ${T.schemaVersion} (
    ${CSchemaVersion.version}   INTEGER PRIMARY KEY,
    ${CSchemaVersion.appliedAt} INTEGER NOT NULL,
    ${CSchemaVersion.note}      TEXT
  )
  ''',

  // ───────── Scope B sync (v2) ─────────
  // Pending-push queue. Drained by SyncEngine in FIFO order. Rows are
  // pruned after successful push acknowledgement. See
  // socials_plan.md §3 (S3) + §1.2 sync model.
  '''
  CREATE TABLE ${T.syncOutbox} (
    ${CSyncOutbox.id}            INTEGER PRIMARY KEY AUTOINCREMENT,
    ${CSyncOutbox.tableName}     TEXT NOT NULL,
    ${CSyncOutbox.localRowId}    INTEGER NOT NULL,
    ${CSyncOutbox.cloudId}       TEXT NOT NULL,
    ${CSyncOutbox.opType}        TEXT NOT NULL CHECK (${CSyncOutbox.opType} IN ('upsert', 'delete')),
    ${CSyncOutbox.payloadJson}   TEXT,
    ${CSyncOutbox.createdAt}     INTEGER NOT NULL,
    ${CSyncOutbox.attemptCount}  INTEGER NOT NULL DEFAULT 0,
    ${CSyncOutbox.lastAttemptAt} INTEGER,
    ${CSyncOutbox.lastError}     TEXT,
    ${CSyncOutbox.pushedAt}      INTEGER
  )
  ''',
  // Fast lookup for the drainer: pending rows ordered by creation.
  'CREATE INDEX idx_sync_outbox_pending ON ${T.syncOutbox}(${CSyncOutbox.createdAt}) WHERE ${CSyncOutbox.pushedAt} IS NULL',
  // Fast prune of acked rows.
  'CREATE INDEX idx_sync_outbox_pushed ON ${T.syncOutbox}(${CSyncOutbox.pushedAt}) WHERE ${CSyncOutbox.pushedAt} IS NOT NULL',

  // Singleton sync-state row. Always exactly one row, id = 1.
  '''
  CREATE TABLE ${T.syncState} (
    ${CSyncState.id}                 INTEGER PRIMARY KEY CHECK (${CSyncState.id} = 1),
    ${CSyncState.lastFullSyncAt}     INTEGER,
    ${CSyncState.initialSyncTable}   TEXT,
    ${CSyncState.initialSyncOffset}  INTEGER NOT NULL DEFAULT 0,
    ${CSyncState.lastOutboxDrainAt}  INTEGER
  )
  ''',
  // Seed the singleton row so SyncEngine can blindly UPDATE without
  // worrying about INSERT-or-UPDATE branching.
  'INSERT INTO ${T.syncState} (${CSyncState.id}) VALUES (1)',
];
