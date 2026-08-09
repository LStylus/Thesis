# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Voice Voyage** — A Flutter speech sound screening and phonics learning app built as a thesis project. It records children's speech through a microphone, sends audio to a ML phoneme recognition model (Model-2), and returns phonological process analysis and accuracy scores. Supports ages 4–8.

## Commands

```bash
# Run on Windows
flutter run -d windows

# Run tests
flutter test

# Run a single test
flutter test test/widget_test.dart

# Analyze for lint issues
flutter analyze

# Clean and rebuild
flutter clean && flutter pub get
```

## Project Structure

### Architecture Pattern
Controllers (ChangeNotifier) hold mutable state and expose methods; views listen via Provider/Consumer. Services encapsulate Firebase, HTTP, and device API calls. Models are plain Dart classes with `toMap()`/`fromMap()` for Firestore serialization.

**Data flow:** View → Controller → Service → External (Firebase/ML Model API)

### Key Directories

| Directory | Purpose |
|---|---|
| `lib/controllers/` | ChangeNotifier state managers: AuthController, HomeController, ScreeningController |
| `lib/models/` | Data models: AppUserModel, ProfileModel, ScreeningWordModel, LearningReportModel, SignupDraftModel |
| `lib/services/` | Firebase auth (AuthService), Firestore CRUD (UserService), audio recording (AudioRecordingService), ML model HTTP client (PhonemeAssessmentService) |
| `lib/views/` | Screens grouped by feature: `auth/`, `home/`, `screening/` |
| `lib/screens/` | Top-level screens (currently only `gameplay/gameplay_screen.dart`) |
| `lib/widgets/` | Shared reusable widgets |
| `lib/core/constants/` | Design tokens: colors, fonts, spacing, text styles, asset paths, profile assets |
| `lib/core/theme/` | AppTheme with Material 3 theme, Fredoka/Matemasie fonts |

### Two Main Flows

**1. Screening** (`lib/views/screening/`) — A standalone assessment wizard:
- Parents sign up → child info → screening session (record words) → ML model processes audio → results page with phonological process detection → profile saved to Firestore
- Uses `ScreeningController` (ChangeNotifier) created per-session
- Words resolved by age via `ScreeningWordModel.resolveForAge(age)`

**2. Gameplay/Activities** (`lib/screens/gameplay/`) — Level-based learning:
- Ocean map with flag/chest nodes (4 levels per island)
- Level 0–2: Word-pair tap-and-speak game
- Level 3: Free-speak with instruction audio
- Records → assesses via Model-2 → saves scores to Firestore learning report
- State managed locally in `_GameplayScreenState` (no controller)
- Results passed back via `Navigator.pop(GameplayLevelResult)`

### State Management
- Provider + ChangeNotifier via `MultiProvider` in `main.dart`
- `AuthController` (auth state + signup flow)
- `HomeController` (profile streams + gameplay score saving)
- `ScreeningController` (per-session, created in-line via `ChangeNotifierProvider`)
- Gameplay uses `StatefulWidget` local state

### Firebase Schema
- `users/{userId}` — parent account (role, child profile IDs, active profile, learning report data)
- `users/{userId}/children/{profileId}` — child profiles with learning reports
- `profiles/{profileId}` — legacy flat profile collection
- Auth: email/password only

### Phoneme Model Integration
- Sends 16kHz mono WAV recordings to `POST {baseUrl}/assess` as multipart form
- Fields: `word` (lowercase display word) + `age` (child age in years) + `file` (WAV audio)
- Returns `overall_score`, `expected_ipa`, `detected_ipa`, `assessment.detected_processes[]`
- Default endpoint: `http://127.0.0.1:8001`
- Override via `PhonemeAssessmentService(baseUrl: '...')`

### Audio Recording
- 16kHz, mono, WAV format, 3-second auto-record duration
- Temp file stored via `path_provider`, validated for WAV header (`RIFF`/`WAVE`)
- File cleaned up on exit/cancel

### Age-based Word Lists
- `ScreeningWordModel` has static lists per age group (4, 5, 6–7, 8)
- Words organized by phoneme process and word position (initial/medial/final)
- `TestingDefaults.screeningWordsPerAge = 3` limits screening word count; set higher or modify `ScreeningController._useTestingWordLimit` for full lists
- `TestingDefaults` also contains test credentials and sample data

### Platform Locking
- Home and Gameplay lock to landscape; Screening and Auth screens lock to portrait
- Orientation resets on dispose via `SystemChrome.setPreferredOrientations`
