/// api_service.dart — External API service for motivational quotes.
///
/// Fetches random inspirational quotes from ZenQuotes API.
/// Includes fallback quotes for offline usage.
/// Caches the result to avoid repeated network calls.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();
  String? _q; String? _a;
  Future<Map<String, String>> getQuote() async {
    if (_q != null) return {'quote': _q!, 'author': _a ?? ''};
    try {
      final r = await http.get(Uri.parse('https://zenquotes.io/api/random')).timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) { final d = jsonDecode(r.body); if (d is List && d.isNotEmpty) { _q = d[0]['q']; _a = d[0]['a']; return {'quote': _q!, 'author': _a ?? ''}; } }
    } catch (e) { debugPrint('Quote: $e'); }
    const fb = [{'quote': 'The secret of getting ahead is getting started.', 'author': 'Mark Twain'},
      {'quote': 'It always seems impossible until it is done.', 'author': 'Nelson Mandela'},
      {'quote': 'The only way to do great work is to love what you do.', 'author': 'Steve Jobs'}];
    return fb[Random().nextInt(fb.length)];
  }
  void clearCache() { _q = null; _a = null; }
}
