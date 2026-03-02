# ADR 005: Quick Check-In UX Integration

## Status
Proposed

## Context
Existing users find multi-metric logging (Classic Log) time-consuming for daily tracking. We are introducing a "Quick Check-In" flow designed for <10 second completion. We need a way to integrate this into the existing 4-item navigation without increasing cognitive overload or disrupting current workflows.

## Decision
1.  **Navigation**: We will transition from a 4-item to a 5-item bottom navigation bar.
2.  **Placement**: The "Check-In" action will occupy the center slot (index 2).
3.  **UI Pattern**: The Quick Check-In will be implemented as a Modal Bottom Sheet to maintain context and allow rapid entry/exit.
4.  **Question Logic**: A `QuickCheckInProvider` will implement a rotation algorithm to ask one question per session, prioritizing conditions not yet logged today.
5.  **A/B Testing**: Users will be randomly assigned to Group A (Quick-first) or Group B (Classic-first) via the `abTestGroup` field in their profile.
    *   Group A: Navigation label "Full Log" for the health tab, prominent "Daily Pulse" home card.
    *   Group B: Traditional "Health" label, Quick Check-In as a secondary enhancement.
6.  **Persistence**: User preference for logging style is stored in `preferredLoggingMode`.

## Consequences
*   **Pros**: 
    *   Drastically reduces friction for daily engagement.
    *   Scales well for multi-condition users via rotation logic.
    *   Allows data-driven decisions through A/B testing.
*   **Cons**:
    *   Increases bottom navigation complexity from 4 to 5 items.
    *   Requires clear onboarding to explain the two different logging modes.

## Alternatives Considered
*   **Replacing the Health Tab**: Rejected because detailed historical logging is still necessary for clinical review.
*   **Floating Action Button (FAB)**: Considered, but standard bottom navigation items provide better discoverability for older users (40+) and maintain design consistency across iOS/Android.
