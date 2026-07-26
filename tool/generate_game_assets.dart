import 'dart:io';

const _root = 'assets/game';

void main() {
  final assets = <String, String>{
    ..._characterAssets(),
    ..._wordAssets(),
    ..._feedbackAssets(),
    ..._bubbleBayAssets(),
    ..._coralCargoAssets(),
    ..._reefRouteAssets(),
    ..._captainsCallAssets(),
  };

  for (final entry in assets.entries) {
    final file = File('$_root/${entry.key}');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(_svg(entry.value));
  }

  stdout.writeln('Generated ${assets.length} SVG game assets.');
}

Map<String, String> _wordAssets() => {
  'words/pig.svg': _pigWordArt(),
  'words/ball.svg': _ballWordArt(),
  'words/10.svg': _tenWordArt(),
  'words/dog.svg': _dogWordArt(),
  'words/key.svg': _keyWordArt(),
  'words/goat.svg': _goatWordArt(),
};

String _pigWordArt() => '''
<path d="M70 83 48 48l45 15M186 83l22-35-45 15" fill="#F4829F" stroke="#A83C5B" stroke-width="7" stroke-linejoin="round"/>
<ellipse cx="128" cy="132" rx="84" ry="78" fill="#FF9DB1" stroke="#A83C5B" stroke-width="7"/>
<path d="M73 91q55-43 110 0" stroke="white" stroke-opacity=".36" stroke-width="11" stroke-linecap="round"/>
<ellipse cx="128" cy="155" rx="43" ry="31" fill="#F46F91" stroke="#A83C5B" stroke-width="6"/>
<ellipse cx="112" cy="155" rx="7" ry="10" fill="#79334B"/><ellipse cx="144" cy="155" rx="7" ry="10" fill="#79334B"/>
<circle cx="96" cy="119" r="9" fill="#49334A"/><circle cx="160" cy="119" r="9" fill="#49334A"/>
<circle cx="93" cy="116" r="3" fill="white"/><circle cx="157" cy="116" r="3" fill="white"/>
<path d="M103 193q25 17 50 0" stroke="#A83C5B" stroke-width="6" stroke-linecap="round"/>
<ellipse cx="72" cy="145" rx="11" ry="6" fill="#FFD0DB"/><ellipse cx="184" cy="145" rx="11" ry="6" fill="#FFD0DB"/>''';

String _ballWordArt() => '''
<circle cx="128" cy="132" r="92" fill="url(#gold)" stroke="#E15D56" stroke-width="8"/>
<path d="M58 78c46 37 94 35 140-2M45 142c58-33 111-31 168 5M81 213c2-67 21-125 60-172M174 210c-10-65-33-120-69-165" stroke="#F06464" stroke-width="18" stroke-linecap="round"/>
<path d="M69 71q43-31 83-11" stroke="white" stroke-opacity=".55" stroke-width="12" stroke-linecap="round"/>
<circle cx="128" cy="132" r="92" stroke="#B8494F" stroke-width="7"/>''';

String _tenWordArt() => '''
<path d="M56 77 91 53v150" stroke="url(#gold)" stroke-width="31" stroke-linecap="round" stroke-linejoin="round"/>
<ellipse cx="166" cy="130" rx="48" ry="76" fill="url(#teal)" stroke="#176F75" stroke-width="8"/>
<ellipse cx="166" cy="130" rx="20" ry="43" fill="#E9FFF8" stroke="#176F75" stroke-width="7"/>
<path d="M48 71 86 45M142 70q25-17 49 0" stroke="white" stroke-opacity=".5" stroke-width="9" stroke-linecap="round"/>
<g fill="url(#coral)" stroke="#A83C5B" stroke-width="3"><path d="m40 191 8 17 19 2-14 13 4 19-17-9-17 9 4-19-14-13 19-2 8-17Z"/><path d="m214 31 6 13 15 2-11 10 3 15-13-7-14 7 3-15-11-10 15-2 7-13Z"/></g>''';

String _dogWordArt() => '''
<path d="M77 95C39 91 23 62 38 40c29 3 52 22 61 50M179 95c38-4 54-33 39-55-29 3-52 22-61 50" fill="#B87845" stroke="#6F452E" stroke-width="8" stroke-linejoin="round"/>
<path d="M57 127c0-53 31-87 71-87s71 34 71 87c0 59-31 91-71 91s-71-32-71-91Z" fill="#D99A5E" stroke="#6F452E" stroke-width="8"/>
<path d="M78 80q50-38 100 0" stroke="#FFE4BC" stroke-opacity=".52" stroke-width="11" stroke-linecap="round"/>
<ellipse cx="128" cy="156" rx="43" ry="35" fill="#FFE4BC"/>
<circle cx="96" cy="121" r="9" fill="#3C302D"/><circle cx="160" cy="121" r="9" fill="#3C302D"/>
<path d="m128 143-14 10 14 12 14-12-14-10Z" fill="#3C302D"/>
<path d="M128 164q-13 20-27 5M128 164q13 20 27 5" stroke="#6F452E" stroke-width="6" stroke-linecap="round"/>
<path d="M114 181q14 24 28 0" fill="#F2839C" stroke="#6F452E" stroke-width="5" stroke-linejoin="round"/>''';

String _keyWordArt() => '''
<circle cx="82" cy="105" r="51" fill="url(#gold)" stroke="#A96B1F" stroke-width="9"/>
<circle cx="82" cy="105" r="21" fill="#E9FCFF" stroke="#A96B1F" stroke-width="8"/>
<path d="m116 142 84 83 27-27-18-18 17-17-21-21-17 17-24-24-48 7Z" fill="url(#gold)" stroke="#A96B1F" stroke-width="9" stroke-linejoin="round"/>
<path d="M51 70q31-27 62-5M137 155l60 59" stroke="white" stroke-opacity=".58" stroke-width="9" stroke-linecap="round"/>
<path d="m182 174 17 17" stroke="#E18A22" stroke-width="6" stroke-linecap="round"/>''';

String _goatWordArt() => '''
<path d="M83 81C54 65 48 38 64 22c26 12 39 31 38 58M173 81c29-16 35-43 19-59-26 12-39 31-38 58" fill="url(#gold)" stroke="#8A6832" stroke-width="7" stroke-linejoin="round"/>
<path d="M75 76 46 61l8 42M181 76l29-15-8 42" fill="#9B7650" stroke="#674B35" stroke-width="7" stroke-linejoin="round"/>
<path d="M60 120c0-50 30-81 68-81s68 31 68 81c0 62-29 99-68 99s-68-37-68-99Z" fill="#F3E6C9" stroke="#765B3F" stroke-width="8"/>
<path d="M82 79q45-34 92 0" stroke="white" stroke-opacity=".7" stroke-width="11" stroke-linecap="round"/>
<ellipse cx="128" cy="158" rx="39" ry="32" fill="#DDBB91"/>
<circle cx="96" cy="119" r="8" fill="#403833"/><circle cx="160" cy="119" r="8" fill="#403833"/>
<path d="M117 153h22l-11 13-11-13Z" fill="#6E5142"/>
<path d="M111 178q17 15 34 0" stroke="#765B3F" stroke-width="6" stroke-linecap="round"/>
<path d="M106 205q22 38 44 0" fill="#E8D3A8" stroke="#765B3F" stroke-width="7" stroke-linejoin="round"/>''';

String _svg(String body) =>
    '''<svg width="256" height="256" viewBox="0 0 256 256" fill="none" xmlns="http://www.w3.org/2000/svg">
<defs>
  <linearGradient id="whale" x1="52" y1="48" x2="184" y2="206" gradientUnits="userSpaceOnUse"><stop stop-color="#55D9FF"/><stop offset="0.58" stop-color="#00BBF9"/><stop offset="1" stop-color="#087EBA"/></linearGradient>
  <linearGradient id="belly" x1="96" y1="118" x2="150" y2="205" gradientUnits="userSpaceOnUse"><stop stop-color="#FFF5F8"/><stop offset="1" stop-color="#F5B7C6"/></linearGradient>
  <linearGradient id="coral" x1="40" y1="40" x2="204" y2="220" gradientUnits="userSpaceOnUse"><stop stop-color="#FF9DB1"/><stop offset="1" stop-color="#E74669"/></linearGradient>
  <linearGradient id="gold" x1="56" y1="42" x2="194" y2="216" gradientUnits="userSpaceOnUse"><stop stop-color="#FFE98A"/><stop offset="0.55" stop-color="#FFC94F"/><stop offset="1" stop-color="#E99724"/></linearGradient>
  <linearGradient id="teal" x1="48" y1="44" x2="204" y2="216" gradientUnits="userSpaceOnUse"><stop stop-color="#69E1D0"/><stop offset="1" stop-color="#139B9D"/></linearGradient>
  <linearGradient id="blue" x1="44" y1="32" x2="206" y2="224" gradientUnits="userSpaceOnUse"><stop stop-color="#B9F5FF"/><stop offset="0.55" stop-color="#58D9F2"/><stop offset="1" stop-color="#2687CF"/></linearGradient>
  <linearGradient id="purple" x1="56" y1="40" x2="196" y2="220" gradientUnits="userSpaceOnUse"><stop stop-color="#C5A5FF"/><stop offset="1" stop-color="#7157C8"/></linearGradient>
  <radialGradient id="glow"><stop stop-color="#FFF9B8"/><stop offset="0.45" stop-color="#FFD85E" stop-opacity=".8"/><stop offset="1" stop-color="#FFD85E" stop-opacity="0"/></radialGradient>
  <radialGradient id="bubble"><stop stop-color="#FFFFFF" stop-opacity=".7"/><stop offset=".45" stop-color="#9CEEFF" stop-opacity=".34"/><stop offset="1" stop-color="#44CBEF" stop-opacity=".16"/></radialGradient>
</defs>
$body
</svg>
''';

Map<String, String> _characterAssets() {
  const moods = [
    'idle',
    'happy',
    'listening',
    'encouraging',
    'thinking',
    'celebrating',
    'speaking',
    'retry',
    'holding_pearl',
  ];
  return {
    for (final mood in moods) 'shared/whale_$mood.svg': _whale(mood),
    'shared/fish_blue.svg': _fish('#55D9FF', '#188CC8', false),
    'shared/fish_yellow.svg': _fish('#FFD75E', '#F18C35', false),
    'shared/turtle_receiver.svg': _turtle(),
    'shared/octopus_receiver.svg': _octopus(),
  };
}

String _whale(String mood) {
  final eye = switch (mood) {
    'happy' || 'celebrating' =>
      '<path d="M88 113q10 10 20 0M151 113q10 10 20 0" stroke="#164D68" stroke-width="5" stroke-linecap="round"/>',
    'listening' =>
      '<circle cx="98" cy="112" r="8" fill="#164D68"/><circle cx="164" cy="108" r="8" fill="#164D68"/><circle cx="95" cy="109" r="2.5" fill="white"/><circle cx="161" cy="105" r="2.5" fill="white"/>',
    'thinking' =>
      '<circle cx="98" cy="113" r="7" fill="#164D68"/><path d="M153 111q9-7 18 0" stroke="#164D68" stroke-width="5" stroke-linecap="round"/>',
    'retry' =>
      '<path d="M88 112q10-8 20 0M151 112q10-8 20 0" stroke="#164D68" stroke-width="5" stroke-linecap="round"/>',
    _ =>
      '<ellipse cx="98" cy="112" rx="7" ry="9" fill="#164D68"/><ellipse cx="164" cy="112" rx="7" ry="9" fill="#164D68"/><circle cx="95" cy="109" r="2.5" fill="white"/><circle cx="161" cy="109" r="2.5" fill="white"/>',
  };
  final mouth = switch (mood) {
    'speaking' =>
      '<ellipse cx="131" cy="150" rx="18" ry="15" fill="#8C2945"/><ellipse cx="131" cy="157" rx="11" ry="5" fill="#F58BA4"/>',
    'retry' =>
      '<path d="M116 154q15-10 30 0" stroke="#8C2945" stroke-width="5" stroke-linecap="round"/>',
    'thinking' => '<circle cx="132" cy="151" r="6" fill="#8C2945"/>',
    _ =>
      '<path d="M111 147q20 22 41 0" stroke="#8C2945" stroke-width="5" stroke-linecap="round"/>',
  };
  final extra = switch (mood) {
    'listening' =>
      '<path d="M190 94q25 17 5 39" stroke="#FFD45E" stroke-width="6" stroke-linecap="round"/><path d="M200 87q37 26 7 57" stroke="#FFD45E" stroke-width="4" stroke-linecap="round" opacity=".7"/>',
    'encouraging' =>
      '<g transform="translate(184 54)"><path d="M0 18L8 8l9 8 13-16 8 8" stroke="#FFD45E" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/><circle cx="39" cy="4" r="5" fill="#FF8CA4"/></g>',
    'thinking' =>
      '<g fill="white" stroke="#6CCFED" stroke-width="3"><circle cx="190" cy="74" r="7"/><circle cx="208" cy="58" r="11"/><circle cx="229" cy="38" r="16"/></g><path d="M220 35h18M229 26v18" stroke="#FFD45E" stroke-width="4" stroke-linecap="round"/>',
    'celebrating' =>
      '<g stroke-linecap="round" stroke-width="5"><path d="M45 48l-8-14" stroke="#FFCC4E"/><path d="M69 37V20" stroke="#FF7394"/><path d="M191 37l8-16" stroke="#65D7A5"/><path d="M214 52l13-11" stroke="#A88AF3"/></g><g fill="#FFD45E"><circle cx="41" cy="65" r="5"/><circle cx="204" cy="67" r="5"/></g>',
    'speaking' =>
      '<g fill="url(#bubble)" stroke="white" stroke-width="2"><circle cx="189" cy="140" r="7"/><circle cx="207" cy="124" r="11"/><circle cx="228" cy="104" r="15"/></g>',
    'retry' =>
      '<path d="M42 72q20-18 38 0" stroke="#FFB65C" stroke-width="7" stroke-linecap="round"/><path d="M39 72l7-15M39 72l16 2" stroke="#FFB65C" stroke-width="5" stroke-linecap="round"/>',
    'holding_pearl' =>
      '<circle cx="199" cy="169" r="38" fill="url(#glow)"/><circle cx="199" cy="169" r="18" fill="#FFF7C2" stroke="#EFB94A" stroke-width="4"/><path d="M169 181q15 13 31 2M229 181q-15 13-31 2" stroke="#087EBA" stroke-width="10" stroke-linecap="round"/>',
    _ => '',
  };
  return '''
<path d="M65 91C45 71 32 61 18 66c9 10 12 23 5 37 18 4 34-2 44-10" fill="url(#whale)" stroke="#087EBA" stroke-width="5" stroke-linejoin="round"/>
<path d="M192 91c20-20 33-30 47-25-9 10-12 23-5 37-18 4-34-2-44-10" fill="url(#whale)" stroke="#087EBA" stroke-width="5" stroke-linejoin="round"/>
<path d="M56 119c0-51 34-80 76-80 49 0 76 31 76 83 0 51-36 91-78 91-43 0-74-39-74-94Z" fill="url(#whale)" stroke="#087EBA" stroke-width="5"/>
<path d="M80 159c12 34 31 50 52 50 23 0 44-19 54-52-28 14-76 14-106 2Z" fill="url(#belly)"/>
<path d="M76 74c25-28 71-32 101-5" stroke="white" stroke-opacity=".34" stroke-width="9" stroke-linecap="round"/>
<path d="M76 154c-21 10-28 27-20 44 14-2 28-10 39-24M181 154c22 10 28 27 20 44-14-2-28-10-39-24" fill="#13A7DC" stroke="#087EBA" stroke-width="5" stroke-linejoin="round"/>
$eye
<ellipse cx="84" cy="135" rx="12" ry="6" fill="#FF8CA4" opacity=".55"/><ellipse cx="178" cy="135" rx="12" ry="6" fill="#FF8CA4" opacity=".55"/>
$mouth
<path d="M122 53q9-18 18 0M116 50q-2-18-13-21M145 50q3-18 14-21" stroke="#8FEAFF" stroke-width="5" stroke-linecap="round"/>
$extra''';
}

String _fish(String body, String fin, bool paused) =>
    '''
<path d="M51 126 17 91v70l34-35Z" fill="$fin" stroke="#176C91" stroke-width="5" stroke-linejoin="round"/>
<path d="M45 126c0-45 42-72 91-72 45 0 78 27 93 72-15 45-48 72-93 72-49 0-91-27-91-72Z" fill="$body" stroke="#176C91" stroke-width="5"/>
<path d="M118 61 96 27l49 30M118 191l-22 36 49-31" fill="$fin" stroke="#176C91" stroke-width="5" stroke-linejoin="round"/>
<path d="M67 96c31-26 74-28 107-13" stroke="white" stroke-opacity=".42" stroke-width="8" stroke-linecap="round"/>
<circle cx="177" cy="108" r="12" fill="white"/><circle cx="181" cy="110" r="7" fill="#173B51"/><circle cx="178" cy="106" r="2" fill="white"/>
<path d="M184 146q${paused ? '-12 -8 -24 0' : '14 14 27 0'}" stroke="#9B3D55" stroke-width="5" stroke-linecap="round"/>
<circle cx="200" cy="126" r="7" fill="#FF8CA4" opacity=".65"/>''';

String _turtle() => '''
<ellipse cx="127" cy="132" rx="79" ry="65" fill="url(#teal)" stroke="#176F75" stroke-width="6"/>
<path d="M79 94q48-42 96 0M73 137h108M87 177q40-34 80 0M127 69v126" stroke="#D5F39A" stroke-width="5" opacity=".72"/>
<ellipse cx="207" cy="127" rx="34" ry="28" fill="#75DFAF" stroke="#176F75" stroke-width="5"/><circle cx="219" cy="119" r="5" fill="#173B51"/><path d="M216 139q9 8 18-1" stroke="#8C3D55" stroke-width="4" stroke-linecap="round"/>
<path d="M69 87q-39-20-44 12 20 18 49 11M68 173q-38 24-43-8 20-18 49-12M167 80q33-29 45 0-15 22-43 21M167 183q34 28 45-2-16-21-43-20" fill="#75DFAF" stroke="#176F75" stroke-width="5" stroke-linejoin="round"/>''';

String _octopus() => '''
<path d="M62 142c0-63 27-102 68-102s67 39 67 102c0 28-8 50-21 66-10-4-18-13-23-26-6 17-15 27-27 30-9-7-15-18-18-31-8 14-18 22-30 22-10-16-16-36-16-61Z" fill="url(#coral)" stroke="#A83C5B" stroke-width="6"/>
<path d="M83 195q-31 28-47 2M108 197q-20 36-40 22M148 197q19 36 40 20M174 191q33 25 46 0" stroke="#A83C5B" stroke-width="13" stroke-linecap="round"/>
<ellipse cx="105" cy="115" rx="12" ry="15" fill="white"/><ellipse cx="157" cy="115" rx="12" ry="15" fill="white"/><circle cx="108" cy="119" r="6" fill="#173B51"/><circle cx="154" cy="119" r="6" fill="#173B51"/><path d="M111 149q20 18 40 0" stroke="#8C2945" stroke-width="6" stroke-linecap="round"/>
<circle cx="88" cy="143" r="9" fill="#FFB8C7"/><circle cx="174" cy="143" r="9" fill="#FFB8C7"/>''';

Map<String, String> _feedbackAssets() => {
  'shared/success_badge_small.svg': _badge(true),
  'shared/retry_prompt_visual.svg': _badge(false),
  'shared/invalid_audio_wave.svg': _invalidWave(),
  'shared/progress_pearl.svg': _pearl(true),
  'shared/level_complete_banner.svg': _completeBanner(),
  'shared/next_target_transition.svg': _transition(),
  'shared/encouragement_heart.svg': _sticker('heart'),
  'shared/encouragement_star.svg': _sticker('star'),
  'shared/processing_shell.svg': _processingShell(),
};

String _badge(bool success) =>
    '''
<circle cx="128" cy="128" r="101" fill="${success ? 'url(#gold)' : 'url(#blue)'}" stroke="white" stroke-width="8"/>
<circle cx="128" cy="128" r="84" fill="white" fill-opacity=".2" stroke="#176C91" stroke-opacity=".28" stroke-width="4"/>
${success ? '<path d="M76 130l33 32 72-75" stroke="white" stroke-width="18" stroke-linecap="round" stroke-linejoin="round"/>' : '<path d="M173 94a61 61 0 1 0 8 55" stroke="white" stroke-width="17" stroke-linecap="round"/><path d="m173 94-4-39 39 17" fill="white" stroke="white" stroke-width="5" stroke-linejoin="round"/>'}
<circle cx="81" cy="74" r="10" fill="white" fill-opacity=".7"/>''';

String _invalidWave() => '''
<path d="M29 151c23-36 44-36 67 0s44 36 67 0 44-36 67 0" stroke="#7EDCF3" stroke-width="18" stroke-linecap="round"/>
<path d="M29 188c23-30 44-30 67 0s44 30 67 0 44-30 67 0" stroke="#3AA8D7" stroke-width="13" stroke-linecap="round" opacity=".76"/>
<path d="M68 91c8-31 32-50 62-50 36 0 62 26 65 60 22 2 36 17 36 38 0 24-18 39-46 39H73c-29 0-48-17-48-42 0-24 17-41 43-45Z" fill="#D8F4FA" stroke="#6BB9D0" stroke-width="6"/>
<path d="m105 100 46 46M151 100l-46 46" stroke="#E7687E" stroke-width="11" stroke-linecap="round"/>''';

String _completeBanner() => '''
<path d="M22 76c34 12 54 4 76-20h60c22 24 42 32 76 20l-18 66 18 65c-35-12-58-4-78 18H99c-20-22-43-30-77-18l18-65-18-66Z" fill="url(#purple)" stroke="#4D3C9E" stroke-width="6"/>
<path d="M57 85h142v101H57z" fill="url(#gold)" stroke="#E28F27" stroke-width="6"/>
<path d="m128 100 10 22 25 3-18 17 5 25-22-12-22 12 5-25-18-17 25-3 10-22Z" fill="white"/>
<circle cx="73" cy="105" r="7" fill="#FF83A0"/><circle cx="183" cy="105" r="7" fill="#58D9F2"/>''';

String _transition() => '''
<path d="M23 132c55-59 107-71 185-35" stroke="#C6F6FF" stroke-width="12" stroke-linecap="round" stroke-dasharray="3 24"/>
<path d="m179 70 53 34-59 20 13-21-7-33Z" fill="url(#gold)" stroke="#E38D25" stroke-width="5" stroke-linejoin="round"/>
<g fill="url(#bubble)" stroke="white" stroke-width="3"><circle cx="61" cy="173" r="19"/><circle cx="105" cy="139" r="13"/><circle cx="141" cy="111" r="9"/></g>''';

String _sticker(String kind) => kind == 'heart'
    ? '<path d="M128 218C48 168 26 125 47 83c19-38 66-37 81 1 15-38 62-39 81-1 21 42-1 85-81 135Z" fill="url(#coral)" stroke="white" stroke-width="9"/><path d="M72 92q24-28 45 1" stroke="white" stroke-opacity=".55" stroke-width="9" stroke-linecap="round"/>'
    : '<path d="m128 22 28 67 72 6-55 47 17 71-62-38-62 38 17-71-55-47 72-6 28-67Z" fill="url(#gold)" stroke="white" stroke-width="9" stroke-linejoin="round"/><path d="M93 87q34-28 66 0" stroke="white" stroke-opacity=".55" stroke-width="9" stroke-linecap="round"/>';

String _processingShell() => '''
<path d="M42 174c0-76 33-126 86-126s86 50 86 126H42Z" fill="url(#coral)" stroke="#A83C5B" stroke-width="7"/>
<path d="M128 57v117M83 73l25 101M173 73l-25 101M55 112l53 62M201 112l-53 62" stroke="#FFD1DC" stroke-width="7" stroke-linecap="round"/>
<path d="M31 174h194v37H31z" rx="18" fill="url(#gold)" stroke="#E49426" stroke-width="7"/>
<g fill="white"><circle cx="92" cy="193" r="7"/><circle cx="128" cy="193" r="7"/><circle cx="164" cy="193" r="7"/></g>''';

Map<String, String> _bubbleBayAssets() => {
  'bubble_bay/sound_bubble_idle.svg': _bubble(.62, false),
  'bubble_bay/sound_bubble_partial.svg': _bubble(.78, false),
  'bubble_bay/sound_bubble_full.svg': _bubble(1, true),
  'bubble_bay/bubble_pop_effect.svg': _popEffect(),
  'bubble_bay/coral_ring.svg': _coralRing(),
  'bubble_bay/glowing_pearl_off.svg': _pearl(false),
  'bubble_bay/glowing_pearl_on.svg': _pearl(true),
  'bubble_bay/pearl_slot.svg': _pearlSlot(),
  'bubble_bay/reef_decor.svg': _reefDecor(),
  'bubble_bay/success_sparkle.svg': _sparkles('#FFE36A'),
  'bubble_bay/retry_effect.svg': _wobbleEffect(),
  'bubble_bay/invalid_audio_effect.svg': _invalidWave(),
  'bubble_bay/instruction_panel_decor.svg': _panelDecor(),
};

String _bubble(double scale, bool smile) =>
    '''
<g transform="translate(${128 * (1 - scale)} ${128 * (1 - scale)}) scale($scale)">
<circle cx="128" cy="128" r="102" fill="url(#bubble)" stroke="white" stroke-width="7"/>
<path d="M67 78c24-32 68-43 101-22" stroke="white" stroke-width="13" stroke-linecap="round" opacity=".7"/>
<circle cx="99" cy="126" r="8" fill="#176C91"/><circle cx="158" cy="126" r="8" fill="#176C91"/>
<path d="M105 157q23 ${smile ? '23' : '10'} 46 0" stroke="#E55C7A" stroke-width="6" stroke-linecap="round"/>
<circle cx="82" cy="145" r="10" fill="#FF9FB4" opacity=".55"/><circle cx="175" cy="145" r="10" fill="#FF9FB4" opacity=".55"/>
</g>''';

String _popEffect() => '''
<circle cx="128" cy="128" r="39" fill="url(#glow)"/>
<g stroke="#C7F7FF" stroke-width="9" stroke-linecap="round"><path d="M128 18v42M128 196v42M18 128h42M196 128h42M49 49l30 30M177 177l30 30M207 49l-30 30M79 177l-30 30"/></g>
<g fill="url(#bubble)" stroke="white" stroke-width="3"><circle cx="72" cy="101" r="12"/><circle cx="183" cy="92" r="9"/><circle cx="168" cy="176" r="14"/></g>''';

String _coralRing() => '''
<circle cx="128" cy="128" r="88" stroke="#A64B67" stroke-width="34"/>
<circle cx="128" cy="128" r="88" stroke="url(#coral)" stroke-width="25"/>
<g fill="url(#gold)" stroke="#E28E26" stroke-width="4"><circle cx="55" cy="82" r="13"/><circle cx="188" cy="72" r="12"/><circle cx="198" cy="169" r="14"/><circle cx="72" cy="190" r="11"/></g>
<g fill="#A686F2"><path d="m128 28 7 15 17 2-12 12 3 17-15-8-15 8 3-17-12-12 17-2 7-15Z"/><path d="m42 148 5 11 12 1-9 8 3 12-11-6-11 6 3-12-9-8 12-1 5-11Z"/></g>
<path d="M42 115q-18-23-4-43M212 133q20-24 5-44" stroke="#70D69C" stroke-width="10" stroke-linecap="round"/>''';

String _pearl(bool on) =>
    '''
${on ? '<circle cx="128" cy="128" r="112" fill="url(#glow)"/>' : ''}
<circle cx="128" cy="128" r="62" fill="${on ? '#FFF9C7' : '#B8C7D0'}" stroke="${on ? '#E8B342' : '#78909C'}" stroke-width="7"/>
<ellipse cx="105" cy="101" rx="23" ry="15" fill="white" opacity="${on ? '.78' : '.3'}"/>
<path d="M81 161q47 27 94 0" stroke="${on ? '#FFD45E' : '#96A8B2'}" stroke-width="8" stroke-linecap="round" opacity=".7"/>''';

String _pearlSlot() => '''
<path d="M37 166c10-53 43-82 91-82s81 29 91 82H37Z" fill="url(#purple)" stroke="#514398" stroke-width="7"/>
<ellipse cx="128" cy="164" rx="94" ry="38" fill="#4A3D8D" stroke="#312C70" stroke-width="7"/>
<ellipse cx="128" cy="155" rx="57" ry="22" fill="#22295F"/>
<path d="M59 111q69-58 138 0" stroke="#D0BFFF" stroke-width="8" stroke-linecap="round" opacity=".65"/>''';

String _reefDecor() => '''
<path d="M24 216h208" stroke="#397B87" stroke-width="10" stroke-linecap="round"/>
<path d="M57 209q-14-42 7-75M75 210q24-42 5-82M177 211q-18-50 9-88M197 211q22-38 8-68" stroke="#45C68F" stroke-width="12" stroke-linecap="round"/>
<path d="M104 211v-69M104 169 78 145M105 182l28-31M151 213v-52M151 178l24-22" stroke="url(#coral)" stroke-width="14" stroke-linecap="round"/>
<g fill="#A889F3"><circle cx="41" cy="205" r="13"/><circle cx="218" cy="203" r="16"/></g>''';

String _sparkles(String color) =>
    '''
<g fill="$color"><path d="m128 20 12 30 31 3-24 20 8 31-27-17-27 17 8-31-24-20 31-3 12-30Z"/><path d="m51 98 7 17 18 2-14 12 4 18-15-10-16 10 5-18-14-12 18-2 7-17Z"/><path d="m207 115 7 17 18 2-14 12 4 18-15-10-16 10 5-18-14-12 18-2 7-17Z"/></g>
<g fill="white"><circle cx="93" cy="188" r="8"/><circle cx="174" cy="200" r="6"/></g>''';

String _wobbleEffect() => '''
<path d="M58 78q-26 50 0 100M198 78q26 50 0 100" stroke="#FF9A6C" stroke-width="10" stroke-linecap="round" stroke-dasharray="7 17"/>
<path d="m73 43-25 7 15 21M183 43l25 7-15 21" stroke="#FFD45E" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
<g fill="url(#bubble)" stroke="white" stroke-width="3"><circle cx="128" cy="128" r="53"/><circle cx="126" cy="126" r="35"/></g>''';

String _panelDecor() => '''
<path d="M25 71c35-31 68-40 103-40s68 9 103 40" stroke="#7BDCF0" stroke-width="10" stroke-linecap="round"/>
<path d="M25 185c35 31 68 40 103 40s68-9 103-40" stroke="#7BDCF0" stroke-width="10" stroke-linecap="round"/>
<g fill="#FF8CA4"><circle cx="35" cy="128" r="10"/><circle cx="221" cy="128" r="10"/></g>
<g fill="#FFD45E"><path d="m61 51 5 11 12 2-9 8 2 12-10-6-11 6 3-12-9-8 12-2 5-11Z"/><path d="m195 171 5 11 12 2-9 8 2 12-10-6-11 6 3-12-9-8 12-2 5-11Z"/></g>''';

Map<String, String> _coralCargoAssets() => {
  'coral_cargo/cargo_tube.svg': _cargoTube(),
  'coral_cargo/cargo_box.svg': _cargoBox(),
  'coral_cargo/target_item_frame.svg': _itemFrame(),
  'coral_cargo/cargo_platform.svg': _platform(),
  'coral_cargo/delivery_hatch.svg': _hatch(),
  'coral_cargo/receiver_turtle.svg': _turtle(),
  'coral_cargo/receiver_octopus.svg': _octopus(),
  'coral_cargo/success_delivery_effect.svg': _deliveryEffect(true),
  'coral_cargo/mix_up_effect.svg': _mixUp(),
  'coral_cargo/underwater_mail_props.svg': _mailProps(),
  'coral_cargo/retry_state.svg': _deliveryEffect(false),
  'coral_cargo/completed_delivery_effect.svg': _sparkles('#FFD75E'),
};

String _cargoTube() => '''
<path d="M29 128h198" stroke="#176C91" stroke-width="66" stroke-linecap="round"/>
<path d="M29 128h198" stroke="#BFF6FF" stroke-opacity=".62" stroke-width="54" stroke-linecap="round"/>
<path d="M42 111h168" stroke="white" stroke-opacity=".68" stroke-width="9" stroke-linecap="round"/>
<g fill="url(#gold)" stroke="#B86F25" stroke-width="5"><rect x="24" y="89" width="27" height="78" rx="10"/><rect x="107" y="89" width="27" height="78" rx="10"/><rect x="205" y="89" width="27" height="78" rx="10"/></g>''';

String _cargoBox() => '''
<path d="M42 76 128 37l86 39v112l-86 37-86-37V76Z" fill="url(#gold)" stroke="#9A5B27" stroke-width="7" stroke-linejoin="round"/>
<path d="m42 76 86 39 86-39M128 115v110" stroke="#9A5B27" stroke-width="7"/>
<path d="m100 50 86 40v38l-28-13V77L72 38" fill="#FFDF76" opacity=".58"/>
<path d="M91 134h74v49H91z" fill="#FFF4C8" stroke="#C4772D" stroke-width="5"/><path d="M108 151h40M108 165h28" stroke="#F08A67" stroke-width="5" stroke-linecap="round"/>''';

String _itemFrame() => '''
<path d="M128 24 223 79v110l-95 55-95-55V79l95-55Z" fill="url(#teal)" stroke="#176F75" stroke-width="7"/>
<path d="M128 45 204 89v88l-76 44-76-44V89l76-44Z" fill="white" fill-opacity=".92" stroke="#B9F2E4" stroke-width="6"/>
<circle cx="128" cy="133" r="54" fill="#DDF8FC"/><path d="M90 196h76" stroke="#FFD45E" stroke-width="8" stroke-linecap="round"/>''';

String _platform() => '''
<ellipse cx="128" cy="174" rx="105" ry="48" fill="#2A6E79" stroke="#174E61" stroke-width="7"/>
<ellipse cx="128" cy="158" rx="105" ry="48" fill="url(#teal)" stroke="#176F75" stroke-width="7"/>
<ellipse cx="128" cy="151" rx="78" ry="29" fill="#D2FAF3" opacity=".42"/>
<path d="M57 189v35M199 189v35" stroke="#174E61" stroke-width="13" stroke-linecap="round"/>''';

String _hatch() => '''
<rect x="49" y="34" width="158" height="190" rx="60" fill="url(#teal)" stroke="#176F75" stroke-width="8"/>
<rect x="68" y="57" width="120" height="144" rx="45" fill="#173F61" stroke="url(#gold)" stroke-width="10"/>
<path d="M80 109h96v80H80z" fill="#10415A"/><path d="M79 109h98l-14-34H93l-14 34Z" fill="url(#coral)" stroke="#A63E5A" stroke-width="6"/>
<circle cx="164" cy="153" r="10" fill="#FFD75E"/>''';

String _deliveryEffect(bool success) => success
    ? '<path d="M25 128h167" stroke="#C7F7FF" stroke-width="12" stroke-linecap="round" stroke-dasharray="5 20"/><path d="m178 88 55 40-55 40 10-28h-36v-24h36l-10-28Z" fill="url(#gold)" stroke="#E38D25" stroke-width="5" stroke-linejoin="round"/>'
    : '<path d="M42 111q86-48 172 0M42 150q86 48 172 0" stroke="#FF9A6C" stroke-width="10" stroke-linecap="round" stroke-dasharray="8 18"/><circle cx="128" cy="130" r="38" fill="#FFF0D0" stroke="#F0A85A" stroke-width="6"/><path d="M109 130h38" stroke="#E35C72" stroke-width="8" stroke-linecap="round"/>';

String _mixUp() => '''
<path d="M38 78h180v112H38z" rx="28" fill="#FFF2C8" stroke="#F0A64B" stroke-width="7"/>
<path d="M74 102h70v57c0 24-70 24-70 0v-57Z" fill="white" stroke="#4BB8D0" stroke-width="6"/><path d="M145 113q34 0 34 23t-34 23" stroke="#4BB8D0" stroke-width="8"/>
<path d="M88 89q12-27 24 0M117 89q12-27 24 0" stroke="#D8F4FA" stroke-width="6" stroke-linecap="round"/>
<path d="m182 72 9 19 21 3-15 15 4 21-19-10-19 10 4-21-15-15 21-3 9-19Z" fill="#FF86A0"/>''';

String _mailProps() => '''
<path d="M26 90h92v105H26z" rx="15" fill="url(#coral)" stroke="#A63E5A" stroke-width="6"/><path d="m26 92 46 40 46-40" stroke="#FFF0F4" stroke-width="6" stroke-linejoin="round"/>
<path d="M137 58h91v111h-91z" rx="14" fill="url(#gold)" stroke="#A46526" stroke-width="6"/><path d="M158 86h49M158 105h38M158 124h45" stroke="#FFF7D0" stroke-width="6" stroke-linecap="round"/>
<path d="M148 193h65" stroke="#50C99A" stroke-width="14" stroke-linecap="round"/>''';

Map<String, String> _reefRouteAssets() => {
  'reef_route/reef_gate_closed.svg': _reefGate(false),
  'reef_route/reef_gate_open.svg': _reefGate(true),
  'reef_route/route_marker.svg': _routeMarker(),
  'reef_route/route_path.svg': _routePath(),
  'reef_route/fish_school.svg': _fishSchool(),
  'reef_route/fish_swim_effect.svg': _swimEffect(),
  'reef_route/gate_success_glow.svg': _sparkles('#8CF0B9'),
  'reef_route/paused_before_gate.svg': _fish('#FFD75E', '#F18C35', true),
  'reef_route/route_sign.svg': _routeSign(),
  'reef_route/phrase_feedback.svg': _badge(true),
  'reef_route/coral_checkpoint.svg': _checkpoint(),
};

String _reefGate(bool open) => '''
<path d="M38 225V84c0-34 30-61 67-61h46c37 0 67 27 67 61v141" stroke="#176F75" stroke-width="23" stroke-linecap="round"/>
<path d="M52 224V91c0-30 25-52 56-52h40c31 0 56 22 56 52v133" stroke="url(#teal)" stroke-width="15"/>
<g stroke="#FFB0C0" stroke-width="10" stroke-linecap="round"><path d="M49 90 25 71M61 57 49 32M195 64l17-25M207 98l25-16"/></g>
${open ? '<path d="M103 50v64l-44 41M153 50v64l44 41" stroke="url(#gold)" stroke-width="12" stroke-linecap="round"/>' : '<path d="M82 48v165M108 41v172M134 41v172M160 43v170M186 53v160" stroke="url(#gold)" stroke-width="11" stroke-linecap="round"/>'}''';

String _routeMarker() => '''
<path d="M128 231V96" stroke="#8A5C31" stroke-width="14" stroke-linecap="round"/>
<path d="M61 37h127l34 49-34 49H61L28 86l33-49Z" fill="url(#gold)" stroke="#A66728" stroke-width="7"/>
<path d="m91 87 24 24 52-54" stroke="white" stroke-width="13" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M92 231h72" stroke="#45C990" stroke-width="15" stroke-linecap="round"/>''';

String _routePath() => '''
<path d="M20 195c55-7 50-69 105-72s53-67 111-73" stroke="#E5B95C" stroke-width="33" stroke-linecap="round"/>
<path d="M20 190c55-7 50-69 105-72s53-67 111-73" stroke="#FFF1B0" stroke-width="24" stroke-linecap="round" stroke-dasharray="7 19"/>
<g fill="#FF98AD"><circle cx="49" cy="178" r="8"/><circle cx="126" cy="112" r="8"/><circle cx="203" cy="62" r="8"/></g>''';

String _fishSchool() =>
    '''
<g transform="translate(5 52) scale(.58)">${_fish('#FFD75E', '#F18C35', false)}</g>
<g transform="translate(102 15) scale(.5)">${_fish('#55D9FF', '#188CC8', false)}</g>
<g transform="translate(95 115) scale(.43)">${_fish('#FF8CA4', '#D84C6D', false)}</g>''';

String _swimEffect() => '''
<path d="M34 84q35-28 70 0M21 125q49-34 98 0M41 166q34-25 68 0" stroke="#C7F7FF" stroke-width="9" stroke-linecap="round" opacity=".85"/>
<g fill="url(#bubble)" stroke="white" stroke-width="3"><circle cx="156" cy="85" r="12"/><circle cx="191" cy="121" r="18"/><circle cx="222" cy="162" r="10"/></g>''';

String _routeSign() => '''
<path d="M128 229V99" stroke="#8B5B33" stroke-width="15" stroke-linecap="round"/>
<path d="M34 42h188v80H34z" rx="20" fill="url(#purple)" stroke="#4E4098" stroke-width="7"/>
<path d="m76 82 30-25v17h74v18h-74v17L76 82Z" fill="white"/>
<path d="M87 229h82" stroke="#45C990" stroke-width="15" stroke-linecap="round"/>''';

String _checkpoint() => '''
<path d="M47 215v-76M209 215v-76" stroke="#8C5A35" stroke-width="13" stroke-linecap="round"/>
<path d="M45 145q21-64 43 0M70 144q20-91 42 0M145 144q20-91 42 0M173 145q20-64 41 0" stroke="url(#coral)" stroke-width="14" stroke-linecap="round"/>
<path d="M31 126h194v42H31z" rx="20" fill="url(#gold)" stroke="#A66728" stroke-width="6"/><path d="m128 134 7 14 15 2-11 10 3 15-14-7-14 7 3-15-11-10 15-2 7-14Z" fill="white"/>''';

Map<String, String> _captainsCallAssets() => {
  'captains_call/submarine_main.svg': _submarine(),
  'captains_call/command_panel.svg': _commandPanel(),
  'captains_call/sonar_visual.svg': _sonar(false),
  'captains_call/sonar_ping_effect.svg': _sonar(true),
  'captains_call/rescue_arm.svg': _rescueArm(),
  'captains_call/treasure_chest.svg': _treasureChest(),
  'captains_call/underwater_gate.svg': _underwaterGate(),
  'captains_call/submarine_success_effect.svg': _sparkles('#79F2DE'),
  'captains_call/treasure_sparkle.svg': _sparkles('#FFE36A'),
  'captains_call/rescue_effect.svg': _rescueEffect(),
  'captains_call/fuzzy_sonar_retry.svg': _fuzzySonar(),
};

String _submarine() => '''
<path d="M41 129c0-48 41-80 105-80 48 0 82 24 91 61l-8 52c-15 28-47 45-91 45-58 0-97-30-97-78Z" fill="url(#gold)" stroke="#9D5E27" stroke-width="7"/>
<path d="M69 84c38-28 94-27 130 0" stroke="white" stroke-opacity=".38" stroke-width="10" stroke-linecap="round"/>
<path d="M103 55V30h58v28" fill="url(#teal)" stroke="#176F75" stroke-width="7"/><path d="M125 30V14h50" stroke="#176F75" stroke-width="8" stroke-linecap="round"/>
<g fill="#BDF7FF" stroke="#176F75" stroke-width="6"><circle cx="102" cy="128" r="25"/><circle cx="160" cy="128" r="25"/></g>
<path d="M39 114 14 91v76l25-24M230 112l18 16-18 18" fill="url(#teal)" stroke="#176F75" stroke-width="7" stroke-linejoin="round"/>
<path d="M81 192q51 22 102-2" stroke="#E58A2B" stroke-width="9" stroke-linecap="round"/>''';

String _commandPanel() => '''
<rect x="25" y="42" width="206" height="174" rx="35" fill="url(#teal)" stroke="#176F75" stroke-width="8"/>
<rect x="46" y="62" width="164" height="76" rx="22" fill="#173F61" stroke="#8DEAFF" stroke-width="5"/>
<circle cx="127" cy="100" r="27" fill="none" stroke="#60E4F2" stroke-width="4"/><path d="M127 73v54M100 100h54" stroke="#60E4F2" stroke-width="3" opacity=".7"/>
<g stroke="#173F61" stroke-width="5"><circle cx="69" cy="174" r="16" fill="#FF7F96"/><circle cx="112" cy="174" r="16" fill="#FFD45E"/><circle cx="155" cy="174" r="16" fill="#65DBA1"/><circle cx="198" cy="174" r="16" fill="#A98AF2"/></g>''';

String _sonar(bool ping) =>
    '''
<circle cx="128" cy="128" r="22" fill="#8CF6FF" stroke="#176F75" stroke-width="6"/>
<circle cx="128" cy="128" r="50" fill="none" stroke="#5FE8F4" stroke-width="7" opacity=".9"/>
<circle cx="128" cy="128" r="82" fill="none" stroke="#5FE8F4" stroke-width="${ping ? '9' : '6'}" opacity=".65"/>
<circle cx="128" cy="128" r="113" fill="none" stroke="#5FE8F4" stroke-width="${ping ? '7' : '4'}" opacity=".35"/>
<path d="M128 128 192 83" stroke="#FFF48C" stroke-width="7" stroke-linecap="round"/><circle cx="192" cy="83" r="10" fill="#FFD45E"/>''';

String _rescueArm() => '''
<path d="M40 45h68v40H40z" rx="14" fill="url(#teal)" stroke="#176F75" stroke-width="7"/>
<path d="M91 82 151 134l-28 32-61-52 29-32Z" fill="url(#gold)" stroke="#9D5E27" stroke-width="7"/>
<circle cx="137" cy="150" r="27" fill="url(#teal)" stroke="#176F75" stroke-width="7"/>
<path d="M153 166q45 8 55 44M122 170q-24 31-7 58" stroke="#176F75" stroke-width="14" stroke-linecap="round"/>
<path d="M208 210l-18-7M208 210l-2-19M115 228l-18-7M115 228l5-19" stroke="#FFD45E" stroke-width="8" stroke-linecap="round"/>''';

String _treasureChest() => '''
<path d="M47 101c0-45 36-72 81-72s81 27 81 72H47Z" fill="url(#gold)" stroke="#8D572B" stroke-width="8"/>
<path d="M39 101h178v120H39z" rx="22" fill="#8B512B" stroke="#5E391F" stroke-width="8"/>
<path d="M52 115h152v90H52z" rx="13" fill="url(#gold)"/>
<path d="M112 115h32v61h-32z" fill="#FFF1A8" stroke="#A76A28" stroke-width="5"/><circle cx="128" cy="151" r="10" fill="#8B512B"/>
<path d="M67 85h122M83 48l-9-25M128 34V9M174 49l12-25" stroke="#FFF6B0" stroke-width="8" stroke-linecap="round"/>''';

String _underwaterGate() => '''
<path d="M39 229V92c0-39 39-68 89-68s89 29 89 68v137" fill="#173F61" stroke="url(#gold)" stroke-width="12"/>
<path d="M67 225V101c0-28 27-47 61-47s61 19 61 47v124" fill="url(#teal)" stroke="#176F75" stroke-width="8"/>
<path d="M128 55v170M67 128h122" stroke="#FFD45E" stroke-width="8"/><circle cx="128" cy="128" r="31" fill="#173F61" stroke="#FFD45E" stroke-width="8"/><path d="M128 106v44M106 128h44" stroke="#FFD45E" stroke-width="7"/>''';

String _rescueEffect() => '''
<path d="M29 180q99-107 198 0" stroke="#79F2DE" stroke-width="13" stroke-linecap="round" stroke-dasharray="8 19"/>
<path d="m128 40 14 31 34 4-25 23 7 34-30-17-30 17 7-34-25-23 34-4 14-31Z" fill="url(#gold)"/>
<g fill="url(#bubble)" stroke="white" stroke-width="3"><circle cx="55" cy="113" r="14"/><circle cx="201" cy="111" r="18"/><circle cx="84" cy="195" r="10"/></g>''';

String _fuzzySonar() => '''
<circle cx="128" cy="128" r="28" fill="#A5D6DE" stroke="#647F91" stroke-width="7"/>
<path d="M128 72c37 0 61 24 61 56s-24 56-61 56-61-24-61-56 24-56 61-56ZM128 39c55 0 93 38 93 89s-38 89-93 89-93-38-93-89 38-89 93-89Z" stroke="#93AAB4" stroke-width="8" stroke-dasharray="5 17"/>
<path d="M27 103q19-18 38 0t38 0 38 0 38 0 38 0" stroke="#FF8E73" stroke-width="7" stroke-linecap="round" opacity=".8"/>''';
