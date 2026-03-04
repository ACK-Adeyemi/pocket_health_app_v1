import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_condition.dart';
import '../models/health_entry.dart';
import 'health_tracking_provider.dart';
import 'user_provider.dart';

class QuickCheckInProvider extends ChangeNotifier {
  UserProvider userProvider;
  HealthTrackingProvider healthProvider;

  QuickCheckInProvider({
    required this.userProvider,
    required this.healthProvider,
  }) {
    _loadLocalState();
  }

  bool _disposed = false;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

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

  // --- State Variables ---
  int _currentStep = 1;
  int _medSubStep = 1;
  HealthCondition? _selectedCondition;
  String? _howUserIsFeelingToday;
  dynamic _signalValue;
  String? _context;
  bool? _takesMedication; 
  bool? _takenToday; 
  String? _medsStability; 
  bool _isSaving = false;
  int _streak = 0;
  List<String> _completedConditionIdsToday = [];
  
  // --- Getters ---
  int get currentStep => _currentStep;
  int get medSubStep => _medSubStep;
  HealthCondition? get selectedCondition => _selectedCondition;
  String? get howUserIsFeelingToday => _howUserIsFeelingToday;
  dynamic get signalValue => _signalValue;
  String? get context => _context;
  bool? get takesMedication => _takesMedication;
  bool? get takenToday => _takenToday;
  String? get medsStability => _medsStability;
  bool get isSaving => _isSaving;
  int get streak => _streak;
  List<String> get completedConditionIdsToday => _completedConditionIdsToday;

  // --- Initialization ---

  Future<void> _loadLocalState() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final prefs = _prefs;
      if (prefs != null) {
        _streak = prefs.getInt('check_in_streak') ?? 0;

        final lastCheckInStr = prefs.getString('last_check_in_date');
        if (lastCheckInStr != null) {
          final lastCheckInDate = DateTime.parse(lastCheckInStr);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          if (lastCheckInDate.isBefore(yesterday)) {
            _streak = 0;
            await prefs.setInt('check_in_streak', 0);
          }

          if (DateTime(lastCheckInDate.year, lastCheckInDate.month, lastCheckInDate.day).isAtSameMomentAs(today)) {
            _completedConditionIdsToday = prefs.getStringList('completed_conditions_today') ?? [];
            _howUserIsFeelingToday = prefs.getString('today_how_user_is_feeling');
          } else {
            _completedConditionIdsToday = [];
            _howUserIsFeelingToday = null;
            await prefs.setStringList('completed_conditions_today', []);
            await prefs.remove('today_how_user_is_feeling');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('SharedPrefs init failed: $e');
    } finally {
      _isInitialized = true;
      // Ensure we have an initial condition if profile is already loaded
      if (userProvider.userProfile != null) {
        prepareNextCondition();
      }
      notifyListeners();
    }
  }

  void updateDependencies({
    required UserProvider userProvider,
    required HealthTrackingProvider healthProvider,
  }) {
    this.userProvider = userProvider;
    this.healthProvider = healthProvider;

    if (_isInitialized && userProvider.userProfile != null) {
      // If no condition is selected, or the selected one is already done, pick the next one
      if (_selectedCondition == null || _completedConditionIdsToday.contains(_selectedCondition!.id)) {
        prepareNextCondition();
      }
    }
  }

  // --- Flow Logic ---

  void startFlow() {
    _currentStep = (_howUserIsFeelingToday != null) ? 2 : 1;
    _medSubStep = 1;
    _signalValue = null;
    _context = null;
    _takesMedication = null;
    _takenToday = null;
    _medsStability = null;
    prepareNextCondition();
    notifyListeners();
  }

  void goBack() {
    if (_currentStep == 2) {
      _currentStep = 1;
    } else if (_currentStep == 3) {
      _currentStep = 2;
    } else if (_currentStep == 4) {
      if (_medSubStep > 1) {
        _medSubStep--;
      } else {
        // If we skipped step 3 (context) because of a 'good' signal/state, go back to step 2
        if (_isNormalValue(_selectedCondition!.id, _signalValue) && _howUserIsFeelingToday == 'good') {
          _currentStep = 2;
        } else {
          _currentStep = 3;
        }
      }
    }
    notifyListeners();
  }

  void prepareNextCondition() {
    final conditions = userProvider.userProfile?.healthConditions ?? [];
    if (conditions.isEmpty) {
      _selectedCondition = null;
      notifyListeners();
      return;
    }

    final remaining = conditions.where((c) => !_completedConditionIdsToday.contains(c.id)).toList();

    if (remaining.isEmpty) {
      _selectedCondition = null;
      notifyListeners();
      return;
    }

    remaining.sort((a, b) {
      final aUnstable = _isRecentlyUnstable(a.id);
      final bUnstable = _isRecentlyUnstable(b.id);
      if (aUnstable && !bUnstable) return -1;
      if (!aUnstable && bUnstable) return 1;
      return _getClinicalRisk(b.id).compareTo(_getClinicalRisk(a.id));
    });

    _selectedCondition = remaining.first;
    notifyListeners();
  }

  bool _isRecentlyUnstable(String conditionId) {
    final entries = healthProvider.getTrendData(conditionId, _getQuickMetricId(conditionId));
    int nonNormalCount = 0;
    for (final entry in entries) {
      if (!_isNormalValue(conditionId, entry.value)) {
        nonNormalCount++;
      }
    }
    return nonNormalCount > 3;
  }

  int _getClinicalRisk(String conditionId) {
    switch (conditionId) {
      case 'heart_disease':
      case 'hypertension':
      case 'copd': return 5;
      case 'diabetes_type1':
      case 'diabetes_type2': return 4;
      case 'asthma':
      case 'depression': return 3;
      case 'anxiety':
      case 'migraine':
      case 'thyroid': return 2;
      case 'arthritis':
      case 'obesity': return 1;
      default: return 0;
    }
  }

  String _getQuickMetricId(String conditionId) {
    switch (conditionId) {
      case 'asthma':
      case 'copd': return 'respiratory_status';
      case 'diabetes_type1':
      case 'diabetes_type2': return 'blood_sugar_feel';
      case 'hypertension': return 'heart_bp_feel';
      case 'heart_disease': return 'heart_fatigue';
      case 'migraine': return 'head_pain';
      case 'anxiety': return 'anxiety_level';
      case 'depression': return 'mood_today';
      case 'thyroid': return 'energy_level';
      case 'arthritis': return 'joint_pain';
      case 'obesity': return 'today_felt';
      default: return 'general_feel';
    }
  }

  bool _isNormalValue(String conditionId, dynamic value) {
    if (value == null) return true;
    final val = value.toString().toLowerCase();
    return val == 'normal' || val == 'good' || val == 'stable' || val == 'calm' || val == 'none' || val == 'on track';
  }

  // --- Step Actions ---

  void setHowUserIsFeelingToday(String state) {
    _howUserIsFeelingToday = state;
    _currentStep = 2;
    // Persist feeling for the day
    if (_prefs != null) {
      _prefs!.setString('today_how_user_is_feeling', state);
    }
    notifyListeners();
  }

  void setSignalValue(dynamic value) {
    _signalValue = value;
    if (_isNormalValue(_selectedCondition!.id, value) && _howUserIsFeelingToday == 'good') {
      _goToMedicationStep();
    } else {
      _currentStep = 3;
    }
    notifyListeners();
  }

  void setContext(String? context) {
    _context = context;
    _goToMedicationStep();
    notifyListeners();
  }

  void _goToMedicationStep() {
    _currentStep = 4;
    if (_selectedCondition?.takesMedication != null) {
      _takesMedication = _selectedCondition!.takesMedication;
      if (_takesMedication == true) {
        _medSubStep = 2;
      } else {
        _submitAndMoveToConfirmation();
      }
    } else {
      _medSubStep = 1;
    }
  }

  void setTakesMedication(bool value) {
    _takesMedication = value;
    if (!value) {
      _medsStability = null;
      _submitAndMoveToConfirmation();
    } else {
      _medSubStep = 2;
    }
    notifyListeners();
  }

  void setTakenToday(bool? value) {
    _takenToday = value;
    if (value == false) {
      _medsStability = 'not_at_all';
      _submitAndMoveToConfirmation();
    } else {
      _medSubStep = 3;
    }
    notifyListeners();
  }

  void setMedicationStability(String stability) {
    _medsStability = stability;
    _submitAndMoveToConfirmation();
    notifyListeners();
  }

  Future<void> _submitAndMoveToConfirmation() async {
    _isSaving = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final userId = userProvider.userProfile!.uid;
      
      // 1. Log Wellbeing
      await healthProvider.addHealthEntry(HealthEntry(
        id: '',
        userId: userId,
        conditionId: 'wellbeing',
        metricId: 'overall',
        value: _howUserIsFeelingToday,
        timestamp: now,
        source: 'quick',
      ));

      if (_selectedCondition != null) {
        // 2. Log Condition Signal
        await healthProvider.addHealthEntry(HealthEntry(
          id: '',
          userId: userId,
          conditionId: _selectedCondition!.id,
          metricId: _getQuickMetricId(_selectedCondition!.id),
          value: _signalValue,
          timestamp: now,
          source: 'quick',
        ));

        // 3. Log Context
        if (_context != null) {
          await healthProvider.addHealthEntry(HealthEntry(
            id: '',
            userId: userId,
            conditionId: _selectedCondition!.id,
            metricId: 'context',
            value: _context,
            timestamp: now,
            source: 'quick',
          ));
        }

        // 4. Local State Update (Move up for reactivity)
        _completedConditionIdsToday.add(_selectedCondition!.id);
        try {
          if (_prefs != null) {
            await _prefs!.setStringList('completed_conditions_today', _completedConditionIdsToday);
          }
        } catch (e) {
          if (kDebugMode) print('Local storage update failed: $e');
        }

        // 5. Update Model (Triggers updateDependencies in ProxyProvider)
        final updatedCondition = _selectedCondition!.copyWith(
          takesMedication: _takesMedication,
          medicationStabilityMetric: _medsStability,
        );
        final currentConditions = List<HealthCondition>.from(userProvider.userProfile!.healthConditions);
        final index = currentConditions.indexWhere((c) => c.id == _selectedCondition!.id);
        if (index != -1) {
          currentConditions[index] = updatedCondition;
          await userProvider.updateHealthConditions(currentConditions);
        }
      }
      
      // Update streak
      final today = DateTime(now.year, now.month, now.day);
      bool shouldIncrStreak = true;
      try {
        if (_prefs != null) {
          final lastCheckInStr = _prefs!.getString('last_check_in_date');
          if (lastCheckInStr != null) {
            final lastDate = DateTime.parse(lastCheckInStr);
            if (DateTime(lastDate.year, lastDate.month, lastDate.day).isAtSameMomentAs(today)) {
              shouldIncrStreak = false;
            }
          }
          if (shouldIncrStreak) {
            _streak++;
            await _prefs!.setInt('check_in_streak', _streak);
            await _prefs!.setString('last_check_in_date', today.toIso8601String());
          }
        } else {
           if (shouldIncrStreak) _streak++;
        }
      } catch (e) {
        if (shouldIncrStreak) _streak++;
        if (kDebugMode) print('Streak storage failed: $e');
      }

      _currentStep = 5;
      prepareNextCondition(); // Advance to next condition for the dashboard card
    } catch (e) {
      if (kDebugMode) print('Error submitting check-in: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void nextCondition() {
    _currentStep = (_howUserIsFeelingToday != null) ? 2 : 1;
    _medSubStep = 1;
    _signalValue = null;
    _context = null;
    _takesMedication = null;
    _takenToday = null;
    _medsStability = null;
    prepareNextCondition();
    notifyListeners();
  }
}
