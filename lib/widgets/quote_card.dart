import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quote.dart';
import '../providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onTap;
  final bool? isFavorite; // Added for backward compatibility
  final VoidCallback? onFavoriteTap; // Added for backward compatibility
  final bool showActions; // Added for backward compatibility
  final bool animate; // Added for backward compatibility

  const QuoteCard({
    Key? key,
    required this.quote,
    this.onTap,
    this.isFavorite, // Added for backward compatibility
    this.onFavoriteTap, // Added for backward compatibility
    this.showActions = true, // Added for backward compatibility
    this.animate = true, // Added for backward compatibility
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentIsFavorite = isFavorite ?? quote.isFavorite;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, size: 24, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quote.content,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '— ${quote.author}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (showActions)
                    Row(
                      children: [
                        if (authProvider.isAuthenticated &&
                            onFavoriteTap != null)
                          IconButton(
                            icon: Icon(
                              currentIsFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: currentIsFavorite ? Colors.red : null,
                            ),
                            onPressed: onFavoriteTap,
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () {
                            Share.share(
                              '"${quote.content}" — ${quote.author}\n\nShared from QuoteApp',
                            );
                          },
                          child: const Icon(Icons.share, size: 20),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  quote.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
