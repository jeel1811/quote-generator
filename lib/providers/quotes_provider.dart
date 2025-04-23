import 'package:flutter/foundation.dart';
import '../models/quote.dart';
import '../models/category.dart' as app;
import '../services/api_service.dart';
import '../services/quotes_service.dart';

class QuotesProvider with ChangeNotifier {
  final ApiService _apiService;
  final QuotesService _quotesService;

  Quote? _dailyQuote;
  List<Quote> _favorites = [];
  List<Quote> _categoryQuotes = [];
  List<app.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  QuotesProvider({
    required ApiService apiService,
    required QuotesService quotesService,
  }) : _apiService = apiService,
       _quotesService = quotesService;

  Quote? get dailyQuote => _dailyQuote;
  List<Quote> get favorites => _favorites;
  List<Quote> get categoryQuotes => _categoryQuotes;
  List<app.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add these methods to handle backward compatibility with existing screens
  List<Quote> get quotes => _categoryQuotes;
  List<Quote> get favoriteQuotes => _favorites;

  void _setError(dynamic e) {
    if (e is Exception) {
      _error = e.toString().replaceAll('Exception: ', '');
    } else {
      _error = e.toString();
    }
    debugPrint('QuotesProvider error: $_error');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    await fetchCategories();
  }

  Future<void> loadRandomQuotes({int limit = 10}) async {
    await fetchDailyQuote();
  }

  Future<void> loadFavoriteQuotes(String userId) async {
    await fetchFavorites();
  }

  Future<void> loadQuotesByCategory(
    String category, {
    int limit = 10,
    int page = 1,
  }) async {
    await fetchQuotesByCategory(category);
  }

  Future<void> submitUserQuote(
    String userId,
    String content,
    String author,
    String category,
  ) async {
    final quote = Quote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      author: author,
      category: category,
      isUserGenerated: true,
      createdBy: userId,
      createdAt: DateTime.now(),
      isPublic: true,
    );

    await addQuote(quote);
  }

  // Original methods
  Future<void> fetchDailyQuote() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final quote = await _apiService.fetchRandomQuote();
      _dailyQuote = quote;
    } catch (e) {
      _dailyQuote = null;
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchQuotesByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categoryQuotes = await _apiService.fetchQuotesByCategory(category);
    } catch (e) {
      _categoryQuotes = [];
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.fetchCategories();
    } catch (e) {
      _categories = [];
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _favorites = await _quotesService.getFavorites();
    } catch (e) {
      _favorites = [];
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Quote quote) async {
    try {
      final userId = await _quotesService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final success = await _quotesService.toggleFavorite(userId, quote);
      if (success) {
        // Update local state
        if (quote.isFavorite) {
          _favorites.removeWhere((q) => q.id == quote.id);
        } else {
          _favorites.add(quote.copyWith(isFavorite: true));
        }

        // Update daily quote if it's the same one
        if (_dailyQuote != null && _dailyQuote!.id == quote.id) {
          _dailyQuote = _dailyQuote!.copyWith(
            isFavorite: !_dailyQuote!.isFavorite,
          );
        }

        // Update category quotes if needed
        final index = _categoryQuotes.indexWhere((q) => q.id == quote.id);
        if (index != -1) {
          _categoryQuotes[index] = _categoryQuotes[index].copyWith(
            isFavorite: !_categoryQuotes[index].isFavorite,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> addQuote(Quote quote) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _quotesService.addQuote(quote);
    } catch (e) {
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
