import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote.dart';

class UserQuoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a quote to favorites
  Future<void> addToFavorites(String userId, Quote quote) async {
    // Update user's favorite quotes list
    await _firestore.collection('users').doc(userId).update({
      'favoriteQuoteIds': FieldValue.arrayUnion([quote.id]),
    });

    // Store the quote in the favorites collection for quick access
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(quote.id)
        .set(quote.toJson());
  }

  // Remove a quote from favorites
  Future<void> removeFromFavorites(String userId, String quoteId) async {
    // Update user's favorite quotes list
    await _firestore.collection('users').doc(userId).update({
      'favoriteQuoteIds': FieldValue.arrayRemove([quoteId]),
    });

    // Remove the quote from the favorites collection
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(quoteId)
        .delete();
  }

  // Get user's favorite quotes
  Future<List<Quote>> getFavoriteQuotes(String userId) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .get();

    return snapshot.docs.map((doc) => Quote.fromJson(doc.data())).toList();
  }

  // Add a user-generated quote (pending moderation)
  Future<void> addUserQuote(String userId, Quote quote) async {
    // Create a new quote in the user-quotes collection
    await _firestore.collection('user-quotes').add({
      ...quote.toJson(),
      'status': 'pending',
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user's submitted quotes
  Future<List<Quote>> getUserSubmittedQuotes(String userId) async {
    final snapshot =
        await _firestore
            .collection('user-quotes')
            .where('createdBy', isEqualTo: userId)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Quote.fromJson({...data, 'id': doc.id});
    }).toList();
  }

  // Get approved user-generated quotes
  Future<List<Quote>> getApprovedUserQuotes({int limit = 10}) async {
    final snapshot =
        await _firestore
            .collection('user-quotes')
            .where('status', isEqualTo: 'approved')
            .limit(limit)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Quote.fromJson({...data, 'id': doc.id});
    }).toList();
  }

  // Check if a quote is in favorites
  Future<bool> isQuoteFavorite(String userId, String quoteId) async {
    final doc =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(quoteId)
            .get();

    return doc.exists;
  }

  // Approve a user-generated quote (for admin/moderator)
  Future<void> approveUserQuote(String quoteId) async {
    await _firestore.collection('user-quotes').doc(quoteId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reject a user-generated quote (for admin/moderator)
  Future<void> rejectUserQuote(String quoteId) async {
    await _firestore.collection('user-quotes').doc(quoteId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }
}
