import 'dart:convert';
import 'package:flutter/services.dart';

class QuranService {
  static Future<List<Map<String, dynamic>>> loadAllAyahs() async {
    final String jsonStr = await rootBundle.loadString('assets/quran.json');
    final data = json.decode(jsonStr);

    // اگر JSON آرایه آیات است:
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }

    // اگر ساختارت متفاوت است (مثلاً زیر کلید "verses" یا آرایه‌ی دیگری)
    if (data is Map && data.containsKey('verses')) {
      return List<Map<String, dynamic>>.from(data['verses']);
    }

    // fallback: اگر کل فایل یک Map از آیه‌ها با کلیدهای "1","2"... است
    if (data is Map) {
      // تبدیل به لیست مرتّب بر اساس آیدی گلوبال (اگر موجود)
      final List<Map<String, dynamic>> list = [];
      data.forEach((k, v) {
        if (v is List) {
          for (var item in v) {
            if (item is Map<String, dynamic>) list.add(item);
          }
        }
      });
      return list;
    }

    return [];
  }

  // دریافت همه آیات یک صفحه (pageid)
  static Future<List<Map<String, dynamic>>> getAyahsByPage(int pageId) async {
    final all = await loadAllAyahs();
    return all.where((a) {
      final p = a['pageid'] ?? a['page'] ?? a['page_id'] ?? a['page-tag'] ?? a['pageid'];
      if (p == null) return false;
      // بعضی JSON ها pageid را عددی یا رشته قرار می‌دهند
      final intPage = p is int ? p : int.tryParse(p.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? -1;
      return intPage == pageId;
    }).toList();
  }
}
