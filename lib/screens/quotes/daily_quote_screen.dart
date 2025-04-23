import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quotes_provider.dart';
import '../../models/quote.dart';
import '../../widgets/quote_detail_card.dart';

class DailyQuoteScreen extends StatefulWidget {
  const DailyQuoteScreen({super.key});

  @override
  State<DailyQuoteScreen> createState() => _DailyQuoteScreenState();
}

class _DailyQuoteScreenState extends State<DailyQuoteScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialQuote();
  }

  // Load initial quote when screen first appears
  Future<void> _loadInitialQuote() async {
    // Use a delay to ensure the context is properly available
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final quotesProvider = Provider.of<QuotesProvider>(context, listen: false);
    if (quotesProvider.dailyQuote == null) {
      await _loadDailyQuote();
    }
  }

  Future<void> _loadDailyQuote() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<QuotesProvider>(
        context,
        listen: false,
      ).fetchDailyQuote();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Error loading quote: $message'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  void _navigateToAddQuote() {
    Navigator.of(context).pushNamed('/add-quote');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Daily Quote'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
              onPressed: _loadDailyQuote,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add),
              onPressed: _navigateToAddQuote,
            ),
          ],
        ),
      ),
      child: Consumer<QuotesProvider>(
        builder: (context, quotesProvider, child) {
          if (_isLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (quotesProvider.error != null) {
            // Show error message with retry button
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 60,
                      color: CupertinoColors.destructiveRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading quote',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quotesProvider.error ?? 'An unknown error occurred',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: _loadDailyQuote,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget content = _buildDailyQuoteContent(quotesProvider);

          // Wrap with custom pull-to-refresh for iOS
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(onRefresh: _loadDailyQuote),
              SliverFillRemaining(hasScrollBody: false, child: content),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDailyQuoteContent(QuotesProvider quotesProvider) {
    final Quote? dailyQuote = quotesProvider.dailyQuote;

    if (dailyQuote == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.quote_bubble,
              size: 80,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No daily quote available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh and get a daily quote',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _loadDailyQuote,
              child: const Text('Load Quote'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Quote of the Day',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoTheme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildModernQuoteCard(dailyQuote, quotesProvider),
        ],
      ),
    );
  }

  Widget _buildModernQuoteCard(Quote quote, QuotesProvider quotesProvider) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.quote_bubble, color: primaryColor, size: 32),
          const SizedBox(height: 16),
          Text(
            quote.content,
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${quote.author}',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: textColor?.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#${quote.category}',
              style: TextStyle(fontSize: 14, color: primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Icon(CupertinoIcons.share, color: primaryColor, size: 20),
                    const SizedBox(width: 4),
                    Text('Share', style: TextStyle(color: primaryColor)),
                  ],
                ),
                onPressed: () {
                  // Share quote functionality
                  // Will be implemented later
                },
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Icon(
                      quote.isFavorite
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      color:
                          quote.isFavorite
                              ? CupertinoColors.destructiveRed
                              : primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quote.isFavorite ? 'Saved' : 'Save',
                      style: TextStyle(
                        color:
                            quote.isFavorite
                                ? CupertinoColors.destructiveRed
                                : primaryColor,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  quotesProvider.toggleFavorite(quote);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
