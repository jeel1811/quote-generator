import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quotes_provider.dart';
import '../../providers/auth_provider.dart';
import 'category_quotes_screen.dart';
import '../../widgets/quote_card.dart';
import '../../models/category.dart' as app;

class ExploreQuotesScreen extends StatefulWidget {
  const ExploreQuotesScreen({Key? key}) : super(key: key);

  @override
  State<ExploreQuotesScreen> createState() => _ExploreQuotesScreenState();
}

class _ExploreQuotesScreenState extends State<ExploreQuotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    final quotesProvider = Provider.of<QuotesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Load categories and quotes
      await quotesProvider.loadCategories();
      await quotesProvider.loadRandomQuotes();

      // If user is authenticated, load favorites
      if (authProvider.isAuthenticated && authProvider.user != null) {
        await quotesProvider.loadFavoriteQuotes(authProvider.user!.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeCategory(String category) async {
    if (category == _selectedCategory) return;

    setState(() {
      _isLoading = true;
      _selectedCategory = category;
    });

    try {
      final quotesProvider = Provider.of<QuotesProvider>(
        context,
        listen: false,
      );
      if (category == 'All') {
        await quotesProvider.loadRandomQuotes();
      } else {
        await quotesProvider.loadQuotesByCategory(category);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading quotes: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    final quotesProvider = Provider.of<QuotesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_tabController.index == 0) {
        // Trending tab
        if (_selectedCategory == 'All') {
          await quotesProvider.loadRandomQuotes();
        } else {
          await quotesProvider.loadQuotesByCategory(_selectedCategory);
        }

        // If user is authenticated, load favorites
        if (authProvider.isAuthenticated && authProvider.user != null) {
          await quotesProvider.loadFavoriteQuotes(authProvider.user!.uid);
        }
      } else {
        // Categories tab
        await quotesProvider.loadCategories();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error refreshing data: $e')));
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
        title: const Text('Explore Quotes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Trending'), Tab(text: 'Categories')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTrendingTab(), _buildCategoriesTab()],
      ),
    );
  }

  Widget _buildTrendingTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildQuotesList(),
    );
  }

  Widget _buildQuotesList() {
    return Consumer<QuotesProvider>(
      builder: (context, quotesProvider, child) {
        final quotes = quotesProvider.quotes;

        if (quotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.format_quote, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No quotes found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting a different category',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildCategoryChips(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quotes.length,
                itemBuilder: (context, index) {
                  final quote = quotes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: QuoteCard(
                      quote: quote,
                      isFavorite: quote.isFavorite,
                      onFavoriteTap: () {
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        if (authProvider.user != null) {
                          quotesProvider.toggleFavorite(quote);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    return Consumer<QuotesProvider>(
      builder: (context, quotesProvider, child) {
        // Add 'All' category
        final categories = [
          'All',
          ...quotesProvider.categories.map((c) => c.name),
        ];

        return Container(
          height: 50,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == _selectedCategory;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: Theme.of(
                    context,
                  ).primaryColor.withAlpha(51), // ~0.2 opacity
                  onSelected: (selected) {
                    if (selected) {
                      _changeCategory(category);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCategoriesGrid(),
    );
  }

  Widget _buildCategoriesGrid() {
    return Consumer<QuotesProvider>(
      builder: (context, quotesProvider, child) {
        final categories = quotesProvider.categories;

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No categories found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(app.Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryQuotesScreen(category: category),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withAlpha(179), // ~0.7 opacity
                Theme.of(context).primaryColor,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
