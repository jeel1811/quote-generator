import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quote.dart';
import '../providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';

class QuoteDetailCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onFavoriteToggle;

  const QuoteDetailCard({
    Key? key,
    required this.quote,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Quote icon
            Icon(
              Icons.format_quote,
              size: 48,
              color: theme.primaryColor.withAlpha(179),
            ),
            const SizedBox(height: 16),

            // Quote content
            Text(
              quote.content,
              style: TextStyle(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: theme.textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Author
            Text(
              '— ${quote.author}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),

            // Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                quote.category,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Favorite button
                if (authProvider.isAuthenticated)
                  _buildActionButton(
                    context,
                    icon:
                        quote.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                    label: quote.isFavorite ? 'Favorited' : 'Add to Favorites',
                    color: quote.isFavorite ? Colors.red : null,
                    onTap: onFavoriteToggle,
                  ),

                // Share button
                _buildActionButton(
                  context,
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () {
                    Share.share(
                      '"${quote.content}" — ${quote.author}\n\nShared from QuoteApp',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          IconButton(
            icon: Icon(icon),
            onPressed: onTap,
            color: color,
            iconSize: 28,
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
