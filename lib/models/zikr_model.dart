class Zikr {
  final String title;
  final String text;
  final String? translate;
  final int repeat;

  Zikr({
    required this.title,
    required this.text,
    required this.repeat,
    this.translate,
  });
}
