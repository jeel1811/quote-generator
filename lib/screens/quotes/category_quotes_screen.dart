import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/quote.dart';
import '../../providers/quotes_provider.dart';
import '../../widgets/quote_card.dart';

class CategoryQuotesScreen extends StatefulWidget {
  final Category category;

  const CategoryQuotesScreen({Key? key, required this.category})
    : super(key: key);

  @override
  State<CategoryQuotesScreen> createState() => _CategoryQuotesScreenState();
}

class _CategoryQuotesScreenState extends State<CategoryQuotesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategoryQuotes();
  }

  Future<void> _loadCategoryQuotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<QuotesProvider>(
        context,
        listen: false,
      ).fetchQuotesByCategory(widget.category.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quotes: ${e.toString()}')),
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
        title: Text(widget.category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategoryQuotes,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategoryQuotes,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildQuotesList(),
      ),
    );
  }

  Widget _buildQuotesList() {
    return Consumer<QuotesProvider>(
      builder: (context, quotesProvider, child) {
        final List<Quote> quotes = quotesProvider.categoryQuotes;

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
                  'Try another category or refresh',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: QuoteCard(
                quote: quote,
                onTap: () {
                  // Navigate to quote details
                },
              ),
            );
          },
        );
      },
    );
  }
}
