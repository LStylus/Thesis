# Voice Voyage: gameplay reset and architecture study

Status: architecture preparation only. All 15 new games are **unimplemented**.
Prepared from the supplied gameplay-reset brief on 2026-09-05.

## 1. Audit and removal decision

Before editing, the audit found eight template mechanics behind one Flame scene:
Bucket Sort, Tap and Pop, Minimal Pair, Echo Cave, Sound Builder, Sequence Jumper,
Voice-Powered Journey, and Sound Meter Challenge. A template enum, level config,
gameplay-specific personalization engine, session controller/flow, scene mapper,
HUD and result panel supported them. The home page was the only external game
entry point and saved the returned legacy level score.

The working tree already contained 19 asset deletions: the ocean-classroom PNG,
whale SVG, and all 17 adventure SVGs. Those deletions are user work, not new
deletions by this reset. No additional asset was deleted. Git history still
contains the removed tracked code and assets; no history rewrite or destructive
Git command is part of this change.

Removal plan announced before editing:

1. Remove the eight mechanics, old scenes/configuration/session flow and their
   implementation-specific tests.
2. Preserve recording, assessment, screening, personalization inputs, reporting,
   saved data, content sources, reusable assets, and generic visual utilities.
3. Detach map navigation from game completion; introduce only a neutral notice,
   stage/design metadata, an explicit configuration handoff, and this study.
4. Run analysis and the complete test suite; check removed references and scope.

### Removed

- `lib/features/game/application/game_session_{controller,flow,scene_mapper,state}.dart`:
  old recording/progression orchestration and template-dependent state.
- `lib/features/game/domain/game_{level_config,personalization_engine,result,template_kind}.dart`:
  obsolete template selection, repetition/threshold rules, and level-index result.
  The app's assessment scores, report models and persistence APIs are preserved.
- `lib/features/game/presentation/game_screen.dart` and its HUD/result widgets:
  old game route and UI.
- `lib/gamescene/game_scene.dart`, `game_scene_state.dart`, template mechanics,
  background/explorer components and score animation: old environment, mechanics
  and dependencies on the deleted adventure art.
- Old scene, session-controller and gameplay-personalization test files. They
  test a deliberately retired runtime, not the recording or assessment services.
- Home's temporary returned-game score cache/write call; persisted report streams,
  historical completion display, profile selection and map layout remain.
- Home's old microphone warm-up. Map/notice navigation no longer prepares a
  recorder or requests microphone permission; screening's recording is unchanged.

### Preserved or adapted

- Authentication, Firebase configuration, profiles, screening, recording service,
  phoneme API/assessment/scoring, module service/store, speech-profile models,
  learning reports and home-controller persistence APIs are unchanged.
- `game_services.dart`: existing prompt-audio, recording and assessment adapters.
  Their API limitations are recorded below, not silently changed in this reset.
- Four generic visuals moved to `lib/game/core/`: microphone visualizer,
  feedback particles, progress pill, speech bubble. They accept display values
  or explicit feedback calls instead of depending on an obsolete scene/session.
  The microphone image is borrowed from the future scene's asset cache; this
  visual does not create a recorder, load a game, or own the image's lifetime.
- `GameTarget`: shared speech content; old answer-option/piece fields removed.
  Optional target sound, sound position and content-unit metadata added.
- `LearningModuleTargets`: retains all source items once, in source order, with
  sound/position/unit metadata. Removes the old rotating level slice. No stage,
  repetition or difficulty is selected. IDs include the source module ID.
- `GameTargetCatalog`: retains the legacy CSV inventory and image/audio links;
  makes its cached list immutable and retains target-sound metadata.
- Existing fonts, icons, profiles, map, word pictures and audio retained. The
  missing adventure directory is removed from the bundle declaration. Existing
  nested audio directories are explicitly bundled; no audio is generated.
- Auth/loading references to user-deleted artwork now use the existing home-map
  SVG and child-explorer SVG. This is a limited artwork repair, not an auth change.
- Flame and Flame SVG dependencies retained; no dependency added or upgraded.

### Current navigation

Existing accessible map nodes open `GameplayUnavailablePage`, which says
“New gameplay system coming next.” and offers a return to the map. It has no
game scene, recorder, scoring call, result payload or progress write. The map's
legacy four-level display is historical infrastructure, **not** five-stage
progress or an integration of the 15 new games. Existing lock/unlock display
continues to read historical reports; redesigning it is a separate phase.

## 2. Shared design contract

| Stage | Purpose | Meaningful progression requirement |
|---|---|---|
| 1 — Listen | Hear words and notice sounds | Required auditory exposures; no microphone gate |
| 2 — Recognize | Identify familiar words/sounds | Correct choices/matches; no microphone gate |
| 3 — Guided Say | Produce with model and visual support | Accepted speech after the guided setup |
| 4 — Independent Say | Retrieve and produce independently | Accepted speech; no correct model immediately before the attempt |
| 5 — Use in Context | Communicate using practiced sounds | Accepted target-aware speech in an authored context |

Stage and language complexity are different axes. The backend's syllable, word,
phrase and sentence groups must never be treated as stage indices. A child can
enter Guided Say directly when a future selection policy supports it. Age alone
must not impose a start stage, nor should a new session force previous stages.

All touch actions from stage 3 onward prepare a speech turn or animate an already
accepted outcome. Dragging, uncovering, tapping, timeouts and animation completion
must not bypass the speech gate. Failed, silent, invalid, cancelled or unavailable
assessment is not accepted speech. A skipped item is a skip, not mastery.

Shared child-experience policy for later implementation:

- Short, calm rounds; large touch targets; replay and pause controls; clear focus.
- Encourage effort immediately; do not shame errors or remove lives/stars.
- Repeat the same unresolved target after an error; distinguish recognition,
  speech, audio and network problems. Do not punish an outage as poor speech.
- Ages 4–5: full visual support, slow motion, simple instructions and generous
  timing. Ages 6–8: reduced hints, richer vocabulary/phrases and longer authored
  sequences only when suitable. Preserve the brief's fixed image/round counts;
  vary visual support instead of silently changing those rules.
- Optional small stars/stickers and celebrations; no public ranking, violence,
  endless retries, time pressure or unrestricted conversations.
- An accessibility tap/select alternative can replace a drag or precise motor
  action, but cannot replace required speech. Pause moving scenes during speech.
- Supported/guided/independent assistance must be recorded separately. If a correct
  model is requested during an independent activity, mark the next attempt as
  supported; do not count it as evidence of independent production.

## 3. Study of all 15 designs

The events and components below are **proposals**, not Dart APIs or implemented
mechanics. In each design, Flame reports interaction intents; the future Flutter
session owner validates them and authorizes progression. No raw score is inferred
from an animation. “Accepted” means the future explicit speech policy accepts the
assessment evidence; this study deliberately specifies no universal threshold.

### 1. Picture Listen — unimplemented

1. **Purpose:** Connect three familiar images with their spoken words.
2. **Stage:** Listen.
3. **Child interaction:** Tap each of three pictures; the picture reacts and its
   audio plays. Completion requires all three unique pictures, not three taps on
   one picture. Proposed exposure rule: acknowledge each completed playback.
4. **Speech requirement:** None; never request microphone permission here.
5. **Inputs/configuration:** Three distinct target IDs, image and word-audio
   assets, labels, cue options, repeat/pause settings.
6. **Outputs/events:** Picture selected, playback requested/finished/failed,
   target exposed, all required exposures complete. Replays do not add progress.
7. **Flutter:** Audio queue, exposed-ID set, completion decision, instructions,
   accessible alternatives, lifecycle/pause handling.
8. **Flame:** Image layout, hit targets, subtle bounce/glow and exposure marks.
9. **Controllers/services:** Future shared session/exposure controller and
   completion-aware prompt player; no recorder or assessor.
10. **Sharing:** Image presentation, audio/exposure tracking with games 3, 4 and 9.
11. **Potential components:** Custom image-target and exposure-marker components;
    existing feedback/progress visuals; Flutter semantic image buttons.
12. **Risks:** Rapid taps overlapping audio; crediting muted/failed playback;
    an expressive picture unintentionally confusing the word. Retry failed audio
    without counting it; replay freely without lost progress.
13. **Later assets:** Three or more reusable vocabulary images, matching clean
    model clips, gentle tap feedback, optional neutral background and stickers.
14. **Personalized content:** Receive a selected three-target subset through
    GameConfig; selection happens outside the scene, based on sound and familiarity.

### 2. Sound Emphasis — unimplemented

1. **Purpose:** Make the relevant sound and its position easier to notice.
2. **Stage:** Listen.
3. **Child interaction:** Start/replay an emphasized word; follow a synchronized
   highlight at the initial, medial or final sound. Required presentations should
   finish before completion; repetition count remains a future configuration.
4. **Speech requirement:** None.
5. **Inputs/configuration:** Word, target sound/position, reviewed emphasized
   audio, timing markers, visual sound span, required exposure count.
6. **Outputs/events:** Playback/cue started, position highlighted, exposure
   completed, replay requested or playback failed.
7. **Flutter:** Ordered audio/timing source, accessible instructions, exposure
   accounting and pause/resume. Completion is not tied to decorative pulses.
8. **Flame:** Word/image emphasis and synchronized visual markers.
9. **Controllers/services:** Shared exposure controller, prompt player and
   a timing adapter; no recording/assessment dependency.
10. **Sharing:** Model playback with games 1/3/7/8/9; word/prompt display everywhere.
11. **Potential components:** Custom sound-span highlight; existing speech bubble;
    Flutter text semantics. Audio timeline supplies timing, not a guessed timer.
12. **Risks:** Letter indices are not phoneme indices; positions can be ambiguous.
    A stop sound such as /k/ should use reviewed repetition instead of an invented
    sustained clip. Missing timing data must not show false synchronization.
13. **Later assets:** Standard and emphasized clips per target/position, reviewed
    timing metadata, image assets and simple emphasis effects.
14. **Personalized content:** Selected target sound and position come from module
    metadata; a content resolver must supply a compatible audio/visual rendition.

### 3. Falling Sound Bubbles — unimplemented

1. **Purpose:** Repeat auditory exposure through a playful pop interaction.
2. **Stage:** Listen.
3. **Child interaction:** Pop required image bubbles, see their pictures react,
   hear their words. Missed bubbles return without penalty.
4. **Speech requirement:** None.
5. **Inputs/configuration:** Target images/audio, required exposure occurrences,
   slow fall speed, active-bubble cap, spawn region and reduced-motion option.
6. **Outputs/events:** Bubble selected, word playback complete, occurrence exposed,
   bubble missed/rescheduled and required set complete.
7. **Flutter:** Required-occurrence identity, audio serialization, pause and
   accessible stationary alternative; prevent duplicate completion events.
8. **Flame:** Falling motion, bubble bounds/hit testing, pop animation and recycling.
9. **Controllers/services:** Shared exposure/session controller and prompt audio.
10. **Sharing:** Image/audio loop with game 1; bubble presentation with 6/9/12,
    but recognition and speech progression rules are not shared by accident.
11. **Potential components:** Custom reusable image bubble and bubble field;
    existing feedback particles. Profile first before adding object pooling.
12. **Risks:** Motor speed masking learning, excessive objects, audio overlap,
    repeated callbacks crediting one pop twice. Slow/pause/reoffer bubbles;
    unsuccessful playback leaves the exposure pending, not a lost life.
13. **Later assets:** Bubble shell, pop frames/effect, vocabulary pictures, word
    audio, quiet background; no need for an asset per bubble occurrence.
14. **Personalized content:** Selected targets plus exposure repetitions arrive
    from a future config builder; the scene never queries a child profile.

### 4. Find the Word — unimplemented

1. **Purpose:** Recognize previously heard words from spoken instructions.
2. **Stage:** Recognize.
3. **Child interaction:** Hear “Which one is the key?” and select among four
   images; complete two correct rounds. Wrong selections keep the round open.
4. **Speech requirement:** None.
5. **Inputs/configuration:** Two round definitions, four choices each, one answer
   ID, spoken prompts, known exposure/familiarity data and a shuffle seed.
6. **Outputs/events:** Choice selected, correct/incorrect recognition, prompt
   replayed, round accepted and two-round completion.
7. **Flutter:** Answer validation, round counter, prompt playback, repeat controls,
   semantic choice labels without exposing the answer.
8. **Flame:** Four image targets, neutral idle movement and chosen-image feedback.
9. **Controllers/services:** Shared recognition/session controller, content
   validator, exposure-history reader and prompt audio; no speech APIs.
10. **Sharing:** Four-choice board with game 5; image targets with game 1.
11. **Potential components:** Custom choice board and selection highlight;
    shared image-target/progress/feedback components.
12. **Risks:** Duplicate or ambiguous images, random layout hints, unseen targets,
    counting wrong/repeated taps as new rounds. Replay and retry without penalty.
13. **Later assets:** Vocabulary images and question clips/templates, neutral
    selection states and encouraging feedback audio.
14. **Personalized content:** Use words introduced in Listen. A future direct-entry
    policy needs evidence of familiarity or a supported introduction; the scene
    must not assume an old level index proves exposure.

### 5. Find the Sound — unimplemented

1. **Purpose:** Recognize a target phoneme at the requested word position.
2. **Stage:** Recognize.
3. **Child interaction:** Choose one of four images for a sound/position prompt;
   complete two correct rounds. Subtle idle motion must not reveal the answer.
4. **Speech requirement:** None.
5. **Inputs/configuration:** Target phoneme, initial/medial/final position,
   four reviewed alternatives, answer ID, two rounds and prompt audio.
6. **Outputs/events:** Choice/position response, correct or incorrect recognition,
   prompt replay, round completion and activity completion.
7. **Flutter:** Phoneme-position answer keys, two-round accounting, replay and
   accessible explanation; do not derive sound positions from first/last letters.
8. **Flame:** Shared choice board, equal idle effects, answer feedback.
9. **Controllers/services:** Recognition/session controller, validated phoneme
   content source and prompt audio; no microphone/ASR.
10. **Sharing:** Game 4's board and retry handling; game 2's target-position metadata.
11. **Potential components:** Custom choice board, sound-position cue and existing
    progress/feedback visuals.
12. **Risks:** Multiple valid answers, spelling-based matching, difficult terms for
    younger children. Review distractors; offer a repeatable simple explanation
    on retry without auto-awarding a correct round.
13. **Later assets:** Familiar object images, sound/position instruction clips,
    optional beginning/middle/end cue illustrations and neutral idle frames.
14. **Personalized content:** Weak phoneme/error position determines content
    compatibility; use exposed words where possible. Selection remains external.

### 6. Sound Bucket — unimplemented

1. **Purpose:** Match a heard word to its visual/name representation.
2. **Stage:** Recognize.
3. **Child interaction:** Hear a random sound bubble, drag it into one of four
   image/name buckets; a correct bucket fills and locks. Complete three bubbles
   assigned to three distinct buckets; the fourth remains a distractor.
4. **Speech requirement:** None.
5. **Inputs/configuration:** Four bucket target IDs/images/labels, audio for at
   least three distinct matches, constrained order seed and drop-zone settings.
6. **Outputs/events:** Drop attempted, match accepted/rejected, bucket locked,
   bubble reoffered and three accepted placements complete.
7. **Flutter:** Matching, locked-bucket IDs, solvable selection from unfilled
   targets, three-placement counter, audio and accessible select-then-place UI.
8. **Flame:** Bubble drag, drop-zone detection, snapback, fill/lock animation.
9. **Controllers/services:** Recognition/session controller, prompt player and
   content validator. Randomization cannot select an already locked answer.
10. **Sharing:** Bubble visuals with 3/9/12; target images/audio across stages.
11. **Potential components:** Custom sound bubble, bucket/drop zone, lock indicator;
    Flame DragCallbacks and bounds/hit-testing utilities already used by the app.
12. **Risks:** Unsolvable random sequences, double drop credit, drag precision.
    Reject locked/wrong buckets, return the bubble and allow replay without loss.
13. **Later assets:** Empty/filled/locked bucket art, bubble shell, word images,
    labels rendered as text, model clips and gentle matching effects.
14. **Personalized content:** Receive four compatible known targets and a
    three-target required subset; target selection is not scene randomness.

### 7. Build & Say — unimplemented

1. **Purpose:** Transition from supported word construction to speech production.
2. **Stage:** Guided Say.
3. **Child interaction:** Complete a word from pieces, hear its model, then speak.
   Building only unlocks the speaking turn; it cannot complete the target.
4. **Speech requirement:** An accepted pronunciation is mandatory after building.
5. **Inputs/configuration:** Word/assessment target, reviewed pieces/answer layout,
   image, correct model clip, cues, recording settings and future acceptance policy.
6. **Outputs/events:** Piece selected, construction valid, model finished,
   recording requested, attempt assessed, accepted or retry, target complete.
7. **Flutter:** Construction validation, prompt-before-record sequencing, recording,
   assessment, retry assistance and speech-only completion authorization.
8. **Flame:** Piece interaction, assembled display and feedback for accepted speech.
9. **Controllers/services:** Shared speech-turn/session controller, GameRecorder,
   GameAssessmentClient, prompt player and reviewed construction configuration.
10. **Sharing:** The same speech turn as 8/9; piece placement visuals can later
    serve 6/12 without sharing their completion criteria.
11. **Potential components:** Custom letter/sound piece and assembly slot; shared
    speech bubble, microphone, image target and progress components.
12. **Risks:** Literacy difficulty obscuring speech; phonemes not mapping one-to-one
    to letters; recording model audio. Keep assembled word on speech retry and
    wait for actual model completion before opening the microphone.
13. **Later assets:** Clear word images, piece/slot skins, model word clips,
    support prompts, encouragement and small success effects.
14. **Personalized content:** Config supplies target sound/word and reviewed
    construction recipe plus support settings. Neither pieces nor age select stage.

### 8. Guided Training Path — unimplemented

1. **Purpose:** Make guided speech produce visible forward movement.
2. **Stage:** Guided Say.
3. **Child interaction:** At each obstacle, see a picture, hear the word, speak;
   only an accepted attempt lets the character pass the obstacle.
4. **Speech requirement:** Required for each obstacle's meaningful progress.
5. **Inputs/configuration:** Short ordered target/obstacle sequence, model clips,
   support cues, movement presentation settings and acceptance policy.
6. **Outputs/events:** Obstacle reached, model finished, attempt assessed,
   passage authorized, animation finished and required path complete.
7. **Flutter:** Speech turns, current target/obstacle identity, retries, pause and
   completion; keep world animation separate from accepted-attempt evidence.
8. **Flame:** Character movement, rocks/water/gates/tunnels and safe passing motion.
9. **Controllers/services:** Shared speech-turn/session owner, prompt player,
   recorder and assessment adapter; a small future path presentation adapter.
10. **Sharing:** Speech orchestration with 7/9; movement/character visuals with
    10/12/15, not a universal obstacle-mechanic framework.
11. **Potential components:** Custom path marker, obstacle and animated character;
    shared microphone, prompt, progress and particles.
12. **Risks:** Tap or animation advancing without speech, lengthy waits, animation
    callbacks after navigation. Pause at obstacles; retry the same target and
    ignore stale callbacks. No character injury or falling punishment.
13. **Later assets:** Friendly character idle/pass states, short path scenery,
    obstacle art, word cards/model clips and supportive prompts.
14. **Personalized content:** External config supplies target sequence, assistance
    and repetitions; path length is presentation of that plan, not a selector.

### 9. Listen, Pop & Repeat — unimplemented

1. **Purpose:** Reuse a familiar pop/listen action while adding required speech.
2. **Stage:** Guided Say.
3. **Child interaction:** Pop a picture bubble, hear its word and “Your turn,”
   then pronounce it. The pop itself is not target completion.
4. **Speech requirement:** Accepted speech for each required target occurrence.
5. **Inputs/configuration:** Image bubbles, model and turn-cue audio, required
   targets/repetitions, motion settings and speech policy.
6. **Outputs/events:** Pop intent, model/turn cue finished, recording/assessment,
   accepted target, retry requested and required speech set complete.
7. **Flutter:** Latch one active target, serialize audio then recording, count only
   accepted speech, manage retry and pause. Preserve the picture during recording.
8. **Flame:** Pop/reaction, highlight active target, pause other bubbles during
   the speech turn, animate completion only after authorization.
9. **Controllers/services:** Shared speech-turn/session owner, audio, recording
   and assessment adapters.
10. **Sharing:** Game 3's bubble view and game 7's speech turn; no second audio or
    recording stack and no reuse of Listen's exposure completion as speech success.
11. **Potential components:** Custom image bubble/active-target card; retained
    microphone/progress/feedback visuals.
12. **Risks:** Disappearing prompt, double taps changing target mid-recording,
    accidentally inheriting no-speech completion. Retry the latched target with
    replay support; missing/failed assessment never counts as a successful pop.
13. **Later assets:** Reuse bubble/picture/pop art, word models, “Your turn” audio,
    recording cue and optional small success sticker.
14. **Personalized content:** Config selects targets and repetitions from the
    shared content pool, independently of bubble spawn/layout decisions.

### 10. Forest Discovery — unimplemented

1. **Purpose:** Retrieve and name an item without hearing its model first.
2. **Stage:** Independent Say.
3. **Child interaction:** Remove leaves, stone, bush or log over a subtle glow;
   name the revealed item after “What did you find?” Complete three hidden items.
4. **Speech requirement:** Accepted independent speech for all three items;
   uncovering does not count. Do not play the correct pronunciation beforehand.
5. **Inputs/configuration:** Three target images/assessment entries, hiding places,
   neutral question prompt, reveal order and independent-support policy.
6. **Outputs/events:** Cover removed, target revealed, neutral cue finished,
   attempt assessed, discovery accepted and three-item completion.
7. **Flutter:** No-model speech policy, question audio, recording/assessment,
   accepted-ID set, hints and supported-attempt labeling.
8. **Flame:** Forest navigation, subtle glows, removable covers and reveal effects.
9. **Controllers/services:** Shared speech-turn/session owner, neutral audio,
   recorder and assessment; scene receives no unrestricted model-play callback.
10. **Sharing:** Image reveal/selection and character presentation with other games;
    independent speech policy with 11/12.
11. **Potential components:** Custom hiding spot, removable cover and glow;
    shared image target/microphone/progress.
12. **Risks:** Auto-speaking an image label, inaccessible hidden targets, cover
    removal awarding completion. Retry the revealed item; provide an explicit
    support path without labeling modeled speech as independent.
13. **Later assets:** Forest layers, four cover types, glow, three or more item
    images, neutral question audio, discovery effect and optional explorer states.
14. **Personalized content:** Select recognizable target images for the intended
    weak sound/position; config provides targets, not scripted scene-owned words.

### 11. Silly Monster — unimplemented

1. **Purpose:** Encourage independently correcting a deliberately silly word.
2. **Stage:** Independent Say.
3. **Child interaction:** See KEY, hear the monster's reviewed “TEY,” and say KEY;
   accepted corrections change silly → calming → happy friend. No combat.
4. **Speech requirement:** Accepted correct speech; the intentionally incorrect
   example is allowed, but the correct model must not precede the attempt.
5. **Inputs/configuration:** Target/image, approved wrong-example clip and its
   error annotation, intended correct assessment target, transformation milestones.
6. **Outputs/events:** Wrong example played, correction attempted/assessed,
   friendship milestone authorized, state animated and encounter complete.
7. **Flutter:** Separate wrong example from expected answer, independent speech
   turn, accepted-attempt counter, help/retry policy and safe content validation.
8. **Flame:** Expressive silly/calming/happy character reactions and friendship
   effects; never interpret a pose change as assessment success.
9. **Controllers/services:** Shared speech-turn/session owner, curated contrast
   content, audio, recorder and assessor of the correct target only.
10. **Sharing:** Independent speech policy with 10/12; character states and
    feedback with 8/13/15.
11. **Potential components:** Custom character-state view, image prompt and
    friendship indicator; existing particles/microphone/prompt.
12. **Risks:** Reinforcing an error through repetition, frightening/shaming children,
    rewarding imitation of the wrong example. Use reviewed short clips, neutral
    retries and an exit/help option; do not automatically replay errors repeatedly.
13. **Later assets:** Friendly monster's three states/transitions, word images,
    approved wrong pronunciations, neutral correction cues, friendship celebration.
14. **Personalized content:** A future selector supplies an approved target/error
    pair compatible with the profile. Never generate arbitrary mispronunciations
    or infer the correct assessment word from the wrong-example clip name.

### 12. Build the Bridge — unimplemented

1. **Purpose:** Show speech directly building a safe path for a friendly animal.
2. **Stage:** Independent Say.
3. **Child interaction:** Select/attend to a word bubble and say its word;
   acceptance pops the bubble and adds one bridge piece. Once all targets are
   accepted, the puppy/kitten crosses safely and the activity completes.
4. **Speech requirement:** One authorized piece per required accepted target;
   no correct model immediately before the attempt.
5. **Inputs/configuration:** Required word/image targets, target-to-piece mapping,
   animal choice, neutral cues and speech policy. Count supplied later.
6. **Outputs/events:** Target selected, attempt assessed, piece authorized/placed,
   bridge completed, safe crossing finished and activity complete.
7. **Flutter:** Accepted target IDs, piece accounting, independent speech turns,
   idempotent completion and recovery from interrupted crossing animation.
8. **Flame:** Word bubbles, bridge construction and animal's safe crossing.
9. **Controllers/services:** Shared speech-turn/session owner, audio/recorder/
   assessment adapters and a small bridge presentation adapter.
10. **Sharing:** Bubble/image views with 3/9; independent speech with 10/11;
    character/route animation with 8.
11. **Potential components:** Custom bridge piece, animal view and word bubble;
    shared progress/microphone/feedback.
12. **Risks:** Double assessment response adding two pieces; tap-to-pop bypass;
    frightening broken-bridge stakes. Animal waits safely on shore; retries do
    not remove pieces, and accepted target IDs prevent duplicate rewards.
13. **Later assets:** Animal idle/walk/happy states, bridge endpoints/pieces,
    calm water/shore, bubble art, word images and supportive neutral prompts.
14. **Personalized content:** Config supplies required targets/repetitions;
    world construction visualizes that plan without deciding speech difficulty.

### 13. Talk With Buddy — unimplemented

1. **Purpose:** Use practiced sounds in a controlled word-to-sentence conversation.
2. **Stage:** Use in Context.
3. **Child interaction:** Answer authored Buddy turns about an image, expanding
   from “Cat” to its color/location in sentences. No unrestricted AI dialogue.
4. **Speech requirement:** Each required conversational turn needs accepted,
   relevant speech containing the configured target skill.
5. **Inputs/configuration:** Bounded dialogue graph, picture/context, expected
   intents, allowed response variants, target sounds, length/support settings,
   and explicit end conditions.
6. **Outputs/events:** Turn prompted, response recorded, pronunciation evidence,
   content relevance result, accepted turn/retry and conversation complete.
7. **Flutter:** Dialogue state, authored branching, speech orchestration,
   accessibility, response-policy evaluation and session persistence.
8. **Flame:** Buddy listening/talking/happy states and a quiet context illustration.
9. **Controllers/services:** Shared speech-turn owner, a future bounded dialogue
   controller and content-policy evaluator alongside existing assessment/recording.
   Current forced-alignment scoring alone cannot prove semantic relevance.
10. **Sharing:** Bounded-turn infrastructure with 14/15; all speech/media services.
11. **Potential components:** Custom Buddy character/context view; Flutter dialog
    overlay and semantic prompt; shared microphone/feedback/progress.
12. **Risks:** Accepting an irrelevant fluent response, forcing one exact sentence,
    unsafe free chat, logging child utterances. Use reviewed response sets and
    content-aware validation; on retry give a contextual cue without auto-passing.
13. **Later assets:** Buddy states, context pictures, recorded dialogue prompts,
    hint cards, turn indicators and gentle celebration.
14. **Personalized content:** Config builder binds approved dialogue slots to
    target sounds/words and appropriate phrase lengths, with no in-scene API calls.

### 14. Mission Roleplay — unimplemented

1. **Purpose:** Practice functional communication in familiar situations.
2. **Stage:** Use in Context.
3. **Child interaction:** Speak to request a carrot in a store, describe bag
   contents at school, or report a discovery to the captain.
4. **Speech requirement:** Mission progression requires a relevant spoken request
   or report using the configured target skill, not just selecting an item.
5. **Inputs/configuration:** Approved scenario, mission steps, roles/context,
   target phrases/sounds, acceptable intent/response variants and hints.
6. **Outputs/events:** Mission/turn started, response assessed, communicative
   intent accepted/retried, step fulfilled and mission complete.
7. **Flutter:** Authored mission/dialogue state, content relevance and speech
   validation, accessible instruction/hint overlay, pause and session outputs.
8. **Flame:** Shop/school/explorer staging, NPC reactions and visible fulfillment
   only after accepted communication.
9. **Controllers/services:** Bounded-turn/mission controller, speech-turn owner,
   audio, recorder, assessor and future content-policy evaluator.
10. **Sharing:** Game 13's controlled dialogue/response validation and game 15's
    contextual scene transitions; no separate conversation backend per game.
11. **Potential components:** Custom NPC and context prop; shared character view,
    microphone/progress and Flutter mission prompt/hint card.
12. **Risks:** Scoring only a target noun while ignoring the request, rigid scripts,
    irrelevant complex props. Accept approved natural variants; retry with a
    simple contextual cue and keep earned steps without automatic completion.
13. **Later assets:** Store/school/explorer backdrops, friendly NPCs, carrot/bag/
    discovery props, authored mission/question clips and completion sticker.
14. **Personalized content:** Bind the child's target words into reviewed mission
    slots and choose supported response complexity externally; never arbitrary chat.

### 15. Story Adventure — unimplemented

1. **Purpose:** Generalize practiced sounds into increasingly meaningful narration.
2. **Stage:** Use in Context.
3. **Child interaction:** Answer story-beat prompts: identify a key, say “Get the
   key,” explain “The character found the key,” and later give a short narrative.
4. **Speech requirement:** Each required beat progresses only through accepted
   target-aware speech; tapping Next cannot satisfy the narrative task.
5. **Inputs/configuration:** Reviewed story graph, target-bound beats, word → phrase
   → sentence → short-narrative tasks, approved response/intent policy and cues.
6. **Outputs/events:** Beat shown, utterance assessed, content evidence evaluated,
   beat authorized, transition finished and story/session complete.
7. **Flutter:** Bounded story/turn state, progression and response validation,
   save/resume policy, accessibility and complete-versus-partial results.
8. **Flame:** Scene layers, character movement, chest/key actions and authored
   transitions, all driven by authorized beat state.
9. **Controllers/services:** Shared bounded-turn and speech-turn owners, authored
   story configuration, audio/recorder/assessment and contextual response evaluator.
10. **Sharing:** Turn validation with 13/14; character, environment and transition
    presentation with 8/10/12. Avoid a general-purpose narrative engine initially.
11. **Potential components:** Custom story-scene/prop view and character states;
    Flutter narrative prompt overlay; shared microphone and progress.
12. **Risks:** Scope growth, long attention demands, fabricated narrative assessment,
    lost progress after interruptions. Start with one short linear story, preserve
    accepted beats, allow pause and support retries without bypassing speech.
13. **Later assets:** A small coherent scene set, Buddy/explorer states, chest/key
    and target props, authored question clips, transitions and ending illustration.
14. **Personalized content:** Future config builder binds targets to compatible
    reviewed story beats and response complexity. It must not generate unlimited
    plots or assume current word scoring supports free narratives.

## 4. Architecture: present foundation versus future work

```text
lib/
  features/game/
    domain/
      game_stage.dart                # NOW: five stages and speech requirement
      game_definition.dart           # NOW: 15 IDs/titles/stage associations only
      game_config.dart               # NOW: explicit design, child context, targets
      game_target.dart               # NOW: equivalent of SpeechTarget
      game_target_catalog.dart       # RETAINED: legacy inventory; validate before use
      learning_module_targets.dart   # ADAPTED: lossless source-order content mapping
    application/
      game_services.dart             # RETAINED: audio/recording/assessment adapters
      session / speech-turn owners   # FUTURE: create with first real vertical slice
    presentation/
      gameplay_unavailable_page.dart # NOW: navigation notice, no gameplay
      game host / semantic overlays  # FUTURE: no routes to the new games yet
  game/
    core/                            # NOW: four detached reusable visuals
    listen/                          # FUTURE: do not create empty scene skeletons
    recognize/                       # FUTURE
    guided_say/                      # FUTURE
    independent_say/                 # FUTURE
    use_in_context/                  # FUTURE
  services/                          # PRESERVED: device, API, Firebase persistence
  models/                            # PRESERVED: profile, module, report, assessment
```

The new GameDefinition is a design catalog, not a game factory or availability
registry. There are no scene constructors, unlock rules or completed-game claims.
GameConfig snapshots the supplied target list; it intentionally does not select
content, validate a game's round counts or implement repetition/hint policies.
Add game-specific configuration only with the first implementation that needs it.

### Minimal concepts and later seams

| Concept | Current equivalent / future decision |
|---|---|
| GameStage | Five-stage enum with explicit number, title and required-speech metadata |
| GameDefinition | Fifteen stable design IDs/titles and one stage each; no runtime factory |
| GameConfig | Immutable selected definition, child ID/age, immutable target list |
| SpeechTarget | Existing GameTarget with prompt, assessment reference, assets, sound/position/unit |
| GameContent | Current target list plus existing module; future reviewed per-game payloads only when needed |
| GameSession | Documented future single Flutter-owned session; no unused state machine added |
| GameResult | Future typed completion/partial/cancelled result with target/attempt evidence and schema version; no legacy level-index result reused |

Future ownership/data direction:

```text
profile + screening + module + performance evidence
        → future external selection/config builder
        → immutable GameConfig + reviewed activity-specific content
        → Flutter session owner ↔ audio / recorder / assessor
        → read-only visual state → Flame rendering
        ← target/interaction intents ← Flame input
        → versioned learning result → existing persistence boundary
```

Keep recording state, acceptance and completion authoritative in Flutter. Flame
can hold ephemeral positions, particle ages and drag state, not Firebase records,
ASR clients or progression truth. Flutter overlays own semantic controls, parent
dialogs, privacy notices and motor-accessible alternatives. Use the existing
ChangeNotifier/Provider convention initially; no state-management migration.

### Shared systems to build once, incrementally

| System | Reuse / important boundary |
|---|---|
| Target/content resolution | Existing module+catalog; future validation of images, audio, phoneme/position, distractors and scenario compatibility |
| Prompt playback | Retained adapter; future await-completion, stop/cancel, failure outcome and timing markers |
| Speech turn | One controller for prompt/cue → ready → recording → assessing → accepted/retry/error; stages 1–2 never enter it |
| Attempt identity | Future session/target/attempt IDs; ignore duplicate or stale callbacks and responses after disposal |
| Recording lifecycle | Reuse GameRecorder/AudioRecordingService; one owner cancels/disposes stream subscriptions and recordings |
| Assessment/feedback | Reuse GameAssessmentClient/PhonemeAssessmentService; separate API failure, invalid audio and pronunciation feedback |
| Exposure/recognition tracking | Small stage-appropriate counters/sets; never fabricate speech accuracy for listening/touch tasks |
| Image/word views | Shared visual building blocks plus semantic Flutter equivalents; add only when implementing games 1/4 |
| Mic/prompt/progress/particles | Four retained presentation-only Flame utilities, no dependencies on retired game state |
| Character/scene presentation | Reuse rendering/state transitions where real games share them; no giant switch over all mechanics |
| Contextual turn evaluation | Later games 13–15 share bounded scripts and reviewed response/intent validation, separate from pronunciation evidence |
| Results/persistence | Existing store/report service boundaries retained; later schema adapter distinguishes exposure, recognition, supported production, independent production and context |

### Prerequisites and risks not implemented in this phase

1. **Audio correctness:** The retained prompt adapter's Future finishes when
   playback starts, not when the clip ends; it currently swallows playback errors.
   Before any Listen/Guided game, add explicit finished/cancelled/failed outcomes
   and asset-path normalization (`assets/...` versus AssetSource-relative paths),
   test no overlapping prompts, and never credit silent failure as exposure.
2. **Content suitability:** Legacy CSV phrase/sentence rows can show a phrase
   while audio and assessment still refer to one word; syllable rows can pair a
   word image/audio with a syllable prompt. Retained inventory is not approved
   curriculum. Validate/re-author pairings, sound positions and emphasis timings.
   Dynamic module items currently have no image/model-audio mapping; resolve
   those explicitly. Verify API coverage for phrases/sentences before use.
3. **Speech acceptance:** Specify evidence and assistance policy with the product
   team before coding progression. Do not transplant retired percentage thresholds
   or treat every successful HTTP response as accepted pronunciation.
4. **Async lifecycle:** Future owners must stop prompts and recording on pause,
   route exit, interruption and target change; cancel subscriptions and ignore
   late assessment responses. Do not start a second attempt while processing.
5. **Context assessment:** Existing phoneme scores are not a conversation/intent
   evaluator. Start with reviewed bounded response variants and explicit product
   acceptance rules; confirm backend capabilities before promising narratives.
6. **Personalization:** Preserve age, screening result, weak phoneme, error pattern,
   position, current stage and prior performance as inputs. A future selector
   returns target skill, start stage, compatible design, words, difficulty, hints
   and repetition. No such rules or selector implementation were added here.
7. **Persistence migration:** Keep old reports readable and distinguish legacy
   activity/level IDs from new design/stage IDs. Do not overwrite or backfill
   existing progress in this reset. Design a versioned result adapter and consented
   migration before integrating new map progression; store no raw child audio by
   default and avoid logging utterances/profile data.
8. **Accessibility/performance:** Provide reduced motion and semantic controls;
   cap simultaneous moving objects and pause them during speech. Measure before
   pooling/caching abstractions. Existing visuals can be optimized later if
   profiling warrants it; moving them here is reuse, not a performance claim.

## 5. Safest future implementation order

Each step should be a small tested vertical slice, not fifteen stubs at once.

1. **Foundation plus Listen:** Finish prompt completion/cancellation and content
   validation; implement Picture Listen first. Prove three unique completed
   exposures, replay/failure handling and no recorder creation. Then Sound
   Emphasis with reviewed timing, followed by Falling Sound Bubbles with capped
   motion and no-loss replay. Add only shared pieces justified by these games.
2. **Recognize:** Find the Word, then Find the Sound on the shared four-choice
   board, then Sound Bucket. Test two-correct-round rules, sound positions,
   solvable three-of-four bucket sets, locking, wrong-drop retry and duplicate
   input. Preserve exposure/familiarity provenance.
3. **Guided Say:** Build & Say first establishes the shared speech turn. Test that
   building alone cannot finish, actual audio completion precedes recording, and
   failed/late assessments cannot advance. Extend to Guided Training Path, then
   Listen, Pop & Repeat using the proven bubble renderer and speech owner.
4. **Independent Say:** Forest Discovery first proves no correct model before
   speech and three accepted discoveries. Next Build the Bridge proves one piece
   per accepted target and safe final crossing. Add Silly Monster after approving
   its wrong-example content and non-shaming friendship presentation.
5. **Use in Context:** Talk With Buddy with one short controlled conversation,
   then one Mission Roleplay scenario, then one linear Story Adventure. Prove
   pronunciation plus communicative intent, allowed variants, bounded branching,
   supported retries and interrupted-session recovery before expanding content.
6. **Integration only after validation:** Add selector rules, availability and map
   progression with versioned persistence, safe legacy-data handling and end-to-end
   device tests. This is future work, not authorized implementation in this phase.

## 6. Validation record

Baseline: analyzer reported one missing `assets/game/adventure/` directory warning.
The existing test suite reported 43 passing tests, with missing-asset-directory
output and existing plugin/binding diagnostic logs. A stale bundle could hide
deleted assets, so the updated asset test checks both disk and bundle contents.

Final validation on Flutter 3.35.6 / Dart 3.9.2:

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | All 38 tests passed |
| Baseline comparison | 43 baseline tests minus 14 retired-runtime tests plus 9 new tests = 38; retained module/asset tests updated |
| Documentation completeness | Exactly 15 uniquely numbered designs; all 14 required study fields per design |
| Removed-reference search | No retired scene/template/controller or deleted-asset references in `lib/` or `test/` |
| Preservation check | No diff in services, controllers, app data models, screening, or the retained game service adapters |
| Asset scope | Only the 19 deletions present before this task; no new asset deletions |

The home navigation test passes with a non-failing SVG loader diagnostic about an
unsupported `filter` element in retained artwork. The artwork was not rewritten.
The local Flutter SDK resolves its own transitive test-package pins; the original
`pubspec.lock` is restored after validation so no dependency change is delivered.

New tests cover the exact 15 IDs, three designs per stage, speech-requirement
metadata, explicit direct-stage configuration, immutable target handoff, retained
module metadata, asset availability, detached visual rendering, notice navigation
and loading animation disposal. An actual HomePage test also verifies map → notice
→ map navigation, zero score writes, and preserved historical score values.
Metadata tests do not claim future speech gates
are implemented. Existing auth/profile/module/assessment tests remain in scope.

Device microphone permissions, live ASR endpoints, Firebase writes, actual child
usability, all new gameplay, and data migration require later integration testing;
this reset neither exercises remote services nor changes saved user data.
