import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quotes_provider.dart';
import '../../widgets/quote_card.dart';

class FavoriteQuotesScreen extends StatefulWidget {
  const FavoriteQuotesScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteQuotesScreen> createState() => _FavoriteQuotesScreenState();
}

class _FavoriteQuotesScreenState extends State<FavoriteQuotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final quotesProvider = Provider.of<QuotesProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.user != null) {
      await quotesProvider.loadFavoriteQuotes(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final quotesProvider = Provider.of<QuotesProvider>(context);

    if (!authProvider.isAuthenticated) {
      return _buildUnauthenticatedState();
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child:
            quotesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : quotesProvider.favoriteQuotes.isEmpty
                ? _buildEmptyState()
                : _buildFavoritesList(quotesProvider, authProvider),
      ),
    );
  }

  Widget _buildUnauthenticatedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Login Required',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Please login to view your favorite quotes',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add quotes to your favorites by tapping the heart icon',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to explore tab
              final BottomNavigationBar? navigationBar =
                  findBottomNavigationBar(context);
              if (navigationBar != null) {
                navigationBar.onTap!(1); // Index 1 is the Explore tab
              }
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explore Quotes'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(
    QuotesProvider quotesProvider,
    AuthProvider authProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: quotesProvider.favoriteQuotes.length,
      itemBuilder: (context, index) {
        final quote = quotesProvider.favoriteQuotes[index];

        return Dismissible(
          key: Key(quote.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Remove from Favorites'),
                  content: const Text(
                    'Are you sure you want to remove this quote from your favorites?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Remove'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            if (authProvider.user != null) {
              quotesProvider.toggleFavorite(quote);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quote removed from favorites')),
              );
            }
          },
          child: QuoteCard(
            quote: quote,
            isFavorite: true,
            onFavoriteTap:
                authProvider.user != null
                    ? () => quotesProvider.toggleFavorite(quote)
                    : null,
          ),
        );
      },
    );
  }

  BottomNavigationBar? findBottomNavigationBar(BuildContext context) {
    BottomNavigationBar? navigationBar;

    void visitor(Element element) {
      if (element.widget is BottomNavigationBar) {
        navigationBar = element.widget as BottomNavigationBar;
      } else {
        element.visitChildren(visitor);
      }
    }

    context.visitChildElements(visitor);
    return navigationBar;
  }
}
