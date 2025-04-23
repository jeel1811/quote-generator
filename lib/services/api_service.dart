import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/quote.dart';
import '../models/category.dart' as app_category;

class ApiService {
  static const baseUrl = 'https://api.quotable.io';
  static const timeout = Duration(seconds: 10);

  final http.Client _client;

  // Create with optional client parameter for testing
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Default quotes to use when offline - these should only be used as a last resort
  final List<Map<String, dynamic>> _fallbackQuotes = [
    {
      "_id": "fallback1",
      "content": "The best way to predict the future is to create it.",
      "author": "Abraham Lincoln",
      "tags": ["inspirational", "motivation"],
      "category": "inspiration",
    },
    {
      "_id": "fallback2",
      "content": "The journey of a thousand miles begins with one step.",
      "author": "Lao Tzu",
      "tags": ["wisdom", "life"],
      "category": "wisdom",
    },
    {
      "_id": "fallback3",
      "content": "Life is what happens when you're busy making other plans.",
      "author": "John Lennon",
      "tags": ["life", "wisdom"],
      "category": "life",
    },
    {
      "_id": "fallback4",
      "content": "Strive not to be a success, but rather to be of value.",
      "author": "Albert Einstein",
      "tags": ["success", "motivation"],
      "category": "success",
    },
    {
      "_id": "fallback5",
      "content": "The only way to do great work is to love what you do.",
      "author": "Steve Jobs",
      "tags": ["work", "inspiration"],
      "category": "work",
    },
  ];

  // Default categories to use when offline
  final List<Map<String, dynamic>> _fallbackCategories = [
    {"_id": "cat1", "name": "Inspiration"},
    {"_id": "cat2", "name": "Wisdom"},
    {"_id": "cat3", "name": "Life"},
    {"_id": "cat4", "name": "Success"},
    {"_id": "cat5", "name": "Motivation"},
  ];

  // Check if network is available
  Future<bool> _isNetworkAvailable() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Fetch a random quote with improved error handling
  Future<Quote> fetchRandomQuote() async {
    if (!await _isNetworkAvailable()) {
      debugPrint('Network unavailable, using fallback quote');
      return _getRandomFallbackQuote();
    }

    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/random'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Quote.fromJson(data);
      } else {
        debugPrint('API error (${response.statusCode}): ${response.body}');
        throw Exception('Failed to load quote (${response.statusCode})');
      }
    } on SocketException {
      debugPrint('Network error: SocketException');
      return _getRandomFallbackQuote();
    } on HttpException {
      debugPrint('Network error: HttpException');
      return _getRandomFallbackQuote();
    } on TimeoutException {
      debugPrint('Network error: TimeoutException');
      return _getRandomFallbackQuote();
    } catch (e) {
      debugPrint('Unknown error: $e');
      return _getRandomFallbackQuote();
    }
  }

  // Get a random quote from fallback quotes
  Quote _getRandomFallbackQuote() {
    final random =
        _fallbackQuotes[DateTime.now().millisecond % _fallbackQuotes.length];
    return Quote.fromJson(random);
  }

  // Fetch quotes by category with improved error handling
  Future<List<Quote>> fetchQuotesByCategory(String category) async {
    if (!await _isNetworkAvailable()) {
      debugPrint(
        'Network unavailable, using fallback quotes for category: $category',
      );
      return _getFallbackQuotesByCategory(category);
    }

    try {
      final url = Uri.parse('$baseUrl/quotes').replace(
        queryParameters: {'tags': category.toLowerCase(), 'limit': '20'},
      );

      final response = await _client.get(url).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'] is List) {
          final results = data['results'] as List;
          if (results.isEmpty) {
            // If API returns empty results, try fallback quotes
            return _getFallbackQuotesByCategory(category);
          }
          return results.map((quoteJson) => Quote.fromJson(quoteJson)).toList();
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        debugPrint('API error (${response.statusCode}): ${response.body}');
        throw Exception(
          'Failed to load quotes for category: $category (${response.statusCode})',
        );
      }
    } on SocketException {
      debugPrint('Network error: SocketException');
      return _getFallbackQuotesByCategory(category);
    } on HttpException {
      debugPrint('Network error: HttpException');
      return _getFallbackQuotesByCategory(category);
    } on TimeoutException {
      debugPrint('Network error: TimeoutException');
      return _getFallbackQuotesByCategory(category);
    } catch (e) {
      debugPrint('Unknown error: $e');
      return _getFallbackQuotesByCategory(category);
    }
  }

  // Get fallback quotes filtered by category
  List<Quote> _getFallbackQuotesByCategory(String category) {
    final lowerCategory = category.toLowerCase();
    final filtered =
        _fallbackQuotes
            .where(
              (q) =>
                  q['category'].toString().toLowerCase() == lowerCategory ||
                  (q['tags'] as List).any(
                    (tag) => tag.toString().toLowerCase() == lowerCategory,
                  ),
            )
            .toList();

    // If no matches in fallback quotes for this category, return all fallback quotes
    if (filtered.isEmpty) {
      return _fallbackQuotes.map((q) => Quote.fromJson(q)).toList();
    }

    return filtered.map((q) => Quote.fromJson(q)).toList();
  }

  // Fetch available categories/tags with improved error handling
  Future<List<app_category.Category>> fetchCategories() async {
    if (!await _isNetworkAvailable()) {
      debugPrint('Network unavailable, using fallback categories');
      return _getFallbackCategories();
    }

    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/tags'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isEmpty) {
          // If API returns empty results, use fallback categories
          return _getFallbackCategories();
        }
        return data
            .map((tagJson) => app_category.Category.fromJson(tagJson))
            .toList();
      } else {
        debugPrint('API error (${response.statusCode}): ${response.body}');
        throw Exception('Failed to load categories (${response.statusCode})');
      }
    } on SocketException {
      debugPrint('Network error: SocketException');
      return _getFallbackCategories();
    } on HttpException {
      debugPrint('Network error: HttpException');
      return _getFallbackCategories();
    } on TimeoutException {
      debugPrint('Network error: TimeoutException');
      return _getFallbackCategories();
    } catch (e) {
      debugPrint('Unknown error: $e');
      return _getFallbackCategories();
    }
  }

  // Get fallback categories
  List<app_category.Category> _getFallbackCategories() {
    return _fallbackCategories
        .map((c) => app_category.Category.fromJson(c))
        .toList();
  }

  // Search quotes with improved error handling
  Future<List<Quote>> searchQuotes(String query) async {
    if (!await _isNetworkAvailable()) {
      debugPrint('Network unavailable, searching fallback quotes for: $query');
      return _searchFallbackQuotes(query);
    }

    try {
      final url = Uri.parse(
        '$baseUrl/search/quotes',
      ).replace(queryParameters: {'query': query, 'limit': '20'});

      final response = await _client.get(url).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'] is List) {
          final results = data['results'] as List;
          if (results.isEmpty) {
            // If API returns empty results, search fallback quotes
            return _searchFallbackQuotes(query);
          }
          return results.map((quoteJson) => Quote.fromJson(quoteJson)).toList();
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        debugPrint('API error (${response.statusCode}): ${response.body}');
        throw Exception('Failed to search quotes (${response.statusCode})');
      }
    } on SocketException {
      debugPrint('Network error: SocketException');
      return _searchFallbackQuotes(query);
    } on HttpException {
      debugPrint('Network error: HttpException');
      return _searchFallbackQuotes(query);
    } on TimeoutException {
      debugPrint('Network error: TimeoutException');
      return _searchFallbackQuotes(query);
    } catch (e) {
      debugPrint('Unknown error: $e');
      return _searchFallbackQuotes(query);
    }
  }

  // Search within fallback quotes
  List<Quote> _searchFallbackQuotes(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered =
        _fallbackQuotes
            .where(
              (q) =>
                  q['content'].toString().toLowerCase().contains(lowerQuery) ||
                  q['author'].toString().toLowerCase().contains(lowerQuery),
            )
            .toList();

    // If no matches in fallback quotes, return all fallback quotes
    if (filtered.isEmpty) {
      return _fallbackQuotes.map((q) => Quote.fromJson(q)).toList();
    }

    return filtered.map((q) => Quote.fromJson(q)).toList();
  }
}
