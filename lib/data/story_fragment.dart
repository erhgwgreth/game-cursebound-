enum FragmentKind { sinInscription, memory }

class StoryFragment {
  const StoryFragment({
    required this.id,
    required this.kind,
    required this.order,
    required this.textKey,
    this.sinTheme,
  });

  final String id;
  final FragmentKind kind;
  final int order;
  final String textKey;
  final String? sinTheme;
}

String sinThemeForFloor(int floor) {
  return switch ((floor - 1) % 5) {
    0 => 'abandonment',
    1 => 'greed',
    2 => 'betrayal',
    3 => 'fanaticism',
    _ => 'pride',
  };
}

const List<StoryFragment> storyFragmentTable = [
  StoryFragment(
    id: 'sin_abandonment_01',
    kind: FragmentKind.sinInscription,
    order: 101,
    sinTheme: 'abandonment',
    textKey: 'story.sin.abandonment.01',
  ),
  StoryFragment(
    id: 'sin_abandonment_02',
    kind: FragmentKind.sinInscription,
    order: 102,
    sinTheme: 'abandonment',
    textKey: 'story.sin.abandonment.02',
  ),
  StoryFragment(
    id: 'sin_greed_01',
    kind: FragmentKind.sinInscription,
    order: 201,
    sinTheme: 'greed',
    textKey: 'story.sin.greed.01',
  ),
  StoryFragment(
    id: 'sin_greed_02',
    kind: FragmentKind.sinInscription,
    order: 202,
    sinTheme: 'greed',
    textKey: 'story.sin.greed.02',
  ),
  StoryFragment(
    id: 'sin_betrayal_01',
    kind: FragmentKind.sinInscription,
    order: 301,
    sinTheme: 'betrayal',
    textKey: 'story.sin.betrayal.01',
  ),
  StoryFragment(
    id: 'sin_betrayal_02',
    kind: FragmentKind.sinInscription,
    order: 302,
    sinTheme: 'betrayal',
    textKey: 'story.sin.betrayal.02',
  ),
  StoryFragment(
    id: 'sin_fanaticism_01',
    kind: FragmentKind.sinInscription,
    order: 401,
    sinTheme: 'fanaticism',
    textKey: 'story.sin.fanaticism.01',
  ),
  StoryFragment(
    id: 'sin_fanaticism_02',
    kind: FragmentKind.sinInscription,
    order: 402,
    sinTheme: 'fanaticism',
    textKey: 'story.sin.fanaticism.02',
  ),
  StoryFragment(
    id: 'sin_pride_01',
    kind: FragmentKind.sinInscription,
    order: 501,
    sinTheme: 'pride',
    textKey: 'story.sin.pride.01',
  ),
  StoryFragment(
    id: 'sin_pride_02',
    kind: FragmentKind.sinInscription,
    order: 502,
    sinTheme: 'pride',
    textKey: 'story.sin.pride.02',
  ),
  StoryFragment(
    id: 'memory_01_offering_day',
    kind: FragmentKind.memory,
    order: 1,
    textKey: 'story.memory.01',
  ),
  StoryFragment(
    id: 'memory_02_sold_by_friends',
    kind: FragmentKind.memory,
    order: 2,
    textKey: 'story.memory.02',
  ),
  StoryFragment(
    id: 'memory_03_chosen_sacrifice',
    kind: FragmentKind.memory,
    order: 3,
    textKey: 'story.memory.03',
  ),
  StoryFragment(
    id: 'memory_04_first_contract',
    kind: FragmentKind.memory,
    order: 4,
    textKey: 'story.memory.04',
  ),
  StoryFragment(
    id: 'memory_05_red_hands',
    kind: FragmentKind.memory,
    order: 5,
    textKey: 'story.memory.05',
  ),
  StoryFragment(
    id: 'memory_06_no_surface',
    kind: FragmentKind.memory,
    order: 6,
    textKey: 'story.memory.06',
  ),
];

List<StoryFragment> get memoryFragments {
  final fragments = storyFragmentTable
      .where((fragment) => fragment.kind == FragmentKind.memory)
      .toList();
  fragments.sort((a, b) => a.order.compareTo(b.order));
  return fragments;
}

List<StoryFragment> sinFragmentsForTheme(String theme) {
  final fragments = storyFragmentTable
      .where(
        (fragment) =>
            fragment.kind == FragmentKind.sinInscription &&
            fragment.sinTheme == theme,
      )
      .toList();
  fragments.sort((a, b) => a.order.compareTo(b.order));
  return fragments;
}
