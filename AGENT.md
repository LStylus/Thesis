# AGENT.md

Guidance for working in the **Voice Voyage** Flutter app (this repository).
The app pairs with the backend monorepo at `../VoiceVoyageServices` —
see its `AGENT.md`/`CLAUDE.md` for the services.

## Project Overview

**Voice Voyage** — a Flutter speech-sound screening and phonics-learning app
(thesis project). Children record words through the microphone; audio is
sent to the backend phoneme service for forced-alignment analysis
(phonological processes, PCC, scores), and a second backend service builds
personalized practice modules from the detected errors. Supports ages 4–8.

Two backend services (each its own process/port):

| Service | Port | Job |
|---|---|---|
| Phoneme service (`../VoiceVoyageServices/phoneme_service`) | 8001 | WAV → phoneme scores, detected processes |
| Dynamic modules service (`../VoiceVoyageServices/dynamic_modules_service`) | 8002 | age + detected processes → practice module |

## Commands

```bash
# Run on Windows
flutter run -d windows

# Run all tests
flutter test

# Run a single test
flutter test test/phoneme_assessment_service_test.dart

# Analyze for lint issues
flutter analyze

# Clean and rebuild
flutter clean && flutter pub get
```

## Project Structure

### Architecture Pattern
Controllers (ChangeNotifier) hold mutable state and expose methods; views
listen via Provider/Consumer. Services encapsulate Firebase, HTTP, and
device API calls. Models are plain Dart classes with `toMap()`/`fromMap()`
for Firestore serialization.

**Data flow:** View → Controller → Service → External (Firebase / backend API)

### Key Directories

| Directory | Purpose |
|---|---|
| `lib/controllers/` | ChangeNotifier state managers: AuthController, HomeController, ScreeningController |
| `lib/models/` | Data models: AppUserModel, ProfileModel, ScreeningWordModel, LearningModuleModel, LearningReportModel, SignupDraftModel |
| `lib/services/` | Firebase auth (AuthService), Firestore CRUD (UserService), audio recording (AudioRecordingService), phoneme API client (PhonemeAssessmentService), modules API client (DynamicModulesService) |
| `lib/features/` | Feature-first modules: `screening/` (application controllers), `game/` (domain config, application flows, presentation) |
| `lib/views/` | Screens grouped by feature: `auth/`, `home/`, `screening/` |
| `lib/widgets/` | Shared reusable widgets |
| `lib/core/constants/` | Design tokens + `TestingDefaults` (word limit, test credentials) |
| `lib/core/theme/` | AppTheme with Material 3 theme, Fredoka/Matemasie fonts |

### Two Main Flows

**1. Screening** (`lib/views/screening/` + `lib/features/screening/`):
- Parent signs up → child info (birth date → age) → screening session
  (record words) → phoneme service assesses each word →
  `ScreeningResultsController` batches results →
  **then requests a personalized practice module** from the modules service
  (age + all detected processes) → stored as `learningModule`
- `ScreeningController` (ChangeNotifier) is created per-session with the
  child's age; words resolved via `ScreeningWordModel.resolveForAge(age)`

**2. Gameplay** (`lib/features/game/`):
- Ocean-map level-based learning; 4 levels per island: Bubble Bay
  (syllables), Coral Cargo (single words), Reef Route (short phrases),
  Captain's Call (full sentences) — see `domain/game_level_config.dart`
- Records → assesses via the phoneme service → saves scores to Firestore
  learning report (`GameSessionController`, `game_session_flow.dart`)

### State Management
- Provider + ChangeNotifier via `MultiProvider` in `main.dart`
- `AuthController` (auth state + signup flow)
- `HomeController` (profile streams + gameplay score saving)
- `ScreeningController` (per-session, created in-line via `ChangeNotifierProvider`)
- `ScreeningResultsController` (batch assessment + learning module request)
- `GameSessionController` (per-level recording/assessment, retry logic)

### Firebase Schema
- `users/{userId}` — parent account (role, child profile IDs, active profile, learning report data)
- `users/{userId}/children/{profileId}` — child profiles with learning reports
- `profiles/{profileId}` — legacy flat profile collection
- Auth: email/password only

## Backend Integration

### Phoneme service (`PhonemeAssessmentService` → port 8001)
- Sends 16kHz mono WAV recordings to `POST {baseUrl}/assess` as multipart form
- Fields: `word` (lowercase display word) + `age` (child age) + `file` (WAV)
- Returns `overall_score`, `expected_ipa`, `detected_ipa`,
  `assessment.detected_processes[]`, `pcc`, `passed`, …
- Default base URL: `http://127.0.0.1:8001` (Android emulator: `http://10.0.2.2:8001`)
- Override via `PhonemeAssessmentService(baseUrl: '...')`
- 3 retries with exponential backoff + jitter; errors parsed from the body

### Dynamic modules service (`DynamicModulesService` → port 8002)
- `POST {baseUrl}/module` with form fields `age` + `processes` (JSON array
  of `{process, position, detail}` — the target phoneme is derived from the
  `detail` string on the backend, e.g. `/s/ -> [t]`)
- Returns the practice module: `module_id`, `focus_sounds`,
  `focus_processes`, `outline_id/title`, `levels` (syllable → word → phrase
  → sentence items with `text`/`target_sound`/`position`), `rationale`,
  `generated_by` (`llm` | `rule-based`), optional `warning`
- Parsed into `LearningModuleModel` (`lib/models/learning_module_model.dart`)
- Default base URL: `http://127.0.0.1:8002` (Android emulator: `http://10.0.2.2:8002`)

## Audio Recording
- 16kHz, mono, WAV format, 3-second auto-record duration
- Temp file stored via `path_provider`, validated for WAV header (`RIFF`/`WAVE`)
- File cleaned up on exit/cancel

## Age-based Word Lists
- `ScreeningWordModel` has static lists per age group (4, 5, 6–7, 8)
- Word IDs follow `{word}_{age}` (optionally `_{phoneme-group}`, e.g.
  `pig_age4`, `sun_age4_pbmn`) — the position segment was removed; IDs are
  used as map keys and must stay unique
- `TestingDefaults.screeningWordsPerAge = 3` limits screening word count;
  set higher or modify `ScreeningController._useTestingWordLimit` for full lists
- `TestingDefaults` also contains test credentials and sample data

## Platform Locking
- Home and Gameplay lock to landscape; Screening and Auth screens lock to portrait
- Orientation resets on dispose via `SystemChrome.setPreferredOrientations`
