import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AppColors {
  static const Color cream = Color(0xFFFFF8E1);
  static const Color gold = Color(0xFFC9A227);
}

class AyahData {
  final String ayahKey; // "1_7"
  final int sura;
  final int ayah;
  final Map<String, String> translations; // lang -> text

  AyahData({
    required this.ayahKey,
    required this.sura,
    required this.ayah,
    required this.translations,
  });
}

class AyahBox {
  final Rect rect; // IMAGE pixels
  final String ayahKey; // "1_1"
  final int ayahId;

  AyahBox({
    required this.rect,
    required this.ayahKey,
    required this.ayahId,
  });
}

class Surah {
  final String name;
  final int startPage; // 1..604
  const Surah({required this.name, required this.startPage});
}

const List<Surah> surahList = [
  Surah(name: "الفاتحة", startPage: 1),
  Surah(name: "البقرة", startPage: 2),
  Surah(name: "آل عمران", startPage: 50),
  Surah(name: "النساء", startPage: 77),
  Surah(name: "المائدة", startPage: 106),
  Surah(name: "الأنعام", startPage: 128),
  Surah(name: "الأعراف", startPage: 151),
  Surah(name: "الأنفال", startPage: 177),
  Surah(name: "التوبة", startPage: 187),
  Surah(name: "هود", startPage: 208),
  Surah(name: "یوسف", startPage: 221),
  Surah(name: "الرعد", startPage: 249),
  Surah(name: "إبراهيم", startPage: 255),
  Surah(name: "الحجر", startPage: 262),
  Surah(name: "النحل", startPage: 267),
  Surah(name: "الإسراء", startPage: 282),
  Surah(name: "الکهف", startPage: 293),
  Surah(name: "مریم", startPage: 305),
  Surah(name: "طه", startPage: 312),
  Surah(name: "الأنبياء", startPage: 322),
  Surah(name: "الحج", startPage: 332),
  Surah(name: "المؤمنون", startPage: 342),
  Surah(name: "النور", startPage: 350),
  Surah(name: "الفرقان", startPage: 359),
  Surah(name: "الشعراء", startPage: 367),
  Surah(name: "النمل", startPage: 377),
  Surah(name: "القصص", startPage: 385),
  Surah(name: "العنكبوت", startPage: 396),
  Surah(name: "الروم", startPage: 404),
  Surah(name: "لقمان", startPage: 411),
  Surah(name: "السجدة", startPage: 415),
  Surah(name: "الأحزاب", startPage: 418),
  Surah(name: "سبأ", startPage: 428),
  Surah(name: "فاطر", startPage: 434),
  Surah(name: "يس", startPage: 440),
  Surah(name: "الصافات", startPage: 446),
  Surah(name: "ص", startPage: 453),
  Surah(name: "الزمر", startPage: 458),
  Surah(name: "غافر", startPage: 467),
  Surah(name: "فصلت", startPage: 477),
  Surah(name: "الشوری", startPage: 483),
  Surah(name: "الزخرف", startPage: 489),
  Surah(name: "الدخان", startPage: 496),
  Surah(name: "الجاثیه", startPage: 499),
  Surah(name: "الأحقاف", startPage: 502),
  Surah(name: "محمد", startPage: 507),
  Surah(name: "الفتح", startPage: 511),
  Surah(name: "الحجرات", startPage: 515),
  Surah(name: "ق", startPage: 518),
  Surah(name: "الذاریات", startPage: 520),
  Surah(name: "الطور", startPage: 523),
  Surah(name: "النجم", startPage: 526),
  Surah(name: "القمر", startPage: 528),
  Surah(name: "الرحمن", startPage: 531),
  Surah(name: "الواقعه", startPage: 534),
  Surah(name: "الحدید", startPage: 537),
  Surah(name: "المجادلة", startPage: 542),
  Surah(name: "الحشر", startPage: 545),
  Surah(name: "الممتحنة", startPage: 549),
  Surah(name: "الصف", startPage: 551),
  Surah(name: "الجمعة", startPage: 553),
  Surah(name: "المنافقون", startPage: 554),
  Surah(name: "التغابن", startPage: 556),
  Surah(name: "الطلاق", startPage: 558),
  Surah(name: "التحریم", startPage: 560),
  Surah(name: "الملك", startPage: 562),
  Surah(name: "القلم", startPage: 564),
  Surah(name: "الحاقة", startPage: 566),
  Surah(name: "المعارج", startPage: 568),
  Surah(name: "نوح", startPage: 570),
  Surah(name: "جن", startPage: 572),
  Surah(name: "المزمل", startPage: 574),
  Surah(name: "المدثر", startPage: 575),
  Surah(name: "القيامة", startPage: 577),
  Surah(name: "الإنسان", startPage: 578),
  Surah(name: "المرسلات", startPage: 580),
  Surah(name: "النبأ", startPage: 582),
  Surah(name: "النازعات", startPage: 583),
  Surah(name: "عبس", startPage: 585),
  Surah(name: "التکویر", startPage: 586),
  Surah(name: "الإنفطار", startPage: 587),
  Surah(name: "المطففین", startPage: 587),
  Surah(name: "الإنشقاق", startPage: 589),
  Surah(name: "البروج", startPage: 590),
  Surah(name: "الطارق", startPage: 591),
  Surah(name: "الأعلى", startPage: 591),
  Surah(name: "الغاشية", startPage: 592),
  Surah(name: "الفجر", startPage: 593),
  Surah(name: "البلد", startPage: 594),
  Surah(name: "الشمس", startPage: 595),
  Surah(name: "اللیل", startPage: 595),
  Surah(name: "الضحی", startPage: 596),
  Surah(name: "الشرح", startPage: 596),
  Surah(name: "التین", startPage: 597),
  Surah(name: "العلق", startPage: 597),
  Surah(name: "القدر", startPage: 598),
  Surah(name: "البینه", startPage: 598),
  Surah(name: "الزلزلة", startPage: 599),
  Surah(name: "العادیات", startPage: 599),
  Surah(name: "القارعة", startPage: 600),
  Surah(name: "التکاثر", startPage: 600),
  Surah(name: "العصر", startPage: 601),
  Surah(name: "الهمزة", startPage: 601),
  Surah(name: "الفیل", startPage: 601),
  Surah(name: "قریش", startPage: 602),
  Surah(name: "الماعون", startPage: 602),
  Surah(name: "الکوثر", startPage: 602),
  Surah(name: "الکافرون", startPage: 603),
  Surah(name: "النصر", startPage: 603),
  Surah(name: "المسد", startPage: 603),
  Surah(name: "الإخلاص", startPage: 604),
  Surah(name: "الفلق", startPage: 604),
  Surah(name: "الناس", startPage: 604),
];

enum RepeatModeX { off, oneAyah, page }

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({super.key});

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();

  // ===== Prefs =====
  bool _nightMode = false;
  String _qariKey = 'Ayman_Sowaid';
  String _lang = 'fa';
  bool _autoNext = true;
  RepeatModeX _repeatMode = RepeatModeX.off;
  double _speed = 1.0;
  bool _showSubtitle = true;

  // ===== selection =====
  int _currentPage = 1; // 1..604
  String? _selectedAyahKey;
  List<AyahBox> _selectedAyahBoxes = [];
  bool _actionBarVisible = false;

  // ===== caches =====
  final Map<int, Future<Size>> _imageSizeFutureCache = {};
  final Map<int, Future<List<AyahBox>>> _boxesFutureCache = {};
  final Map<int, List<AyahBox>> _boxesCache = {};
  final Map<int, List<String>> _orderCache = {};

  // ===== ayah data map (translations) =====
  Map<String, AyahData> _ayahDataMap = {};
  bool _ayahDataLoaded = false;

  // ===== audio =====
  late final AudioPlayer _audioPlayer;
  String? _currentPlayingAyahKey;

  // جلوگیری از چندبار تریگر شدن completed و/یا هم‌زمان شدن playها
  bool _handlingCompleted = false;
  int _playSeq = 0;

  // ===== bookmarks =====
  final Set<String> _bookmarkedAyahKeys = <String>{};

  // ===== local qaris =====
  final Map<String, String> _localQaris = {
    'Ayman_Sowaid': 'assets/audio/Ayman_Sowaid/',
    'Fares_Abbad': 'assets/audio/Fares_Abbad/',
    'Ali_Jaber': 'assets/audio/Ali_Jaber/',
    'Alafasy': 'assets/audio/Alafasy/',
  };

  // ===== prefs keys =====
  static const _kNight = 'night_mode';
  static const _kQari = 'last_qari_key';
  static const _kLang = 'last_lang';
  static const _kLastPage = 'last_page';
  static const _kBookmarks = 'bookmarks';
  static const _kAutoNext = 'auto_next';
  static const _kRepeat = 'repeat_mode';
  static const _kSpeed = 'playback_speed';
  static const _kShowSubtitle = 'show_translation_subtitle';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _audioPlayer = AudioPlayer();
    _initAudioSession();

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onCompleted(); // بدون await، ولی داخل خودش guard دارد
      }
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadPrefs();
    await _loadBookmarks();
    await _loadAyahData();
    await _loadLastPageAndJump();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /* ------------------ PREFS ------------------ */

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nightMode = prefs.getBool(_kNight) ?? false;
      _qariKey = prefs.getString(_kQari) ?? 'Ayman_Sowaid';
      _lang = prefs.getString(_kLang) ?? 'fa';
      _autoNext = prefs.getBool(_kAutoNext) ?? true;
      _speed = prefs.getDouble(_kSpeed) ?? 1.0;
      _showSubtitle = prefs.getBool(_kShowSubtitle) ?? true;

      final r = prefs.getString(_kRepeat) ?? 'off';
      _repeatMode = switch (r) {
        'one' => RepeatModeX.oneAyah,
        'page' => RepeatModeX.page,
        _ => RepeatModeX.off,
      };
    });

    try {
      await _audioPlayer.setSpeed(_speed);
    } catch (_) {}
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNight, _nightMode);
    await prefs.setString(_kQari, _qariKey);
    await prefs.setString(_kLang, _lang);
    await prefs.setBool(_kAutoNext, _autoNext);
    await prefs.setDouble(_kSpeed, _speed);
    await prefs.setBool(_kShowSubtitle, _showSubtitle);

    final r = switch (_repeatMode) {
      RepeatModeX.oneAyah => 'one',
      RepeatModeX.page => 'page',
      RepeatModeX.off => 'off',
    };
    await prefs.setString(_kRepeat, r);
  }

  Future<void> _loadLastPageAndJump() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastPage) ?? 0; // PageView index
    final targetIndex = last.clamp(0, 603);
    _currentPage = targetIndex + 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pageController.jumpToPage(targetIndex);
      setState(() {});
    });
  }

  Future<void> _saveLastPage(int pageIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastPage, pageIndex);
  }

  /* ------------------ BOOKMARKS ------------------ */

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kBookmarks) ?? <String>[];
    setState(() {
      _bookmarkedAyahKeys
        ..clear()
        ..addAll(list.map((e) => e.trim()).where((e) => e.isNotEmpty));
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kBookmarks, _bookmarkedAyahKeys.toList());
  }

  Future<void> _toggleBookmark(String ayahKey) async {
    final k = ayahKey.trim();
    if (k.isEmpty) return;

    setState(() {
      if (_bookmarkedAyahKeys.contains(k)) {
        _bookmarkedAyahKeys.remove(k);
      } else {
        _bookmarkedAyahKeys.add(k);
      }
    });
    await _saveBookmarks();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        content: Text(
          _bookmarkedAyahKeys.contains(k)
              ? 'به نشانک‌ها اضافه شد'
              : 'از نشانک‌ها حذف شد',
        ),
      ),
    );
  }

  /* ------------------ AYAH DATA (TRANSLATIONS) ------------------ */

  Future<void> _loadAyahData() async {
    try {
      final raw = await rootBundle.loadString('assets/ayah_data/ayahs.json');
      final List list = json.decode(raw);

      final map = <String, AyahData>{};

      for (final e0 in list) {
        final e = e0 as Map;
        final sura = (e['chapter_number'] as num).toInt();
        final ayah = (e['Ayah_number'] as num).toInt();
        final key = '${sura}_$ayah';

        final translations = <String, String>{};
        e.forEach((k, v) {
          final ks = k.toString();
          if (ks.startsWith('content_') && v is String) {
            final lang = ks.replaceFirst('content_', '').trim();
            translations[lang] = v;
          }
        });

        map[key] = AyahData(
          ayahKey: key,
          sura: sura,
          ayah: ayah,
          translations: translations,
        );
      }

      if (!mounted) return;
      setState(() {
        _ayahDataMap = map;
        _ayahDataLoaded = true;
      });
    } catch (e) {
      debugPrint('AyahData load error: $e');
      if (!mounted) return;
      setState(() => _ayahDataLoaded = false);
    }
  }

  AyahData? _ayahDataOf(String? ayahKey) {
    if (!_ayahDataLoaded || ayahKey == null) return null;
    return _ayahDataMap[ayahKey.trim()];
  }

  /* ------------------ IMAGE SIZE / BBOX LOAD (CACHED) ------------------ */

  Future<Size> _getImageSize(int page) {
    return _imageSizeFutureCache.putIfAbsent(page, () async {
      final data = await rootBundle
          .load('assets/page_webp/page_${page.toString().padLeft(3, '0')}.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final img = frame.image;
      return Size(img.width.toDouble(), img.height.toDouble());
    });
  }

  Future<List<AyahBox>> _loadAyahBoxes(int page) {
    return _boxesFutureCache.putIfAbsent(page, () async {
      final path =
          'assets/bboxes_final/page_${page.toString().padLeft(3, '0')}.json';
      try {
        final raw = await rootBundle.loadString(path);
        final decoded = json.decode(raw);

        final List list = decoded is Map ? (decoded['bboxes'] as List) : decoded;

        final boxes = list.map((e0) {
          final e = e0 as Map;
          final b =
          (e['bbox'] as List).map((x) => (x as num).toDouble()).toList();
          return AyahBox(
            rect: Rect.fromLTWH(b[0], b[1], b[2], b[3]),
            ayahKey: (e['ayahKey'] ?? '').toString().trim(),
            ayahId: ((e['ayahid'] ?? 0) as num).toInt(),
          );
        }).toList();

        _boxesCache[page] = boxes;
        _orderCache[page] = _buildAyahOrder(boxes);
        return boxes;
      } catch (e) {
        debugPrint('BBoxes load error page=$page: $e');
        _boxesCache[page] = [];
        _orderCache[page] = [];
        return [];
      }
    });
  }

  // ====== ترتیب‌دهی درست: اول با ayahId اگر معتبر بود، وگرنه با "خواندن صفحه" (بالا->پایین، راست->چپ)
  List<String> _buildAyahOrder(List<AyahBox> boxes) {
    // تجمیع bbox های یک آیه (ممکن است چند تکه باشد)
    final Map<String, _AyahAgg> agg = {};
    for (final b in boxes) {
      final k = b.ayahKey.trim();
      if (k.isEmpty) continue;
      final a = agg.putIfAbsent(
        k,
            () => _AyahAgg(key: k, rect: b.rect, minId: b.ayahId > 0 ? b.ayahId : 0),
      );
      a.rect = a.rect.expandToInclude(b.rect);
      if (b.ayahId > 0) {
        if (a.minId == 0 || b.ayahId < a.minId) a.minId = b.ayahId;
      }
    }

    final items = agg.values.toList();
    if (items.isEmpty) return const <String>[];

    // اگر اکثر آیتم‌ها ayahId معتبر داشتند و یکتا بود، بر اساس ayahId مرتب کن
    final nonZero = items.where((e) => e.minId > 0).toList();
    final uniqueIds = nonZero.map((e) => e.minId).toSet();
    final useId = nonZero.length >= (items.length * 0.7) &&
        uniqueIds.length == nonZero.length;

    if (useId) {
      items.sort((a, b) => a.minId.compareTo(b.minId));
      return items.map((e) => e.key).toList(growable: false);
    }

    // fallback: بر اساس موقعیت bbox (خواندن صفحه)
    final heights = items.map((e) => e.rect.height).where((h) => h > 0).toList()
      ..sort();
    final medianH =
    heights.isEmpty ? 40.0 : heights[heights.length ~/ 2].toDouble();
    final lineTol = medianH * 0.75;

    // اول بر اساس top مرتب، بعد خط‌بندی، بعد داخل هر خط RTL
    items.sort((a, b) => a.rect.top.compareTo(b.rect.top));

    final List<_Line> lines = [];
    for (final it in items) {
      if (lines.isEmpty) {
        lines.add(_Line(y: it.rect.top, items: [it]));
        continue;
      }
      final last = lines.last;
      if ((it.rect.top - last.y).abs() <= lineTol) {
        last.items.add(it);
        // آپدیت y به میانگین برای پایداری
        last.y = (last.y * (last.items.length - 1) + it.rect.top) / last.items.length;
      } else {
        lines.add(_Line(y: it.rect.top, items: [it]));
      }
    }

    for (final ln in lines) {
      // راست به چپ: right بزرگتر اول
      ln.items.sort((a, b) => b.rect.right.compareTo(a.rect.right));
    }

    final ordered = <String>[];
    for (final ln in lines) {
      ordered.addAll(ln.items.map((e) => e.key));
    }

    return ordered;
  }

  /* ------------------ FIT / COORDINATES ------------------ */

  Rect _containRect({required Size imageSize, required Size widgetSize}) {
    final fitted = applyBoxFit(BoxFit.contain, imageSize, widgetSize);
    final dstSize = fitted.destination;
    final dx = (widgetSize.width - dstSize.width) / 2.0;
    final dy = (widgetSize.height - dstSize.height) / 2.0;
    return Rect.fromLTWH(dx, dy, dstSize.width, dstSize.height);
  }

  Offset _widgetToImage({
    required Offset pWidget,
    required Rect dstRect,
    required Size imageSize,
  }) {
    final local = pWidget - dstRect.topLeft;
    final sx = imageSize.width / dstRect.width;
    final sy = imageSize.height / dstRect.height;
    return Offset(local.dx * sx, local.dy * sy);
  }

  Rect _imageRectToWidget({
    required Rect rImage,
    required Rect dstRect,
    required Size imageSize,
  }) {
    final sx = dstRect.width / imageSize.width;
    final sy = dstRect.height / imageSize.height;

    return Rect.fromLTWH(
      dstRect.left + rImage.left * sx,
      dstRect.top + rImage.top * sy,
      rImage.width * sx,
      rImage.height * sy,
    );
  }

  /* ------------------ HIT TEST ------------------ */

  AyahBox? _hitTest({
    required Offset tapWidget,
    required Rect dstRect,
    required Size imageSize,
    required List<AyahBox> boxes,
  }) {
    if (!dstRect.contains(tapWidget)) return null;

    final pImg = _widgetToImage(
      pWidget: tapWidget,
      dstRect: dstRect,
      imageSize: imageSize,
    );

    final hits = boxes.where((b) => b.rect.contains(pImg)).toList();
    if (hits.isEmpty) return null;

    // smallest bbox first (overlap)
    hits.sort((a, b) {
      final areaA = a.rect.width * a.rect.height;
      final areaB = b.rect.width * b.rect.height;
      return areaA.compareTo(areaB);
    });

    return hits.first;
  }

  void _clearSelection() {
    setState(() {
      _selectedAyahKey = null;
      _selectedAyahBoxes = [];
      _actionBarVisible = false;
    });
  }

  void _hideActionBarOnly() {
    if (!_actionBarVisible) return;
    setState(() => _actionBarVisible = false);
  }

  Future<void> _ensurePageCacheReady(int page) async {
    if (_boxesCache.containsKey(page) && _orderCache.containsKey(page)) return;
    await _loadAyahBoxes(page);
  }

  Future<void> _selectAyahOnCurrentPage(
      String ayahKey, {
        required bool showActionBar,
      }) async {
    final k = ayahKey.trim();
    if (k.isEmpty) return;

    await _ensurePageCacheReady(_currentPage);

    final boxes = _boxesCache[_currentPage] ?? const <AyahBox>[];
    final group = boxes.where((b) => b.ayahKey.trim() == k).toList();

    if (!mounted) return;
    setState(() {
      _selectedAyahKey = k;
      _selectedAyahBoxes = group;
      _actionBarVisible = showActionBar;
    });
  }

  /* ------------------ AUDIO HELPERS ------------------ */

  String _ayahKeyToFileName(String ayahKey) {
    final parts = ayahKey.trim().split('_');
    if (parts.length != 2) return '000000.mp3';
    final sura = parts[0].padLeft(3, '0');
    final ayah = parts[1].padLeft(3, '0');
    return '$sura$ayah.mp3'; // 001001.mp3
  }

  String _assetPathFor(String ayahKey, {String? qariKey}) {
    final qari = qariKey ?? _qariKey;
    final base = _localQaris[qari] ?? _localQaris.values.first;
    return '$base${_ayahKeyToFileName(ayahKey)}';
  }

  // نکته مهم: هر بار play می‌کنیم، هم currentPlaying و هم selection و subtitle sync می‌شود.
  Future<void> _playAyah(
      String ayahKey, {
        bool showActionBar = false,
      }) async {
    final k = ayahKey.trim();
    if (k.isEmpty) return;

    final seq = ++_playSeq;

    try {
      await _ensurePageCacheReady(_currentPage);

      // sync selection + highlight + subtitle
      _currentPlayingAyahKey = k;
      await _selectAyahOnCurrentPage(k, showActionBar: showActionBar);

      await _audioPlayer.stop();
      await _audioPlayer.setSpeed(_speed);

      // اگر وسطش play دیگری آمد، این یکی را ادامه نده
      if (seq != _playSeq) return;

      await _audioPlayer.setAsset(_assetPathFor(k));
      if (seq != _playSeq) return;

      await _audioPlayer.play();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Audio error: $e');
      if (!mounted) return;
      // اگر این play قدیمی شده، snackbar نده
      if (seq != _playSeq) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در پخش فایل صوتی آیه: $k')),
      );
    }
  }

  Future<void> _togglePlayPause() async {
    final key = (_selectedAyahKey ?? _currentPlayingAyahKey)?.trim();
    if (key == null || key.isEmpty) return;

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      if (mounted) setState(() {});
      return;
    }

    if (_audioPlayer.processingState == ProcessingState.idle ||
        _audioPlayer.processingState == ProcessingState.completed) {
      await _playAyah(key, showActionBar: false);
    } else {
      await _audioPlayer.play();
      if (mounted) setState(() {});
    }
  }

  Future<void> _onCompleted() async {
    if (_handlingCompleted) return;
    _handlingCompleted = true;
    try {
      if (_repeatMode == RepeatModeX.oneAyah) {
        final k = _currentPlayingAyahKey;
        if (k != null) {
          await _playAyah(k, showActionBar: false);
        }
        return;
      }

      if (_autoNext) {
        await _playNextAyah();
        return;
      }

      if (mounted) setState(() {});
    } finally {
      _handlingCompleted = false;
    }
  }

  Future<void> _playNextAyah() async {
    final current = (_currentPlayingAyahKey ?? _selectedAyahKey)?.trim();
    if (current == null || current.isEmpty) return;

    final order = _orderCache[_currentPage] ?? const <String>[];
    if (order.isEmpty) return;

    final idx = order.indexWhere((k) => k.trim() == current);
    if (idx == -1) return;

    if (idx + 1 >= order.length) {
      if (_repeatMode == RepeatModeX.page) {
        await _playAyah(order.first, showActionBar: false);
      } else {
        _currentPlayingAyahKey = null;
        if (mounted) setState(() {});
      }
      return;
    }

    await _playAyah(order[idx + 1], showActionBar: false);
  }

  Future<void> _playPrevAyah() async {
    final current = (_currentPlayingAyahKey ?? _selectedAyahKey)?.trim();
    if (current == null || current.isEmpty) return;

    final order = _orderCache[_currentPage] ?? const <String>[];
    if (order.isEmpty) return;

    final idx = order.indexWhere((k) => k.trim() == current);
    if (idx <= 0) return;

    await _playAyah(order[idx - 1], showActionBar: false);
  }

  Future<void> _stopAudio() async {
    ++_playSeq; // هر play قبلی را invalid کن
    await _audioPlayer.stop();
    setState(() {
      _currentPlayingAyahKey = null;
    });
  }

  /* ------------------ UI ACTIONS ------------------ */

  Future<void> _goToPage(int page) async {
    final p = page.clamp(1, 604);
    final index = p - 1;

    _clearSelection();
    await _stopAudio();
    _pageController.jumpToPage(index);
    await _saveLastPage(index);

    setState(() {
      _currentPage = p;
    });
  }

  Future<void> _goToPageDialog() async {
    final controller = TextEditingController(text: _currentPage.toString());
    final page = await showDialog<int?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('رفتن به صفحه'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'عدد 1 تا 604'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.pop(context, n);
            },
            child: const Text('رفتن'),
          ),
        ],
      ),
    );

    if (page == null) return;
    await _goToPage(page);
  }

  void _showQariSelector() {
    final qaris = _localQaris.keys.toList()..sort();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          children: qaris.map((k) {
            final isCurrent = k == _qariKey;
            return ListTile(
              leading: Icon(isCurrent ? Icons.check_circle : Icons.person),
              title: Text(k),
              subtitle: Text(
                _localQaris[k]!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _qariKey = k);
                await _savePrefs();

                final playingKey = _currentPlayingAyahKey;
                if (playingKey != null) {
                  await _playAyah(playingKey, showActionBar: false);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLangSelector() {
    final key = _currentPlayingAyahKey ?? _selectedAyahKey;
    if (key == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اول یک آیه را انتخاب کنید')),
      );
      return;
    }

    final ayah = _ayahDataOf(key);
    if (ayah == null || ayah.translations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ترجمه برای این آیه موجود نیست')),
      );
      return;
    }

    final langs = ayah.translations.keys.toList()..sort();
    if (langs.contains(_lang)) {
      langs.remove(_lang);
      langs.insert(0, _lang);
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          children: langs.map((l) {
            return ListTile(
              leading: Icon(l == _lang ? Icons.check_circle : Icons.translate),
              title: Text(l),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _lang = l);
                await _savePrefs();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBookmarksSheet() {
    final list = _bookmarkedAyahKeys.toList()
      ..sort((a, b) {
        final pa = a.split('_');
        final pb = b.split('_');
        final sa = int.tryParse(pa[0]) ?? 0;
        final sb = int.tryParse(pb[0]) ?? 0;
        if (sa != sb) return sa.compareTo(sb);
        final aa = int.tryParse(pa[1]) ?? 0;
        final ab = int.tryParse(pb[1]) ?? 0;
        return aa.compareTo(ab);
      });

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: list.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(16),
          child: Text('هیچ نشانکی ندارید'),
        )
            : ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final key = list[i];
            return ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text('آیه $key'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _toggleBookmark(key),
              ),
              onTap: () {
                Navigator.pop(context);
                _selectAyahOnCurrentPage(key, showActionBar: true);
              },
            );
          },
        ),
      ),
    );
  }

  void _showSpeedSheet() {
    const speeds = [0.75, 0.9, 1.0, 1.1, 1.25, 1.5];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('سرعت پخش', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...speeds.map((s) {
              final isCurrent = (s - _speed).abs() < 0.001;
              return ListTile(
                leading: Icon(isCurrent ? Icons.check_circle : Icons.speed),
                title: Text('${s}x'),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _speed = s);
                  await _audioPlayer.setSpeed(_speed);
                  await _savePrefs();
                },
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _cycleRepeatMode() async {
    setState(() {
      _repeatMode = switch (_repeatMode) {
        RepeatModeX.off => RepeatModeX.oneAyah,
        RepeatModeX.oneAyah => RepeatModeX.page,
        RepeatModeX.page => RepeatModeX.off,
      };
    });
    await _savePrefs();
  }

  void _showSurahSearchSheet() {
    final controller = TextEditingController();
    List<Surah> filtered = surahList;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void applyFilter(String q) {
              final qq = q.trim();
              if (qq.isEmpty) {
                setSheet(() => filtered = surahList);
                return;
              }
              setSheet(() {
                filtered = surahList
                    .where((s) => s.name.contains(qq))
                    .toList(growable: false);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'جستجوی سوره...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: applyFilter,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.65,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        return ListTile(
                          title: Text(s.name),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _goToPage(s.startPage);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /* ------------------ SUBTITLE (TRANSLATION) ------------------ */

  String _currentSubtitleText() {
    if (!_showSubtitle) return '';
    final key = _currentPlayingAyahKey ?? _selectedAyahKey;
    if (key == null) return '';
    final ayah = _ayahDataOf(key);
    final t = ayah?.translations[_lang] ?? '';
    return t.trim();
  }

  /* ------------------ MAIN BUILD ------------------ */

  @override
  Widget build(BuildContext context) {
    final bg = _nightMode ? const Color(0xFF0F0F10) : AppColors.cream;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.gold,
        title: Text('صفحه $_currentPage'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'night') {
                setState(() => _nightMode = !_nightMode);
                await _savePrefs();
              } else if (v == 'goto') {
                await _goToPageDialog();
              } else if (v == 'stop') {
                await _stopAudio();
              } else if (v == 'subtitle') {
                setState(() => _showSubtitle = !_showSubtitle);
                await _savePrefs();
              } else if (v == 'surah') {
                _showSurahSearchSheet();
              } else if (v == 'qari') {
                _showQariSelector();
              } else if (v == 'lang') {
                _showLangSelector();
              } else if (v == 'bookmarks') {
                _showBookmarksSheet();
              } else if (v == 'speed') {
                _showSpeedSheet();
              } else if (v == 'repeat') {
                _cycleRepeatMode();
              } else if (v == 'autonext') {
                setState(() => _autoNext = !_autoNext);
                await _savePrefs();
              } else if (v == 'prev') {
                await _playPrevAyah();
              } else if (v == 'next') {
                await _playNextAyah();
              } else if (v == 'playpause') {
                await _togglePlayPause();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'surah', child: Text('جستجوی سوره')),
              const PopupMenuItem(value: 'goto', child: Text('رفتن به صفحه...')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'qari', child: Text('انتخاب قاری')),
              const PopupMenuItem(value: 'lang', child: Text('زبان ترجمه')),
              PopupMenuItem(
                value: 'subtitle',
                child: Text(_showSubtitle ? 'زیرنویس ترجمه: روشن' : 'زیرنویس ترجمه: خاموش'),
              ),
              const PopupMenuItem(value: 'bookmarks', child: Text('نشانک‌ها')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'autonext',
                child: Text(_autoNext ? 'پخش پشت‌سرهم: روشن' : 'پخش پشت‌سرهم: خاموش'),
              ),
              PopupMenuItem(
                value: 'repeat',
                child: Text(switch (_repeatMode) {
                  RepeatModeX.off => 'تکرار: خاموش',
                  RepeatModeX.oneAyah => 'تکرار: همین آیه',
                  RepeatModeX.page => 'تکرار: صفحه',
                }),
              ),
              const PopupMenuItem(value: 'speed', child: Text('سرعت پخش')),
              const PopupMenuItem(value: 'playpause', child: Text('پخش/توقف موقت')),
              const PopupMenuItem(value: 'prev', child: Text('آیه قبلی')),
              const PopupMenuItem(value: 'next', child: Text('آیه بعدی')),
              const PopupMenuItem(value: 'stop', child: Text('توقف پخش')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'night',
                child: Text(_nightMode ? 'حالت روز' : 'حالت شب'),
              ),
            ],
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: PageView.builder(
          controller: _pageController,
          itemCount: 604,
          onPageChanged: (index) async {
            final page = index + 1;

            await _stopAudio();
            _clearSelection();
            await _saveLastPage(index);

            setState(() {
              _currentPage = page;
            });
          },
          itemBuilder: (context, index) {
            final page = index + 1;
            final asset =
                'assets/page_webp/page_${page.toString().padLeft(3, '0')}.webp';

            return FutureBuilder<List<AyahBox>>(
              future: _loadAyahBoxes(page),
              builder: (context, snapBoxes) {
                final boxes = snapBoxes.data ?? const <AyahBox>[];

                return FutureBuilder<Size>(
                  future: _getImageSize(page),
                  builder: (context, snapSize) {
                    final imgSize = snapSize.data;
                    if (imgSize == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return LayoutBuilder(
                      builder: (context, cons) {
                        final widgetSize = Size(cons.maxWidth, cons.maxHeight);
                        final dstRect = _containRect(
                          imageSize: imgSize,
                          widgetSize: widgetSize,
                        );

                        final subtitle = _currentSubtitleText();

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) async {
                            final hit = _hitTest(
                              tapWidget: d.localPosition,
                              dstRect: dstRect,
                              imageSize: imgSize,
                              boxes: boxes,
                            );

                            if (hit == null) {
                              _clearSelection();
                            } else {
                              // ✅ فقط یک بار play (نه دوبار)
                              await _playAyah(hit.ayahKey, showActionBar: true);
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColorFiltered(
                                colorFilter: _nightMode
                                    ? const ColorFilter.mode(
                                    Colors.black87, BlendMode.modulate)
                                    : const ColorFilter.mode(
                                    Colors.transparent, BlendMode.multiply),
                                child: Image.asset(
                                  asset,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),

                              if (page == _currentPage)
                                ..._buildHighlights(
                                  imgSize: imgSize,
                                  dstRect: dstRect,
                                ),

                              if (page == _currentPage &&
                                  _actionBarVisible &&
                                  _selectedAyahKey != null &&
                                  _selectedAyahBoxes.isNotEmpty)
                                _AyahActionBar(
                                  anchorRect: _imageRectToWidget(
                                    rImage: _selectedAyahBoxes
                                        .map((e) => e.rect)
                                        .reduce((a, b) => a.expandToInclude(b)),
                                    dstRect: dstRect,
                                    imageSize: imgSize,
                                  ),
                                  isBookmarked: _bookmarkedAyahKeys
                                      .contains(_selectedAyahKey),
                                  isPlaying: (_currentPlayingAyahKey ==
                                      _selectedAyahKey) &&
                                      _audioPlayer.playing,
                                  onPlayPause: () async {
                                    _hideActionBarOnly();
                                    await _togglePlayPause();
                                  },
                                  onBookmark: () async {
                                    final k = _selectedAyahKey;
                                    if (k == null) return;
                                    _hideActionBarOnly();
                                    await _toggleBookmark(k);
                                  },
                                  onCopy: () async {
                                    final k = _selectedAyahKey;
                                    if (k == null) return;
                                    _hideActionBarOnly();
                                    await _copyAyahTranslation(k);
                                  },
                                  onShare: () {
                                    final k = _selectedAyahKey;
                                    if (k == null) return;
                                    _hideActionBarOnly();
                                    _shareAyahText(k);
                                  },
                                ),

                              if (page == _currentPage && subtitle.isNotEmpty)
                                _SubtitleBar(
                                  text: subtitle,
                                  nightMode: _nightMode,
                                  onClose: () {
                                    setState(() => _showSubtitle = false);
                                    _savePrefs();
                                  },
                                ),

                              Positioned(
                                bottom: (subtitle.isNotEmpty && page == _currentPage)
                                    ? 64
                                    : 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '$_currentPage / 604',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildHighlights({
    required Size imgSize,
    required Rect dstRect,
  }) {
    if (_selectedAyahKey == null || _selectedAyahBoxes.isEmpty) return const [];

    return _selectedAyahBoxes.map((b) {
      final isPlayingThis =
          (b.ayahKey.trim() == _currentPlayingAyahKey?.trim()) && _audioPlayer.playing;

      final r = _imageRectToWidget(
        rImage: b.rect,
        dstRect: dstRect,
        imageSize: imgSize,
      );

      final clamped = Rect.fromLTRB(
        r.left.clamp(dstRect.left, dstRect.right),
        r.top.clamp(dstRect.top, dstRect.bottom),
        r.right.clamp(dstRect.left, dstRect.right),
        r.bottom.clamp(dstRect.top, dstRect.bottom),
      );

      return Positioned(
        left: clamped.left,
        top: clamped.top,
        width: clamped.width,
        height: clamped.height,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: isPlayingThis
                  ? Colors.orange.withOpacity(0.35)
                  : Colors.amber.withOpacity(0.22),
              border: Border.all(
                color: isPlayingThis ? Colors.deepOrange : Colors.amber,
                width: isPlayingThis ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _copyAyahTranslation(String ayahKey) async {
    final ayah = _ayahDataOf(ayahKey);
    final t = ayah?.translations[_lang] ?? '';
    if (t.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متن ترجمه برای کپی موجود نیست')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: t));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('کپی شد')),
    );
  }

  void _shareAyahText(String ayahKey) {
    _copyAyahTranslation(ayahKey);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('برای اشتراک‌گذاری، متن ترجمه کپی شد (Paste کنید)'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/* ========================= HELPERS ========================= */

class _AyahAgg {
  final String key;
  Rect rect;
  int minId;
  _AyahAgg({required this.key, required this.rect, required this.minId});
}

class _Line {
  double y;
  final List<_AyahAgg> items;
  _Line({required this.y, required this.items});
}

/* ========================= WIDGETS ========================= */

class _AyahActionBar extends StatelessWidget {
  final Rect anchorRect;
  final bool isBookmarked;
  final bool isPlaying;

  final VoidCallback onPlayPause;
  final VoidCallback onBookmark;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _AyahActionBar({
    required this.anchorRect,
    required this.isBookmarked,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onBookmark,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    final top = (anchorRect.top - 56).clamp(8.0, screen.height - 200);
    final left = (anchorRect.center.dx - 110).clamp(8.0, screen.width - 220);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: isPlaying ? 'توقف موقت' : 'پخش',
                onPressed: onPlayPause,
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                tooltip: isBookmarked ? 'حذف نشانک' : 'افزودن نشانک',
                onPressed: onBookmark,
                icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_add),
              ),
              IconButton(
                tooltip: 'کپی ترجمه',
                onPressed: onCopy,
                icon: const Icon(Icons.copy),
              ),
              IconButton(
                tooltip: 'اشتراک',
                onPressed: onShare,
                icon: const Icon(Icons.share),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtitleBar extends StatelessWidget {
  final String text;
  final bool nightMode;
  final VoidCallback onClose;

  const _SubtitleBar({
    required this.text,
    required this.nightMode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bg = nightMode
        ? Colors.black.withOpacity(0.72)
        : Colors.black.withOpacity(0.55);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: bg,
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, -2),
                color: Colors.black.withOpacity(0.20),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'بستن زیرنویس',
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
