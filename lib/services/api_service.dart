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
  // ── 1. Singleton Setup ──
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  // ── 2. Cached Variables ──
  String? _cachedQuote;
  String? _cachedAuthor;

  // ── 3. Fetch Quote Logic ──
  Future<Map<String, String>> getQuote() async {
    // Step 1: Return the cached quote immediately if it exists
    if (_cachedQuote != null) {
      return {
        'quote': _cachedQuote!,
        'author': _cachedAuthor ?? '',
      };
    }

    // Step 2: Attempt to fetch from the external Web API
    try {
      final url = Uri.parse('https://zenquotes.io/api/random');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ensure the returned JSON is a valid list and not empty
        if (data is List && data.isNotEmpty) {
          _cachedQuote = data[0]['q'];
          _cachedAuthor = data[0]['a'];

          return {
            'quote': _cachedQuote!,
            'author': _cachedAuthor ?? '',
          };
        }
      }
    } catch (e) {
      // Log the error if the device is offline or the request times out
      debugPrint('Quote API Error: $e');
    }

    // Step 3: Local fallback quotes (Used when offline or API fails)
    const fallbacks = [
      {
        'quote': 'The secret of getting ahead is getting started.',
        'author': 'Mark Twain'
      },
      {
        'quote': 'It always seems impossible until it is done.',
        'author': 'Nelson Mandela'
      },
      {
        'quote': 'The only way to do great work is to love what you do.',
        'author': 'Steve Jobs'
      }
    ];

    // Return a randomly selected fallback quote
    return fallbacks[Random().nextInt(fallbacks.length)];
  }

  // ── 4. Cache Management ──
  /// Clears the cached quote, forcing the next call to fetch a new one.
  void clearCache() {
    _cachedQuote = null;
    _cachedAuthor = null;
  }
}