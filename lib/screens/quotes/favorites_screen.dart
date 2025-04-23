import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quotes_provider.dart';
import '../../widgets/quote_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<QuotesProvider>(
        context,
        listen: false,
      ).fetchFavorites();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Quotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildFavoritesList(),
    );
  }

  Widget _buildFavoritesList() {
    return Consumer<QuotesProvider>(
      builder: (context, quotesProvider, child) {
        final favorites = quotesProvider.favorites;

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No favorite quotes yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your favorite quotes will appear here',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadFavorites,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final quote = favorites[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: QuoteCard(
                  quote: quote,
                  onTap: () {
                    // Navigate to quote details if needed
                  },
                  onFavoriteTap: () {
                    quotesProvider.toggleFavorite(quote);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
