import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/solar_data.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID (or anonymous ID)
  String get _userId {
    final user = _auth.currentUser;
    return user?.uid ?? 'anonymous';
  }
  
  // Save solar report
  Future<String> saveSolarReport(SolarData data) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('reports')
          .add(data.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save report: $e');
    }
  }
  
  // Get all saved reports for user
  Future<List<SolarData>> getSavedReports() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('reports')
          .orderBy('analysisDate', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => SolarData.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load reports: $e');
    }
  }
  
  // Delete a report
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('reports')
          .doc(reportId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }
  
  // Sign in anonymously (for free tier users)
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }
  
  // Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }
}
