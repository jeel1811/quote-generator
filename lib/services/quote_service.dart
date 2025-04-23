import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quote.dart';

class QuoteService {
  final String baseUrl = 'https://api.quotable.io';

  Future<List<Quote>> getRandomQuotes({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quotes/random?limit=$limit'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Quote.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quotes');
    }
  }

  Future<List<Quote>> getQuotesByCategory(
    String category, {
    int limit = 10,
    int page = 1,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quotes?tags=$category&limit=$limit&page=$page'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((json) => Quote.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quotes for category $category');
    }
  }

  Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/tags'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((tag) => tag['name'].toString()).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<Quote> getQuoteById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/quotes/$id'));

    if (response.statusCode == 200) {
      return Quote.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load quote');
    }
  }

  Future<Quote> getDailyQuote() async {
    final response = await http.get(
      Uri.parse('$baseUrl/quotes/random?limit=1'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return Quote.fromJson(data.first);
    } else {
      throw Exception('Failed to load daily quote');
    }
  }
}
