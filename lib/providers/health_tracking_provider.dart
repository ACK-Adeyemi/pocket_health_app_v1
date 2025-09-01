import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_condition.dart';
import '../models/health_metric.dart';
import '../models/health_entry.dart';

class HealthTrackingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<HealthCondition> _userConditions = [];
  List<HealthEntry> _recentEntries = [];
  Map<String, List<HealthEntry>> _entriesByCondition = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<HealthCondition> get userConditions => _userConditions;
  List<HealthEntry> get recentEntries => _recentEntries;
  Map<String, List<HealthEntry>> get entriesByCondition => _entriesByCondition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set user conditions (from user profile)
  void setUserConditions(List<HealthCondition> conditions) {
    _userConditions = conditions;
    notifyListeners();
  }

  // Load health entries for a user
  Future<void> loadHealthEntries(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final querySnapshot = await _firestore
          .collection('health_entries')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      _recentEntries = querySnapshot.docs
          .map((doc) => HealthEntry.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Group entries by condition
      _entriesByCondition.clear();
      for (final entry in _recentEntries) {
        if (!_entriesByCondition.containsKey(entry.conditionId)) {
          _entriesByCondition[entry.conditionId] = [];
        }
        _entriesByCondition[entry.conditionId]!.add(entry);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load health entries: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Add a new health entry
  Future<bool> addHealthEntry(HealthEntry entry) async {
    _setLoading(true);
    _error = null;

    try {
      final docRef = await _firestore.collection('health_entries').add(entry.toMap());
      
      // Add to local lists
      final newEntry = entry.copyWith(id: docRef.id);
      _recentEntries.insert(0, newEntry);
      
      if (!_entriesByCondition.containsKey(entry.conditionId)) {
        _entriesByCondition[entry.conditionId] = [];
      }
      _entriesByCondition[entry.conditionId]!.insert(0, newEntry);

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save health entry: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add multiple health entries as a group (e.g., blood pressure)
  Future<bool> addHealthEntryGroup(HealthEntryGroup entryGroup) async {
    _setLoading(true);
    _error = null;

    try {
      final batch = _firestore.batch();
      final List<HealthEntry> savedEntries = [];

      for (final entry in entryGroup.entries) {
        final docRef = _firestore.collection('health_entries').doc();
        final entryWithId = entry.copyWith(id: docRef.id);
        batch.set(docRef, entryWithId.toMap());
        savedEntries.add(entryWithId);
      }

      await batch.commit();

      // Add to local lists
      for (final entry in savedEntries) {
        _recentEntries.insert(0, entry);
        
        if (!_entriesByCondition.containsKey(entry.conditionId)) {
          _entriesByCondition[entry.conditionId] = [];
        }
        _entriesByCondition[entry.conditionId]!.insert(0, entry);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save health entries: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get entries for a specific condition
  List<HealthEntry> getEntriesForCondition(String conditionId) {
    return _entriesByCondition[conditionId] ?? [];
  }

  // Get latest entry for a specific metric
  HealthEntry? getLatestEntryForMetric(String conditionId, String metricId) {
    final entries = getEntriesForCondition(conditionId);
    try {
      return entries.firstWhere((entry) => entry.metricId == metricId);
    } catch (e) {
      return null;
    }
  }

  // Get entries for a specific metric over time
  List<HealthEntry> getEntriesForMetric(String conditionId, String metricId, {int? limit}) {
    final entries = getEntriesForCondition(conditionId)
        .where((entry) => entry.metricId == metricId)
        .toList();
    
    if (limit != null && entries.length > limit) {
      return entries.take(limit).toList();
    }
    
    return entries;
  }

  // Get trend data for a metric (last 30 days)
  List<HealthEntry> getTrendData(String conditionId, String metricId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    return getEntriesForMetric(conditionId, metricId)
        .where((entry) => entry.timestamp.isAfter(thirtyDaysAgo))
        .toList();
  }

  // Calculate average for a numeric metric
  double? getAverageForMetric(String conditionId, String metricId, {int? days}) {
    DateTime? cutoffDate;
    if (days != null) {
      cutoffDate = DateTime.now().subtract(Duration(days: days));
    }

    final entries = getEntriesForMetric(conditionId, metricId)
        .where((entry) => cutoffDate == null || entry.timestamp.isAfter(cutoffDate))
        .toList();

    if (entries.isEmpty) return null;

    final numericValues = entries
        .map((entry) => entry.numericValue)
        .where((value) => value != null)
        .cast<double>()
        .toList();

    if (numericValues.isEmpty) return null;

    return numericValues.reduce((a, b) => a + b) / numericValues.length;
  }

  // Delete a health entry
  Future<bool> deleteHealthEntry(String entryId) async {
    _setLoading(true);
    _error = null;

    try {
      await _firestore.collection('health_entries').doc(entryId).delete();
      
      // Remove from local lists
      _recentEntries.removeWhere((entry) => entry.id == entryId);
      
      for (final conditionEntries in _entriesByCondition.values) {
        conditionEntries.removeWhere((entry) => entry.id == entryId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete health entry: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get metrics for a condition
  List<HealthMetric> getMetricsForCondition(String conditionId) {
    return HealthMetric.getMetricsForCondition(conditionId);
  }

  // Get condition by ID
  HealthCondition? getConditionById(String conditionId) {
    try {
      return _userConditions.firstWhere((condition) => condition.id == conditionId);
    } catch (e) {
      return null;
    }
  }
}
