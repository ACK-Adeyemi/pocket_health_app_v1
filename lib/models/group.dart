import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a community group auto-generated from health condition categories
class Group {
  final String id;
  final String name;
  final String description;
  final String category; // 'chronic', 'mental_health', 'acute', etc.
  final int memberCount;
  final int threadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? moderatorId; // Assigned moderator for this group

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.memberCount = 0,
    this.threadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.moderatorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'memberCount': memberCount,
      'threadCount': threadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'moderatorId': moderatorId,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      memberCount: map['memberCount']?.toInt() ?? 0,
      threadCount: map['threadCount']?.toInt() ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      isActive: map['isActive'] ?? true,
      moderatorId: map['moderatorId'],
    );
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? memberCount,
    int? threadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? moderatorId,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      memberCount: memberCount ?? this.memberCount,
      threadCount: threadCount ?? this.threadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      moderatorId: moderatorId ?? this.moderatorId,
    );
  }

  // Helper method to parse DateTime from Firestore
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // Generate groups from health condition categories
  static List<Group> generateGroupsFromConditions() {
    final now = DateTime.now();
    return [
      Group(
        id: 'chronic_conditions',
        name: 'Chronic Conditions',
        description: 'Support and discussion for chronic health conditions like diabetes, hypertension, and arthritis',
        category: 'chronic',
        createdAt: now,
        updatedAt: now,
      ),
      Group(
        id: 'mental_health',
        name: 'Mental Health',
        description: 'Safe space for discussing mental health challenges, anxiety, depression, and wellness',
        category: 'mental_health',
        createdAt: now,
        updatedAt: now,
      ),
      Group(
        id: 'acute_conditions',
        name: 'Acute Conditions',
        description: 'Recovery and management of acute illnesses and temporary health issues',
        category: 'acute',
        createdAt: now,
        updatedAt: now,
      ),
      Group(
        id: 'cardiovascular',
        name: 'Heart & Cardiovascular',
        description: 'Support for heart disease, hypertension, and cardiovascular health management',
        category: 'chronic',
        createdAt: now,
        updatedAt: now,
      ),
      Group(
        id: 'respiratory',
        name: 'Respiratory Health',
        description: 'Asthma, COPD, and other respiratory condition management and support',
        category: 'chronic',
        createdAt: now,
        updatedAt: now,
      ),
      Group(
        id: 'endocrine',
        name: 'Endocrine & Diabetes',
        description: 'Diabetes management, thyroid conditions, and endocrine system health',
        category: 'chronic',
        createdAt: now,
        updatedAt: now,
      ),
      Group(
        id: 'neurological',
        name: 'Neurological Conditions',
        description: 'Migraine, epilepsy, and other neurological health discussions',
        category: 'chronic',
        createdAt: now,
        updatedAt: now,
      ),
      Group(
        id: 'digestive',
        name: 'Digestive Health',
        description: 'IBD, IBS, and other digestive system conditions and management',
        category: 'chronic',
        createdAt: now,
        updatedAt: now,
      ),
      Group(
        id: 'autoimmune',
        name: 'Autoimmune Conditions',
        description: 'Lupus, rheumatoid arthritis, and other autoimmune disease support',
        category: 'chronic',
        createdAt: now,
        updatedAt: now,
      ),
      Group(
        id: 'cancer_support',
        name: 'Cancer Support',
        description: 'Support for cancer patients, survivors, and caregivers',
        category: 'chronic',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, category: $category, members: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
