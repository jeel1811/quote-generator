import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/quotes_provider.dart';
import '../../models/category.dart';
import 'category_quotes_screen.dart';

class QuoteCategoriesScreen extends StatefulWidget {
  const QuoteCategoriesScreen({super.key});

  @override
  State<QuoteCategoriesScreen> createState() => _QuoteCategoriesScreenState();
}

class _QuoteCategoriesScreenState extends State<QuoteCategoriesScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Don't call _loadCategories directly here to avoid setState during didChangeDependencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _loadCategories();
        _isInitialized = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe way to load data after dependencies are updated
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadCategories();
        }
      });
    }
  }

  Future<void> _loadCategories() async {
    // Don't set state if we're already loading
    if (_isLoading) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<QuotesProvider>(
        context,
        listen: false,
      ).fetchCategories();
    } catch (e) {
      if (mounted) {
        // Use a microtask to avoid calling setState during build
        Future.microtask(() {
          if (mounted) {
            _showErrorDialog('Error loading categories: ${e.toString()}');
          }
        });
      }
    } finally {
      // Use a microtask to avoid calling setState during build
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Categories'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.refresh,
            color: CupertinoTheme.of(context).primaryColor,
          ),
          onPressed: () {
            // Wrap in a microtask to ensure it doesn't happen during build
            Future.microtask(() => _loadCategories());
          },
        ),
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _buildCategoriesList(),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Consumer<QuotesProvider>(
      builder: (context, quotesProvider, child) {
        final categories = quotesProvider.categories;

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.collections,
                  size: 64,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'No categories found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        CupertinoTheme.of(context).brightness == Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: () {
                    // Wrap in microtask to avoid setState during build
                    Future.microtask(() => _loadCategories());
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                // Return a future to indicate when refresh is complete
                await _loadCategories();
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(category);
                }, childCount: categories.length),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    // Generate a consistent but different color for each category
    final int colorSeed = category.name.length + category.name.codeUnitAt(0);
    final List<Color> colorOptions = [
      CupertinoColors.activeBlue,
      CupertinoColors.activeOrange,
      CupertinoColors.systemPink,
      CupertinoColors.activeGreen,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemPurple,
      CupertinoColors.systemTeal,
    ];

    final Color cardColor = colorOptions[colorSeed % colorOptions.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => CategoryQuotesScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color:
              CupertinoTheme.of(context).brightness == Brightness.dark
                  ? cardColor.withOpacity(0.5)
                  : cardColor.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.white.withOpacity(0.2),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardColor.withOpacity(0.8),
                    cardColor.withOpacity(0.6),
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
