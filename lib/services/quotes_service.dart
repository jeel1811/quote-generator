import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/quote.dart';

class QuotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  // Get user's favorite quotes
  Future<List<Quote>> getFavorites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('favorites')
              .get();

      return snapshot.docs.map((doc) => Quote.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      rethrow;
    }
  }

  // Toggle favorite status of a quote
  Future<bool> toggleFavorite(String userId, Quote quote) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(quote.id);

      if (quote.isFavorite) {
        // Remove from favorites
        await docRef.delete();
      } else {
        // Add to favorites
        await docRef.set(quote.copyWith(isFavorite: true).toJson());
      }
      return true;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  // Add a user-generated quote
  Future<void> addQuote(Quote quote) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Add to user's quotes collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('userQuotes')
          .doc(quote.id)
          .set(quote.toJson());

      // Also add to public quotes collection if it's public
      if (quote.isPublic ?? false) {
        await _firestore
            .collection('publicQuotes')
            .doc(quote.id)
            .set(quote.toJson());
      }
    } catch (e) {
      debugPrint('Error adding quote: $e');
      rethrow;
    }
  }

  // Get user-generated quotes
  Future<List<Quote>> getUserQuotes() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('userQuotes')
              .get();

      return snapshot.docs.map((doc) => Quote.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting user quotes: $e');
      rethrow;
    }
  }

  // Get public user-generated quotes
  Future<List<Quote>> getPublicQuotes() async {
    try {
      final snapshot =
          await _firestore
              .collection('publicQuotes')
              .orderBy('createdAt', descending: true)
              .limit(20)
              .get();

      return snapshot.docs.map((doc) => Quote.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting public quotes: $e');
      rethrow;
    }
  }
}
