import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/health_condition.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCompletedOnboarding => _userProfile?.hasCompletedOnboarding ?? false;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> createUserProfile({
    required String name,
    required int age,
    required double height,
    required double weight,
    required String heightUnit,
    required String weightUnit,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      final userProfile = UserProfile(
        uid: user.uid,
        email: user.email!,
        name: name,
        age: age,
        height: height,
        weight: weight,
        heightUnit: heightUnit,
        weightUnit: weightUnit,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        hasCompletedOnboarding: false,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userProfile.toMap());

      _userProfile = userProfile;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to create user profile: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateHealthConditions(List<HealthCondition> conditions) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      final conditionsData = conditions.map((c) => c.toMap()).toList();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'healthConditions': conditionsData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          healthConditions: conditions,
          updatedAt: DateTime.now(),
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update health conditions: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateGPDetails({
    required String gpName,
    required String practiceName,
    required String phone,
    required String email,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      final gpDetails = {
        'name': gpName,
        'practiceName': practiceName,
        'phone': phone,
        'email': email,
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'gpDetails': gpDetails,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          gpDetails: gpDetails,
          updatedAt: DateTime.now(),
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update GP details: ${e.toString()}');
      return false;
    }
  }

  Future<bool> completeOnboarding() async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'hasCompletedOnboarding': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          hasCompletedOnboarding: true,
          updatedAt: DateTime.now(),
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to complete onboarding: ${e.toString()}');
      return false;
    }
  }

  Future<bool> loadUserProfile() async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _userProfile = UserProfile.fromMap(doc.data()!);
      } else {
        _userProfile = null;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load user profile: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateUserProfile({
    String? name,
    int? age,
    double? height,
    double? weight,
    String? heightUnit,
    String? weightUnit,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (age != null) updates['age'] = age;
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (heightUnit != null) updates['heightUnit'] = heightUnit;
      if (weightUnit != null) updates['weightUnit'] = weightUnit;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(updates);

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          name: name ?? _userProfile!.name,
          age: age ?? _userProfile!.age,
          height: height ?? _userProfile!.height,
          weight: weight ?? _userProfile!.weight,
          heightUnit: heightUnit ?? _userProfile!.heightUnit,
          weightUnit: weightUnit ?? _userProfile!.weightUnit,
          updatedAt: DateTime.now(),
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update user profile: ${e.toString()}');
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearUserProfile() {
    _userProfile = null;
    notifyListeners();
  }
}
