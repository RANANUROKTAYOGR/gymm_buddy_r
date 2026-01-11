# GymBuddy AR - Database Architecture

## Overview
GymBuddy AR uses **SQLite** with **Sqflite** package for local data storage. The database follows **Clean Architecture** principles with 10 tables and proper foreign key relationships.

---

## Database Schema (10 Tables)

### 1. **USER** 👤
Primary table for user accounts.

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| name | TEXT | NOT NULL |
| email | TEXT | NOT NULL, UNIQUE |
| created_at | TEXT | NOT NULL (ISO8601) |

**Relations:**
- One-to-Many with `WORKOUT_SESSION`
- One-to-Many with `BODY_MEASUREMENTS`
- One-to-Many with `USER_GOALS`

---

### 2. **GYM_BRANCH** 🏢
Gym locations/branches information.

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| name | TEXT | NOT NULL |
| address | TEXT | NOT NULL |
| city | TEXT | |
| phone | TEXT | |
| email | TEXT | |
| latitude | REAL | |
| longitude | REAL | |
| working_hours | TEXT | |
| is_active | INTEGER | NOT NULL, DEFAULT 1 |
| created_at | TEXT | NOT NULL (ISO8601) |

**Relations:**
- One-to-Many with `EQUIPMENT`

---

### 3. **EQUIPMENT** 🏋️
Gym equipment catalog with AR support.

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| gym_branch_id | INTEGER | FK → GYM_BRANCH(id) ON DELETE CASCADE |
| name | TEXT | NOT NULL |
| type | TEXT | (Cardio, Strength, Free Weight, etc.) |
| brand | TEXT | |
| model | TEXT | |
| qr_code | TEXT | For AR scanning |
| description | TEXT | |
| is_available | INTEGER | NOT NULL, DEFAULT 1 |
| last_maintenance_date | TEXT | (ISO8601) |
| created_at | TEXT | NOT NULL (ISO8601) |

**Relations:**
- Many-to-One with `GYM_BRANCH`

---

### 4. **EXERCISE** 💪
Exercise definitions and metadata.

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| name | TEXT | NOT NULL |
| description | TEXT | |
| muscle_group | TEXT | (Chest, Back, Legs, etc.) |
| equipment | TEXT | (Barbell, Dumbbell, etc.) |
| created_at | TEXT | NOT NULL (ISO8601) |

**Relations:**
- One-to-Many with `EXERCISE_LOG`
- One-to-Many with `EXERCISE_IMAGES`

---

### 5. **WORKOUT_SESSION** 📅
User workout sessions/training logs.

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| user_id | INTEGER | FK → USER(id) ON DELETE CASCADE |
| start_time | TEXT | NOT NULL (ISO8601) |
| end_time | TEXT | NOT NULL (ISO8601) |
| session_type | TEXT | |
| total_duration | INTEGER | NOT NULL (seconds) |
| created_at | TEXT | NOT NULL (ISO8601) |

**Relations:**
- Many-to-One with `USER`
- One-to-Many with `EXERCISE_LOG`

---

### 6. **EXERCISE_LOG** 📝
Individual exercises performed in a workout session.

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| workout_session_id | INTEGER | FK → WORKOUT_SESSION(id) ON DELETE CASCADE |
| exercise_id | INTEGER | FK → EXERCISE(id) ON DELETE CASCADE |
| order_in_session | INTEGER | NOT NULL |
| created_at | TEXT | NOT NULL (ISO8601) |

**Relations:**
- Many-to-One with `WORKOUT_SESSION`
- Many-to-One with `EXERCISE`
- One-to-Many with `SET_DETAILS`

---

### 7. **SET_DETAILS** 📊
Individual sets within an exercise (reps, weight, etc.).

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| exercise_log_id | INTEGER | FK → EXERCISE_LOG(id) ON DELETE CASCADE |
| set_number | INTEGER | NOT NULL |
| weight | REAL | (kg) |
| reps | INTEGER | |
| created_at | TEXT | NOT NULL (ISO8601) |

**Relations:**
- Many-to-One with `EXERCISE_LOG`

---

### 8. **BODY_MEASUREMENTS** 📏
User body measurements tracking.

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| user_id | INTEGER | FK → USER(id) ON DELETE CASCADE |
| measurement_date | TEXT | NOT NULL (ISO8601) |
| weight | REAL | (kg) |
| height | REAL | (cm) |
| body_fat_percentage | REAL | |
| muscle_mass | REAL | (kg) |
| bmi | REAL | |
| chest | REAL | (cm) |
| waist | REAL | (cm) |
| hips | REAL | (cm) |
| biceps | REAL | (cm) |
| thighs | REAL | (cm) |
| calves | REAL | (cm) |
| notes | TEXT | |
| created_at | TEXT | NOT NULL (ISO8601) |

**Relations:**
- Many-to-One with `USER`

---

### 9. **USER_GOALS** 🎯
User fitness goals and progress tracking.

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| user_id | INTEGER | FK → USER(id) ON DELETE CASCADE |
| goal_type | TEXT | NOT NULL (Weight Loss, Muscle Gain, etc.) |
| target_metric | TEXT | (weight, body_fat, muscle_mass, etc.) |
| current_value | REAL | |
| target_value | REAL | |
| target_date | TEXT | (ISO8601) |
| description | TEXT | |
| status | TEXT | NOT NULL, DEFAULT 'active' |
| progress | REAL | DEFAULT 0.0 (percentage 0-100) |
| created_at | TEXT | NOT NULL (ISO8601) |
| completed_at | TEXT | (ISO8601) |

**Relations:**
- Many-to-One with `USER`

---

### 10. **EXERCISE_IMAGES** 🖼️
Images/media for exercises (AR markers, demos, etc.).

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT |
| exercise_id | INTEGER | FK → EXERCISE(id) ON DELETE CASCADE |
| image_url | TEXT | NOT NULL (local path or URL) |
| image_type | TEXT | (thumbnail, step1, demo, ar_marker, etc.) |
| order_index | INTEGER | |
| caption | TEXT | |
| is_primary | INTEGER | NOT NULL, DEFAULT 0 |
| created_at | TEXT | NOT NULL (ISO8601) |

**Relations:**
- Many-to-One with `EXERCISE`

---

## Entity Relationship Diagram (ERD)

```
USER (1) ─────┬───────── (M) WORKOUT_SESSION
              │
              ├───────── (M) BODY_MEASUREMENTS
              │
              └───────── (M) USER_GOALS

GYM_BRANCH (1) ───────── (M) EQUIPMENT

EXERCISE (1) ─────┬────── (M) EXERCISE_LOG
                  │
                  └────── (M) EXERCISE_IMAGES

WORKOUT_SESSION (1) ───── (M) EXERCISE_LOG

EXERCISE_LOG (1) ────────── (M) SET_DETAILS
```

---

## Foreign Key Relationships

### CASCADE DELETE Rules:
All foreign keys use `ON DELETE CASCADE` to maintain referential integrity:

1. **USER deleted** → All related `workout_sessions`, `body_measurements`, and `user_goals` are deleted
2. **GYM_BRANCH deleted** → All related `equipment` is deleted
3. **EXERCISE deleted** → All related `exercise_logs` and `exercise_images` are deleted
4. **WORKOUT_SESSION deleted** → All related `exercise_logs` are deleted
5. **EXERCISE_LOG deleted** → All related `set_details` are deleted

---

## CRUD Operations

### All tables support full CRUD:
- ✅ **Create**: `create{TableName}()`
- ✅ **Read**: `get{TableName}()`, `getAll{TableName}()`
- ✅ **Update**: `update{TableName}()`
- ✅ **Delete**: `delete{TableName}()`

### Special Query Methods:
- `getEquipmentByBranch(branchId)` - Equipment by gym location
- `getEquipmentByQRCode(qrCode)` - AR scanning support
- `getBodyMeasurementsByUser(userId)` - User measurement history
- `getLatestBodyMeasurement(userId)` - Latest measurement
- `getActiveGoalsByUser(userId)` - Active goals only
- `getImagesByExercise(exerciseId)` - All exercise images
- `getPrimaryImageByExercise(exerciseId)` - Main exercise image
- `getExerciseLogsBySession(sessionId)` - Exercises in workout
- `getSetDetailsByLog(logId)` - Sets in exercise log

---

## Model Classes

All models include:
- ✅ **fromMap()** - Convert SQLite Map to Object
- ✅ **toMap()** - Convert Object to SQLite Map
- ✅ **copyWith()** - Immutable update support (Extension method)
- ✅ **toString()** - Debug-friendly representation

---

## Database Versioning

- **Version 1**: Initial schema (5 tables)
- **Version 2**: Added 5 new tables (GYM_BRANCH, EQUIPMENT, BODY_MEASUREMENTS, USER_GOALS, EXERCISE_IMAGES)

Database migrations are handled automatically via `onUpgrade` callback.

---

## Usage Example

```dart
// Initialize database
final db = DatabaseHelper.instance;

// Create user
final user = await db.createUser(User(
  name: 'John Doe',
  email: 'john@example.com',
  createdAt: DateTime.now(),
));

// Add body measurement
final measurement = await db.createBodyMeasurement(BodyMeasurements(
  userId: user.id!,
  measurementDate: DateTime.now(),
  weight: 75.5,
  height: 180.0,
  createdAt: DateTime.now(),
));

// Create goal
final goal = await db.createUserGoal(UserGoals(
  userId: user.id!,
  goalType: 'Weight Loss',
  targetMetric: 'weight',
  currentValue: 75.5,
  targetValue: 70.0,
  targetDate: DateTime.now().add(Duration(days: 90)),
  description: 'Lose 5kg in 3 months',
  createdAt: DateTime.now(),
));

// Scan equipment with QR code
final equipment = await db.getEquipmentByQRCode('QR123456');

// Get user's workout history
final sessions = await db.getWorkoutSessionsByUser(user.id!);

// Get latest measurement
final latest = await db.getLatestBodyMeasurement(user.id!);
```

---

## File Structure

```
lib/
  data/
    models/
      user.dart
      gym_branch.dart
      equipment.dart
      exercise.dart
      workout_session.dart
      exercise_log.dart
      set_details.dart
      body_measurements.dart
      user_goals.dart
      exercise_images.dart
    models.dart (exports all models)
    database/
      database_helper.dart
```

---

## Technologies

- **SQLite** - Local database
- **Sqflite** ^2.4.2 - Flutter SQLite plugin
- **Path** ^1.9.1 - File path utilities
- **Clean Architecture** - Separation of concerns
- **Foreign Keys** - Referential integrity
- **Cascade Delete** - Data consistency

---

## Notes

- All dates stored as ISO8601 strings
- Boolean values stored as INTEGER (0/1)
- All models are immutable with copyWith support
- Sample data automatically inserted on first run
- Database automatically created on app launch
- Foreign key constraints enforced at database level

---

**Last Updated**: December 30, 2025
**Database Version**: 2
**Total Tables**: 10
**Total Relationships**: 10
