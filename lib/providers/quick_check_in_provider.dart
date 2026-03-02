import 'package:flutter/foundation.dart';
import '../models/health_condition.dart';
import '../models/health_metric.dart';
import '../models/health_entry.dart';
import 'health_tracking_provider.dart';
import 'user_provider.dart';

class QuickCheckInProvider extends ChangeNotifier {
  UserProvider userProvider;
  HealthTrackingProvider healthProvider;

  QuickCheckInProvider({
    required this.userProvider,
    required this.healthProvider,
  });

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void updateDependencies({
    required UserProvider userProvider,
    required HealthTrackingProvider healthProvider,
  }) {
    this.userProvider = userProvider;
    this.healthProvider = healthProvider;
    
    // Auto-prepare if we have data but no selection, but DON'T clear if we already have one
    if (_selectedCondition == null && userProvider.userProfile != null) {
      prepareCheckIn();
    }
  }

  HealthCondition? _selectedCondition;
  HealthMetric? _selectedMetric;
  bool _isSaving = false;

  HealthCondition? get selectedCondition => _selectedCondition;
  HealthMetric? get selectedMetric => _selectedMetric;
  bool get isSaving => _isSaving;

  /// Determines which condition and metric to ask about for the current session.
  /// Logic:
  /// 1. Find conditions not logged today.
  /// 2. If all logged, pick the oldest one.
  /// 3. For the picked condition, select the primary "Quick" metric.
  void prepareCheckIn({bool force = false}) {
    // If not forced and we already have a selection, don't change it to avoid UI flashes
    if (!force && _selectedCondition != null && _selectedMetric != null) {
      return;
    }

    final conditions = userProvider.userProfile?.healthConditions ?? [];
    if (conditions.isEmpty) {
      _selectedCondition = null;
      _selectedMetric = null;
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    HealthCondition? candidate;
    
    // Check for conditions not logged today
    for (final condition in conditions) {
      final entries = healthProvider.getEntriesForCondition(condition.id);
      final loggedToday = entries.any((e) => 
        e.timestamp.isAfter(today) || e.timestamp.isAtSameMomentAs(today)
      );

      if (!loggedToday) {
        candidate = condition;
        break;
      }
    }

    // Fallback: pick the one with the oldest entry or just the first one
    candidate ??= conditions.first;

    _selectedCondition = candidate;
    _selectedMetric = _getQuickMetricForCondition(candidate.id);
    
    notifyListeners();
  }

  HealthMetric? _getQuickMetricForCondition(String conditionId) {
    final metrics = healthProvider.getMetricsForCondition(conditionId);
    if (metrics.isEmpty) return null;

    // Preference mapping for "Quick" metrics (usually sliders/scales)
    switch (conditionId) {
      case 'arthritis':
        return metrics.firstWhere((m) => m.id == 'arthritis_pain_vas', orElse: () => metrics.first);
      case 'diabetes_type1':
      case 'diabetes_type2':
        return metrics.firstWhere((m) => m.id == 'diabetes_glucose', orElse: () => metrics.first);
      case 'hypertension':
        return metrics.firstWhere((m) => m.id == 'bp_systolic', orElse: () => metrics.first);
      case 'asthma':
        return metrics.firstWhere((m) => m.id == 'asthma_peak_flow', orElse: () => metrics.first);
      case 'depression':
        return metrics.firstWhere((m) => m.id == 'depression_mood', orElse: () => metrics.first);
      case 'anxiety':
        return metrics.firstWhere((m) => m.id == 'anxiety_level', orElse: () => metrics.first);
      case 'copd':
        return metrics.firstWhere((m) => m.id == 'copd_breathlessness', orElse: () => metrics.first);
      case 'heart_disease':
        return metrics.firstWhere((m) => m.id == 'heart_fatigue', orElse: () => metrics.first);
      case 'migraine':
        return metrics.firstWhere((m) => m.id == 'migraine_severity', orElse: () => metrics.first);
      case 'obesity':
        return metrics.firstWhere((m) => m.id == 'obesity_activity', orElse: () => metrics.first);
      case 'thyroid':
        return metrics.firstWhere((m) => m.id == 'thyroid_energy', orElse: () => metrics.first);
      default:
        return metrics.first;
    }
  }

  Future<bool> submitCheckIn(dynamic value) async {
    if (_selectedCondition == null || _selectedMetric == null || _disposed) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final entry = HealthEntry(
        id: '',
        userId: userProvider.userProfile!.uid,
        conditionId: _selectedCondition!.id,
        metricId: _selectedMetric!.id,
        value: value,
        timestamp: DateTime.now(),
        source: 'quick',
      );

      final success = await healthProvider.addHealthEntry(entry);
      
      if (!_disposed) {
        _isSaving = false;
        if (success) {
          _logAnalyticsEvent('check_in_completed', {
            'mode': 'quick',
            'condition_id': _selectedCondition!.id,
            'metric_id': _selectedMetric!.id,
          });
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      if (!_disposed) {
        _isSaving = false;
        notifyListeners();
      }
      return false;
    }
  }

  void _logAnalyticsEvent(String name, Map<String, dynamic> params) {
    // In a real app, this would call Firebase Analytics or similar
    if (kDebugMode) {
      print('ANALYTICS: Event: $name, Params: $params');
    }
  }
}
