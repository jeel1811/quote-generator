import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quotes_provider.dart';

class AddQuoteScreen extends StatefulWidget {
  const AddQuoteScreen({super.key});

  @override
  State<AddQuoteScreen> createState() => _AddQuoteScreenState();
}

class _AddQuoteScreenState extends State<AddQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quoteController = TextEditingController();
  final _authorController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitting = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        _loadCategories();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe way to load categories after dependencies are updated
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadCategories();
        }
      });
    }
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    try {
      final quotesProvider = Provider.of<QuotesProvider>(
        context,
        listen: false,
      );
      if (quotesProvider.categories.isEmpty) {
        await quotesProvider.loadCategories();
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // Don't show dialog here as it might be too disruptive
    }
  }

  Future<void> _submitQuote() async {
    if (_isSubmitting) return;

    // Simple validation for Cupertino inputs
    if (_quoteController.text.trim().isEmpty ||
        _quoteController.text.trim().length < 10) {
      _showErrorDialog('Quote must be at least 10 characters');
      return;
    }

    if (_authorController.text.trim().isEmpty) {
      _showErrorDialog('Please enter the author');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      _showUnauthenticatedDialog();
      return;
    }

    // Use microtask to avoid setState during build
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isSubmitting = true;
        });
      }
    });

    try {
      final quotesProvider = Provider.of<QuotesProvider>(
        context,
        listen: false,
      );
      await quotesProvider.submitUserQuote(
        authProvider.user!.uid,
        _quoteController.text.trim(),
        _authorController.text.trim(),
        _selectedCategory,
      );

      if (mounted) {
        _showSuccessDialog();
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error submitting quote: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
        });
      }
    }
  }

  void _resetForm() {
    if (!mounted) return;

    _quoteController.clear();
    _authorController.clear();
    setState(() {
      _selectedCategory = 'General';
    });
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

  void _showUnauthenticatedDialog() {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Login Required'),
            content: const Text('You need to be logged in to submit quotes.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog() {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Quote Submitted'),
            content: const Text(
              'Your quote has been submitted for moderation. '
              'It will be visible once approved by our team.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showCategoryPicker() {
    if (!mounted) return;

    final quotesProvider = Provider.of<QuotesProvider>(context, listen: false);

    // Prepare the list of category names
    final List<String> categories = [
      'General',
      ...quotesProvider.categories.map((category) => category.name),
    ];

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 250,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32.0,
                      onSelectedItemChanged: (index) {
                        // Use microtask to avoid setState during build
                        Future.microtask(() {
                          if (mounted) {
                            setState(() {
                              _selectedCategory = categories[index];
                            });
                          }
                        });
                      },
                      children:
                          categories.map((category) => Text(category)).toList(),
                      scrollController: FixedExtentScrollController(
                        initialItem: categories.indexOf(_selectedCategory),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildUnauthenticatedState() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Add Quote')),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.person_crop_circle_badge_exclam,
                  size: 80,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You need to be logged in to submit quotes.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CupertinoButton.filled(
                  onPressed:
                      () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quotesProvider = Provider.of<QuotesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return _buildUnauthenticatedState();
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add Quote'),
        trailing:
            _isSubmitting
                ? const CupertinoActivityIndicator()
                : CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
                  onPressed: () {
                    // Use microtask to avoid setState during build
                    Future.microtask(() => _submitQuote());
                  },
                ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap:
              () =>
                  FocusScope.of(
                    context,
                  ).unfocus(), // Dismiss keyboard when tapping outside
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 12),
                  child: Icon(
                    CupertinoIcons.quote_bubble,
                    size: 60,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
                Text(
                  'Add Your Quote',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color:
                        CupertinoTheme.of(context).brightness == Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Inspire others with your favorite quote',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Quote content field
                _buildInputSection(
                  title: 'Quote',
                  child: CupertinoTextField(
                    controller: _quoteController,
                    placeholder: 'Enter your quote here',
                    maxLines: 5,
                    minLines: 3,
                    padding: const EdgeInsets.all(12),
                    decoration: _getInputDecoration(context),
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          CupertinoTheme.of(context).brightness ==
                                  Brightness.dark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Author field
                _buildInputSection(
                  title: 'Author',
                  child: CupertinoTextField(
                    controller: _authorController,
                    placeholder: 'Who said this quote?',
                    padding: const EdgeInsets.all(12),
                    decoration: _getInputDecoration(context),
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          CupertinoTheme.of(context).brightness ==
                                  Brightness.dark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category selector
                _buildInputSection(
                  title: 'Category',
                  child: GestureDetector(
                    onTap: () {
                      // Use microtask to avoid calling during build
                      Future.microtask(() => _showCategoryPicker());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: _getInputDecoration(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  CupertinoTheme.of(context).brightness ==
                                          Brightness.dark
                                      ? CupertinoColors.white
                                      : CupertinoColors.black,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_down,
                            size: 16,
                            color: CupertinoColors.tertiaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit button
                CupertinoButton.filled(
                  onPressed:
                      _isSubmitting
                          ? null
                          : () {
                            // Use microtask to avoid setState during build
                            Future.microtask(() => _submitQuote());
                          },
                  child: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Quote',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color:
                  CupertinoTheme.of(context).brightness == Brightness.dark
                      ? CupertinoColors.white
                      : CupertinoColors.black,
            ),
          ),
        ),
        child,
      ],
    );
  }

  BoxDecoration _getInputDecoration(BuildContext context) {
    return BoxDecoration(
      color:
          CupertinoTheme.of(context).brightness == Brightness.dark
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: CupertinoColors.systemGrey4.resolveFrom(context),
        width: 1.0,
      ),
    );
  }
}
