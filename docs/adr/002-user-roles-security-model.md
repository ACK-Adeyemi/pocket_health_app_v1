# 002: User Roles and Security Model

## Status
Accepted

## Context
The community feature requires a robust role-based access control (RBAC) system to manage user permissions while maintaining security in a healthcare application. Key security concerns include:

- Protecting sensitive health information
- Preventing unauthorized access to moderation tools
- Ensuring accountability for content changes
- Maintaining user privacy and anonymity
- Compliance with healthcare data protection standards

The existing authentication system uses Firebase Auth, which provides a foundation but needs extension for role management.

## Decision
We will implement a hybrid security model combining Firestore-based roles with Firebase Security Rules, prioritizing security for healthcare data.

### Role Definitions
- **User**: Default role for all registered users
  - Can access groups related to their health conditions
  - Full CRUD operations on own threads/comments
  - Can like/dislike and report content
  - Cannot access moderation features

- **Moderator**: Elevated permissions for content management
  - All user permissions
  - Can moderate content in assigned groups
  - Can view and resolve reports
  - Can edit/delete any content in moderated groups
  - Cannot manage user roles

- **Admin**: Full system access
  - All moderator permissions
  - Can assign/revoke moderator and admin roles
  - Can access all groups regardless of health conditions
  - Can perform system-wide content moderation
  - Can view audit logs and system analytics

### Role Assignment Strategy
- **Automatic**: New users get "user" role by default
- **Manual**: Admins assign moderator roles based on criteria
- **Criteria-Based**: Future enhancement for reputation-based promotion
- **Healthcare Professional**: Optional flag for specialized moderation

### Security Implementation
- **Firestore Storage**: Roles stored in user documents with strict access controls
- **Security Rules**: Comprehensive Firebase Security Rules for data access
- **Client Validation**: Input sanitization and permission checks
- **Audit Logging**: All role changes and moderation actions logged
- **Session Management**: Secure token handling with automatic expiration

### Anonymity Implementation
- **Display Names**: SHA-256 hash of user ID with salt for consistent anonymity
- **No Real Names**: User profiles never expose real identities in community
- **Consistent IDs**: Same user always appears with same anonymous ID in threads
- **Metadata Protection**: No correlation between anonymous IDs and personal data

## Consequences

### Positive
- Clear separation of responsibilities
- Scalable permission system
- Strong privacy protection through anonymity
- Audit trail for compliance
- Flexible role management for healthcare context

### Negative
- Increased complexity in permission logic
- Additional database queries for role validation
- Higher maintenance overhead for security rules
- Potential performance impact from access control checks

### Risks
- Role escalation vulnerabilities
- Anonymous ID collision (extremely low probability with SHA-256)
- Audit log tampering
- Insider threats from privileged users

## Alternatives Considered

### Option 1: Firebase Custom Claims Only
- Store roles in Firebase Auth custom claims
- **Rejected**: Limited to 1000 bytes, no complex role hierarchies, harder to audit

### Option 2: Database-Only Roles
- All roles in Firestore without Security Rules
- **Rejected**: Insufficient security for healthcare data, client-side bypass possible

### Option 3: External IAM Service
- Use AWS Cognito or Auth0 for role management
- **Rejected**: Increases complexity and cost, overkill for current scale

### Option 4: Simple Boolean Flags
- isModerator, isAdmin flags instead of enum
- **Rejected**: Less flexible, harder to extend, no clear hierarchy

## Notes
- Regular security audits required for Firestore rules
- Role changes must be logged with admin user and timestamp
- Anonymous ID generation must be deterministic and collision-resistant
- Consider implementing role expiration for temporary moderation
- Healthcare professional verification process needed for specialized roles
