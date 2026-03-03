# Changelog

All notable changes to Pocket Health will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Enhanced Responsiveness & Viewport Management**: Comprehensive fix for layout issues on mobile browsers and small devices (e.g., iPhone SE).
  - Replaced all flex-based vertical spacers with fixed spacing to prevent content "squashing" by browser toolbars and keyboards.
  - Implemented `AlwaysScrollableScrollPhysics` across all forms to ensure consistent interactivity.
  - Optimized keyboard handling by leveraging automatic Scaffold resizing and removing conflicting manual padding.
  - Refactored `CreateThreadDialog`, `ReportDialog`, and `QuickCheckInModal` for better adaptation to constrained heights.
- **Profile Role Visibility**: Display user role (Admin/Moderator) on the profile page for elevated accounts.
- **Community Forum System**: Complete implementation of user community features
  - Groups auto-generated from health condition categories
  - Thread creation, editing, and archiving
  - Comment system with like/dislike functionality
  - Anonymous user identities for privacy protection
  - Role-based access control (User, Moderator, Admin)
  - Content moderation and reporting system
  - Healthcare-specific report categories

### Security
- **User Role System**: Implemented comprehensive role-based access control
  - Default "user" role for all new registrations
  - "moderator" role for content management
  - "admin" role for system administration
  - Manual role assignment by administrators
  - Audit logging for all role changes

- **Privacy Protection**: Enhanced anonymity and data protection
  - SHA-256 hashed anonymous display names
  - Complete separation of community and personal data
  - Access control based on user's health conditions
  - No exposure of real names or personal information in community

- **Content Moderation**: Healthcare-appropriate moderation system
  - User reporting with predefined categories
  - Moderator dashboard for content review
  - Escalation system for critical content
  - Audit trail for all moderation actions

### Technical
- **New Models**: Added community data models
  - `Group`: Auto-generated from health conditions
  - `Thread`: Discussion topics within groups
  - `Comment`: User replies with voting
  - `Report`: Content moderation system

- **Provider Architecture**: New `CommunityProvider` for state management
  - Real-time updates for threads and comments
  - Offline support for community content
  - Efficient data synchronization

- **UI Components**: Complete community interface
  - Group selection and navigation
  - Thread list and detail views
  - Comment threads with nested replies
  - Moderation tools and dashboards

### Database
- **New Collections**: Firestore schema for community features
  - `groups`: Auto-generated group definitions
  - `threads`: User-created discussion topics
  - `comments`: Thread replies and interactions
  - `reports`: Content moderation queue
  - `audit_logs`: Security and moderation tracking

- **Security Rules**: Comprehensive Firestore security rules
  - Role-based data access control
  - Privacy protection for sensitive content
  - Audit logging for compliance

## [1.0.0] - 2025-01-15

### Added
- Initial release of Pocket Health
- User registration and authentication
- Health condition tracking and management
- Basic health metrics logging
- User profile management
- Onboarding flow for new users

### Technical
- Flutter application with Firebase backend
- Basic provider architecture for state management
- Responsive UI with health-focused design
- Initial test suite setup
