import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NextPrayer {
  final String name;
  final DateTime time;
  NextPrayer({required this.name, required this.time});
}

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({Key? key}) : super(key: key);

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage>
    with SingleTickerProviderStateMixin {
  PrayerTimes? times;
  Timer? _timer;

  bool isLoading = true;

  // نمایش
  String cityName = "";
  String countryName = "";
  String areaName = ""; // مثلا استان/منطقه
  String nextPrayerName = "";
  String remainingTime = "--:--:--";
  String hijriDate = "";

  // ورودی‌ها
  String latitudeInput = '';
  String longitudeInput = '';
  String cityInput = '';

  // منبع موقعیت
  String locationSource = 'GPS'; // GPS / City / Coordinates

  // تنظیمات محاسبه
  CalculationMethod selectedMethod = CalculationMethod.umm_al_qura;
  Madhab selectedSchool = Madhab.shafi;

  bool showSettings = false;
  late AnimationController _animationController;

  late TextEditingController _cityController;
  late TextEditingController _latController;
  late TextEditingController _lonController;

  @override
  void initState() {
    super.initState();

    hijriDate = HijriCalendar.now().toFormat("dd MMMM yyyy");

    _cityController = TextEditingController();
    _latController = TextEditingController();
    _lonController = TextEditingController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _setup();
    _startTimer();
  }

  Future<void> _setup() async {
    await _loadPreferences();
    await _initializeFromPrefsOrFetchIfNeeded();
  }

  /// منطق اصلی:
  /// - اگر GPS انتخاب شده و مختصات ذخیره شده => مستقیم استفاده کن (بدون GPS/Geocode)
  /// - اگر City => از اسم شهر مختصات بگیر + ذخیره کن
  /// - اگر Coordinates => reverseGeocode کن + ذخیره کن
  Future<void> _initializeFromPrefsOrFetchIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    locationSource = prefs.getString('locationSource') ?? 'GPS';

    // رشته‌های ذخیره شده برای نمایش (بدون reverseGeocode مجدد)
    cityName = prefs.getString('cached_cityName') ?? '';
    countryName = prefs.getString('cached_countryName') ?? '';
    areaName = prefs.getString('cached_areaName') ?? '';

    final savedLat = prefs.getDouble('latitude');
    final savedLon = prefs.getDouble('longitude');

    if (locationSource == 'GPS') {
      if (savedLat != null && savedLon != null) {
        latitudeInput = savedLat.toString();
        longitudeInput = savedLon.toString();
        _latController.text = latitudeInput;
        _lonController.text = longitudeInput;

        await _loadPrayerTimesWithCoords(Coordinates(savedLat, savedLon));
        _safeSetState(() {});
        return;
      }

      // اولین بار: باید GPS بگیریم
      await _detectLocationAndCache(forceRefresh: false);
      return;
    }

    if (locationSource == 'City') {
      cityInput = prefs.getString('cityInput') ?? '';
      _cityController.text = cityInput;

      if (cityInput.trim().isEmpty) {
        _safeSetState(() => isLoading = false);
        return;
      }

      await _resolveCityToCoordsAndLoad(cityInput, cacheSource: true);
      return;
    }

    // Coordinates
    if (locationSource == 'Coordinates') {
      if (savedLat != null && savedLon != null) {
        latitudeInput = savedLat.toString();
        longitudeInput = savedLon.toString();
      } else {
        latitudeInput = prefs.getString('latitude') ?? '';
        longitudeInput = prefs.getString('longitude') ?? '';
      }

      _latController.text = latitudeInput;
      _lonController.text = longitudeInput;

      final lat = double.tryParse(latitudeInput);
      final lon = double.tryParse(longitudeInput);
      if (lat == null || lon == null) {
        _showMessage('مختصات نامعتبر است');
        _safeSetState(() => isLoading = false);
        return;
      }

      final coords = Coordinates(lat, lon);
      await _loadPrayerTimesWithCoords(coords);

      // اگر نام منطقه ذخیره نشده بود، یک بار reverseGeocode کن و ذخیره کن
      if ((cityName.isEmpty && areaName.isEmpty && countryName.isEmpty)) {
        await _reverseGeocodeAndCache(lat, lon);
        _safeSetState(() {});
      }

      return;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (times == null) return;

      final next = _getNextPrayerTime();
      if (next == null) return;

      // هر ثانیه فقط همین دو مقدار را آپدیت کنیم
      setState(() {
        nextPrayerName = next.name;
        remainingTime = _calculateTimeRemaining(next.time);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  // ---------------------------
  // Preferences
  // ---------------------------

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCity = prefs.getString('cityInput') ?? '';
    final latDouble = prefs.getDouble('latitude');
    final lonDouble = prefs.getDouble('longitude');

    locationSource = prefs.getString('locationSource') ?? 'GPS';

    selectedMethod = CalculationMethod.values[
    prefs.getInt('calculationMethod') ??
        CalculationMethod.umm_al_qura.index];

    selectedSchool = Madhab.values[
    prefs.getInt('madhab') ?? Madhab.shafi.index];

    cityInput = savedCity;
    latitudeInput = latDouble?.toString() ?? (prefs.getString('latitude') ?? '');
    longitudeInput = lonDouble?.toString() ?? (prefs.getString('longitude') ?? '');

    _cityController.text = cityInput;
    _latController.text = latitudeInput;
    _lonController.text = longitudeInput;

    _safeSetState(() {});
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locationSource', locationSource);
    await prefs.setInt('calculationMethod', selectedMethod.index);
    await prefs.setInt('madhab', selectedSchool.index);

    // ذخیره ورودی‌ها
    await prefs.setString('cityInput', cityInput);

    final lat = double.tryParse(latitudeInput);
    final lon = double.tryParse(longitudeInput);
    if (lat != null && lon != null) {
      await prefs.setDouble('latitude', lat);
      await prefs.setDouble('longitude', lon);
    } else {
      await prefs.setString('latitude', latitudeInput);
      await prefs.setString('longitude', longitudeInput);
    }

    // ذخیره نام‌ها برای نمایش (بدون reverseGeocode دوباره)
    await prefs.setString('cached_cityName', cityName);
    await prefs.setString('cached_countryName', countryName);
    await prefs.setString('cached_areaName', areaName);
  }

  // ---------------------------
  // Location / Geocoding
  // ---------------------------

  Future<void> _detectLocationAndCache({required bool forceRefresh}) async {
    _safeSetState(() => isLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('سرویس GPS خاموش است');
        _safeSetState(() => isLoading = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('اجازه GPS داده نشد');
        _safeSetState(() => isLoading = false);
        return;
      }

      Position? position;

      // اگر forceRefresh نبود، اول lastKnown را بگیر (سریع)
      if (!forceRefresh) {
        position = await Geolocator.getLastKnownPosition();
      }

      // اگر نبود یا refresh بود، موقعیت جدید بگیر
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = position.latitude;
      final lon = position.longitude;

      latitudeInput = lat.toString();
      longitudeInput = lon.toString();
      _latController.text = latitudeInput;
      _lonController.text = longitudeInput;

      // بارگذاری اوقات
      await _loadPrayerTimesWithCoords(Coordinates(lat, lon));

      // یک بار reverseGeocode -> نمایش نام منطقه/شهر
      await _reverseGeocodeAndCache(lat, lon);

      // ذخیره همه چیز
      locationSource = 'GPS';
      await _savePreferences();

      _safeSetState(() => isLoading = false);
    } catch (e) {
      debugPrint("GPS ERROR: $e");
      _showMessage('خطا در دریافت موقعیت GPS');
      _safeSetState(() => isLoading = false);
    }
  }

  Future<void> _reverseGeocodeAndCache(double lat, double lon) async {
    try {
      final place = await placemarkFromCoordinates(lat, lon);
      if (place.isEmpty) return;

      final p = place.first;
      // locality ممکنه خالی باشه، پس fallback بهتر
      cityName = (p.locality?.trim().isNotEmpty == true)
          ? p.locality!.trim()
          : (p.subAdministrativeArea?.trim().isNotEmpty == true)
          ? p.subAdministrativeArea!.trim()
          : (p.administrativeArea?.trim().isNotEmpty == true)
          ? p.administrativeArea!.trim()
          : '';

      areaName = (p.administrativeArea ?? '').trim();
      countryName = (p.country ?? '').trim();

      await _savePreferences();
    } catch (_) {
      // اگر خطا داشت، بی‌خیال
    }
  }

  Future<void> _resolveCityToCoordsAndLoad(String city, {required bool cacheSource}) async {
    _safeSetState(() => isLoading = true);

    try {
      final query = city.trim();
      if (query.isEmpty) {
        _showMessage('نام شهر را وارد کنید');
        _safeSetState(() => isLoading = false);
        return;
      }

      // اگر کاربر فارسی می‌نویسد، geocoding معمولاً جواب می‌دهد.
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        _showMessage('شهر پیدا نشد');
        _safeSetState(() => isLoading = false);
        return;
      }

      final loc = locations.first;
      final coords = Coordinates(loc.latitude, loc.longitude);

      latitudeInput = loc.latitude.toString();
      longitudeInput = loc.longitude.toString();
      _latController.text = latitudeInput;
      _lonController.text = longitudeInput;

      // اوقات
      await _loadPrayerTimesWithCoords(coords);

      // reverseGeocode برای نمایش دقیق نام منطقه/کشور
      await _reverseGeocodeAndCache(loc.latitude, loc.longitude);

      // اگر user City انتخاب کرده، منبع را City ذخیره کن
      if (cacheSource) {
        locationSource = 'City';
        cityInput = query;
        // اگر reverseGeocode نام شهر را خالی داد، حداقل ورودی را نمایش بده
        if (cityName.isEmpty) cityName = query;
        await _savePreferences();
      }

      _safeSetState(() => isLoading = false);
    } catch (e) {
      debugPrint("CITY GEOCODE ERROR: $e");
      _showMessage('خطا در جستجوی شهر');
      _safeSetState(() => isLoading = false);
    }
  }

  // ---------------------------
  // Prayer times
  // ---------------------------

  Future<void> _loadPrayerTimesWithCoords(Coordinates coords) async {
    try {
      final now = DateTime.now();
      final params = selectedMethod.getParameters();
      params.madhab = selectedSchool;

      final result = PrayerTimes(coords, DateComponents.from(now), params);

      times = result;

      // نماز بعدی را فوراً یک بار حساب کن
      final next = _getNextPrayerTime();
      if (next != null) {
        nextPrayerName = next.name;
        remainingTime = _calculateTimeRemaining(next.time);
      }
    } catch (e) {
      debugPrint('Load prayer times error: $e');
      _showMessage('خطا در دریافت اوقات: ${e.toString()}');
      times = null;
    }
  }

  NextPrayer? _getNextPrayerTime() {
    if (times == null) return null;
    final now = DateTime.now();

    final prayerMap = <String, DateTime>{
      'فجر': times!.fajr,
      'ظهر': times!.dhuhr,
      'عصر': times!.asr,
      'مغرب': times!.maghrib,
      'عشاء': times!.isha,
    };

    for (final entry in prayerMap.entries) {
      if (entry.value.isAfter(now)) {
        return NextPrayer(name: entry.key, time: entry.value);
      }
    }

    // اگر همه گذشته بود => فجر فردا
    return NextPrayer(
      name: 'فجر',
      time: times!.fajr.add(const Duration(days: 1)),
    );
  }

  String _calculateTimeRemaining(DateTime target) {
    final now = DateTime.now();
    var diff = target.difference(now);
    if (diff.isNegative) diff += const Duration(days: 1);

    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ---------------------------
  // UI
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF8E1);
    const gold = Color(0xFFC9A227);
    const darkGold = Color(0xFF8C6D1F);

    final now = DateTime.now();
    final sunrise = times?.sunrise ?? DateTime(now.year, now.month, now.day, 6, 0);
    final sunset = times?.maghrib ?? DateTime(now.year, now.month, now.day, 18, 0);

    // هر بار build، تاریخ هجری را اگر روز عوض شد آپدیت کن
    hijriDate = HijriCalendar.now().toFormat("dd MMMM yyyy");

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: gold,
        title: const Text('اوقات شرعی'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تنظیمات',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              _safeSetState(() => showSettings = !showSettings);
              if (showSettings) {
                await _loadPreferences();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // پنل تنظیمات
            if (showSettings)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('منبع موقعیت:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('GPS'),
                            selected: locationSource == 'GPS',
                            onSelected: (_) async {
                              locationSource = 'GPS';
                              await _savePreferences();
                              await _detectLocationAndCache(forceRefresh: false);
                              _safeSetState(() {});
                            },
                          ),
                          ChoiceChip(
                            label: const Text('نام شهر'),
                            selected: locationSource == 'City',
                            onSelected: (_) async {
                              _safeSetState(() => locationSource = 'City');
                              await _savePreferences();
                            },
                          ),
                          ChoiceChip(
                            label: const Text('مختصات'),
                            selected: locationSource == 'Coordinates',
                            onSelected: (_) async {
                              _safeSetState(() => locationSource = 'Coordinates');
                              await _savePreferences();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (locationSource == 'GPS') ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('🔄 بروزرسانی GPS'),
                                onPressed: () async {
                                  await _detectLocationAndCache(forceRefresh: true);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (locationSource == 'City') ...[
                        TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'نام شهر (مثلاً تهران / Berlin / Istanbul)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => cityInput = val,
                          onSubmitted: (_) async {
                            cityInput = _cityController.text;
                            await _savePreferences();
                            await _resolveCityToCoordsAndLoad(cityInput, cacheSource: true);
                            _safeSetState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.search),
                            label: const Text('جستجو و اعمال'),
                            style: ElevatedButton.styleFrom(backgroundColor: gold),
                            onPressed: () async {
                              cityInput = _cityController.text;
                              await _savePreferences();
                              await _resolveCityToCoordsAndLoad(cityInput, cacheSource: true);
                              _safeSetState(() {});
                            },
                          ),
                        ),
                      ],

                      if (locationSource == 'Coordinates') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _latController,
                                decoration: const InputDecoration(
                                  labelText: 'عرض جغرافیایی',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (val) => latitudeInput = val,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _lonController,
                                decoration: const InputDecoration(
                                  labelText: 'طول جغرافیایی',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (val) => longitudeInput = val,
                              ),
                            ),
                            IconButton(
                              tooltip: 'اعمال',
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                final lat = double.tryParse(latitudeInput);
                                final lon = double.tryParse(longitudeInput);
                                if (lat == null || lon == null) {
                                  _showMessage('مختصات نامعتبر است');
                                  return;
                                }

                                locationSource = 'Coordinates';
                                await _loadPrayerTimesWithCoords(Coordinates(lat, lon));
                                await _reverseGeocodeAndCache(lat, lon);

                                await _savePreferences();
                                _safeSetState(() {});
                              },
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('روش محاسبه: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          DropdownButton<CalculationMethod>(
                            value: selectedMethod,
                            items: CalculationMethod.values.map((e) {
                              return DropdownMenuItem(value: e, child: Text(e.name));
                            }).toList(),
                            onChanged: (value) async {
                              if (value == null) return;
                              selectedMethod = value;
                              await _savePreferences();

                              // اگر مختصات داریم => فقط زمان‌ها را آپدیت کن
                              final lat = double.tryParse(latitudeInput);
                              final lon = double.tryParse(longitudeInput);
                              if (lat != null && lon != null) {
                                await _loadPrayerTimesWithCoords(Coordinates(lat, lon));
                              }
                              _safeSetState(() {});
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('مذهب: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          DropdownButton<Madhab>(
                            value: selectedSchool,
                            items: Madhab.values.map((e) {
                              return DropdownMenuItem(value: e, child: Text(e.name));
                            }).toList(),
                            onChanged: (value) async {
                              if (value == null) return;
                              selectedSchool = value;
                              await _savePreferences();

                              final lat = double.tryParse(latitudeInput);
                              final lon = double.tryParse(longitudeInput);
                              if (lat != null && lon != null) {
                                await _loadPrayerTimesWithCoords(Coordinates(lat, lon));
                              }
                              _safeSetState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // اطلاعات شهر و تاریخ
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      _buildLocationTitle(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: darkGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
                      style: const TextStyle(color: gold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hijriDate,
                      style: const TextStyle(color: gold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    if (latitudeInput.isNotEmpty && longitudeInput.isNotEmpty)
                      Text(
                        '📍 $latitudeInput , $longitudeInput',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),

            // مسیر خورشید/ماه (24H)
            SizedBox(
              height: 140,
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (_, __) {
                    final progress = _calculateProgress24H(DateTime.now());
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SunMoonPathPainter24H(),
                          ),
                        ),
                        Positioned(
                          left: width * progress,
                          top: height * 0.6 * (1 - sin(progress * pi)),
                          child: _buildSunMoonIcon24H(DateTime.now(), sunrise, sunset),
                        ),
                        Positioned(
                          left: 4,
                          bottom: 0,
                          child: Text(
                            _formatTime(sunrise),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: darkGold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 0,
                          child: Text(
                            _formatTime(sunset),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: darkGold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),
            ),

            const SizedBox(height: 12),

            // کارت‌های نماز
            isLoading
                ? const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ))
                : times == null
                ? const Center(child: Text('بدون داده'))
                : GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildPrayerCard('فجر', times!.fajr, Icons.wb_twilight, gold, darkGold),
                _buildPrayerCard('ظهر', times!.dhuhr, Icons.light_mode, gold, darkGold),
                _buildPrayerCard('عصر', times!.asr, Icons.cloud, gold, darkGold),
                _buildPrayerCard('مغرب', times!.maghrib, Icons.nights_stay, gold, darkGold),
                _buildPrayerCard('عشاء', times!.isha, Icons.mode_night, gold, darkGold),
              ],
            ),

            const SizedBox(height: 12),

            // نماز بعدی
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (nextPrayerName.isEmpty)
                    ? '🕌 نماز بعدی: --'
                    : '🕌 نماز بعدی: $nextPrayerName — $remainingTime',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildLocationTitle() {
    final parts = <String>[];
    if (cityName.trim().isNotEmpty) parts.add(cityName.trim());
    if (areaName.trim().isNotEmpty && areaName.trim() != cityName.trim()) parts.add(areaName.trim());
    if (countryName.trim().isNotEmpty) parts.add(countryName.trim());

    if (parts.isEmpty) return 'نامشخص';
    return parts.join(' - ');
  }

  Widget _buildSunMoonIcon24H(DateTime now, DateTime sunrise, DateTime sunset) {
    final isDay = now.isAfter(sunrise) && now.isBefore(sunset);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isDay
              ? [Colors.yellow.shade400, Colors.orange.shade200]
              : [Colors.grey.shade400, Colors.blueGrey.shade700],
        ),
      ),
      child: Icon(
        isDay ? Icons.wb_sunny : Icons.nightlight_round,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  double _calculateProgress24H(DateTime now) {
    return (now.hour * 3600 + now.minute * 60 + now.second) / 86400;
  }

  Widget _buildPrayerCard(
      String name, DateTime time, IconData icon, Color gold, Color darkGold) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: gold, size: 28),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: darkGold))
          ]),
          Text(
            _formatTime(time),
            style: TextStyle(fontWeight: FontWeight.bold, color: gold, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class SunMoonPathPainter24H extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * (1 - sin((x / size.width) * pi));
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
