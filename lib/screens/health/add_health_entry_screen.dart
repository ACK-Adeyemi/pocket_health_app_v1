import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/health_tracking_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/health_condition.dart';
import '../../models/health_metric.dart';
import '../../models/health_entry.dart';
import '../../utils/app_colors.dart';

class AddHealthEntryScreen extends StatefulWidget {
  final HealthCondition condition;
  final HealthMetric? selectedMetric;

  const AddHealthEntryScreen({
    super.key,
    required this.condition,
    this.selectedMetric,
  });

  @override
  State<AddHealthEntryScreen> createState() => _AddHealthEntryScreenState();
}

class _AddHealthEntryScreenState extends State<AddHealthEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _entryValues = {};
  final Map<String, TextEditingController> _controllers = {};
  DateTime _selectedDateTime = DateTime.now();
  String _notes = '';
  bool _isLoading = false;
  List<HealthMetric> _metrics = [];

  @override
  void initState() {
    super.initState();
    _metrics = HealthMetric.getMetricsForCondition(widget.condition.id);
    
    // Initialize controllers and default values
    for (final metric in _metrics) {
      _controllers[metric.id] = TextEditingController();
      if (metric.options != null && metric.options!.isNotEmpty) {
        _entryValues[metric.id] = metric.options!.first;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final healthProvider = Provider.of<HealthTrackingProvider>(context, listen: false);
      
      if (userProvider.userProfile == null) {
        throw Exception('User not logged in');
      }

      // Check if this is a grouped entry (like blood pressure)
      final isBloodPressureEntry = _metrics.any((m) => m.id == 'bp_systolic') && 
                                   _metrics.any((m) => m.id == 'bp_diastolic');

      if (isBloodPressureEntry && _entryValues.containsKey('bp_systolic') && _entryValues.containsKey('bp_diastolic')) {
        // Create grouped blood pressure entry
        final entries = [
          HealthEntry(
            id: '',
            userId: userProvider.userProfile!.uid,
            conditionId: widget.condition.id,
            metricId: 'bp_systolic',
            value: _entryValues['bp_systolic'],
            timestamp: _selectedDateTime,
            notes: _notes.isNotEmpty ? _notes : null,
          ),
          HealthEntry(
            id: '',
            userId: userProvider.userProfile!.uid,
            conditionId: widget.condition.id,
            metricId: 'bp_diastolic',
            value: _entryValues['bp_diastolic'],
            timestamp: _selectedDateTime,
            notes: _notes.isNotEmpty ? _notes : null,
          ),
        ];

        // Add heart rate if provided
        if (_entryValues.containsKey('bp_heart_rate') && _entryValues['bp_heart_rate'] != null) {
          entries.add(HealthEntry(
            id: '',
            userId: userProvider.userProfile!.uid,
            conditionId: widget.condition.id,
            metricId: 'bp_heart_rate',
            value: _entryValues['bp_heart_rate'],
            timestamp: _selectedDateTime,
            notes: _notes.isNotEmpty ? _notes : null,
          ));
        }

        final entryGroup = HealthEntryGroup(
          id: '',
          userId: userProvider.userProfile!.uid,
          conditionId: widget.condition.id,
          timestamp: _selectedDateTime,
          entries: entries,
          notes: _notes.isNotEmpty ? _notes : null,
        );

        final success = await healthProvider.addHealthEntryGroup(entryGroup);
        if (!success) {
          throw Exception('Failed to save health entries');
        }
      } else {
        // Create individual entries
        for (final metric in _metrics) {
          if (_entryValues.containsKey(metric.id) && _entryValues[metric.id] != null) {
            final entry = HealthEntry(
              id: '',
              userId: userProvider.userProfile!.uid,
              conditionId: widget.condition.id,
              metricId: metric.id,
              value: _entryValues[metric.id],
              timestamp: _selectedDateTime,
              notes: _notes.isNotEmpty ? _notes : null,
            );

            final success = await healthProvider.addHealthEntry(entry);
            if (!success) {
              throw Exception('Failed to save health entry for ${metric.name}');
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health entry saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMetricInput(HealthMetric metric) {
    switch (metric.type) {
      case MetricType.pain:
      case MetricType.mood:
      case MetricType.anxiety:
        return _buildScaleInput(metric);
      case MetricType.bloodGlucose:
      case MetricType.bloodPressure:
      case MetricType.peakFlow:
      case MetricType.heartRate:
      case MetricType.weight:
      case MetricType.temperature:
        return _buildNumericInput(metric);
      case MetricType.custom:
        if (metric.options != null) {
          return _buildDropdownInput(metric);
        } else if (metric.unit == MetricUnit.scale0to10) {
          return _buildScaleInput(metric);
        } else {
          return _buildNumericInput(metric);
        }
    }
  }

  Widget _buildScaleInput(HealthMetric metric) {
    final currentValue = _entryValues[metric.id]?.toDouble() ?? 0.0;
    final maxValue = metric.maxValue ?? 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          metric.description,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
        if (metric.instructions != null) ...[
          SizedBox(height: 4.h),
          Text(
            metric.instructions!,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        SizedBox(height: 12.h),
        Row(
          children: [
            Text(
              '0',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Slider(
                value: currentValue,
                min: 0,
                max: maxValue,
                divisions: maxValue.toInt(),
                activeColor: metric.color,
                onChanged: (value) {
                  setState(() {
                    _entryValues[metric.id] = value;
                  });
                },
              ),
            ),
            Text(
              maxValue.toInt().toString(),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: metric.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '${currentValue.toInt()}${metric.getUnitDisplay()}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: metric.color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumericInput(HealthMetric metric) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          metric.description,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
        if (metric.instructions != null) ...[
          SizedBox(height: 4.h),
          Text(
            metric.instructions!,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        SizedBox(height: 8.h),
        TextFormField(
          controller: _controllers[metric.id],
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter ${metric.name.toLowerCase()}',
            suffixText: metric.getUnitDisplay(),
            prefixIcon: Icon(metric.icon, color: metric.color),
          ),
          validator: (value) {
            if (metric.isRequired && (value == null || value.isEmpty)) {
              return '${metric.name} is required';
            }
            if (value != null && value.isNotEmpty) {
              final numValue = double.tryParse(value);
              if (numValue == null) {
                return 'Please enter a valid number';
              }
              if (metric.minValue != null && numValue < metric.minValue!) {
                return 'Value must be at least ${metric.minValue}';
              }
              if (metric.maxValue != null && numValue > metric.maxValue!) {
                return 'Value must be at most ${metric.maxValue}';
              }
            }
            return null;
          },
          onChanged: (value) {
            final numValue = double.tryParse(value);
            if (numValue != null) {
              _entryValues[metric.id] = numValue;
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdownInput(HealthMetric metric) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          metric.description,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: _entryValues[metric.id] as String?,
          decoration: InputDecoration(
            prefixIcon: Icon(metric.icon, color: metric.color),
          ),
          items: metric.options!.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _entryValues[metric.id] = value;
            });
          },
          validator: (value) {
            if (metric.isRequired && value == null) {
              return '${metric.name} is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add ${widget.condition.name} Entry',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date/Time Selection
                    Card(
                      color: AppColors.surface,
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date & Time',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDateTime,
                                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _selectedDateTime = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.grey300),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: AppColors.primary),
                                    SizedBox(width: 12.w),
                                    Text(
                                      '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} at ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Metrics Input
                    ..._metrics.map((metric) {
                      return Card(
                        color: AppColors.surface,
                        margin: EdgeInsets.only(bottom: 16.h),
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: _buildMetricInput(metric),
                        ),
                      );
                    }).toList(),

                    // Notes Section
                    Card(
                      color: AppColors.surface,
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notes (Optional)',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextFormField(
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Add any additional notes about this entry...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              onChanged: (value) {
                                _notes = value;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: Text(
                          'Save Entry',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
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
