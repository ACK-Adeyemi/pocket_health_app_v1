# Quick Check-In Flow Design Plan

## 1. Bottom Navigation Layout

The new navigation structure incorporates a 5th item in the center, designed as the primary action for daily engagement.

```
[ Home ]   [ Health ]   [ (Check-In) ]   [ Community ]   [ Profile ]
  Icon       Icon           Icon            Icon           Icon
  "Home"    "Health"     "Check-In"      "Community"    "Profile"
```

*   **Icon**: `Icons.add_circle` (Primary color, slightly larger/elevated).
*   **Label**: "Check-In".
*   **Placement**: Center slot (Index 2).
*   **Visual Style**: Uses a Floating Action Button (FAB) style or an elevated Material design check-in button to distinguish it from static tabs.

## 2. Interaction Flow Map

1.  **Entry**: User taps the center "Check-In" button.
2.  **Selection (Logic)**: 
    *   If user has only one condition: Go directly to that condition's quick question.
    *   If user has many: System selects the condition not logged today, or the most "critical" one based on previous severity.
3.  **Action**: Modal Bottom Sheet slides up.
    *   One question: e.g., "Rate your pain level for Arthritis" with a slider.
    *   No typing required.
4.  **Completion**: User adjusts slider/taps option -> Taps "Done".
5.  **Success**: Brief "Logged!" animation (haptic feedback).
6.  **Exit**: Modal closes automatically, returning user to their previous tab.

## 3. State Logic Rules

*   **Question Rotation**: For multi-condition users, the app will cycle through one condition per day.
*   **Persistence**: 
    *   The app remembers `preferredLoggingMode` ('quick' vs 'classic').
    *   If A/B test group A: Default to Quick Check-In UI.
    *   If A/B test group B: Keep Classic Log UI prominent, Quick as an option.
*   **Frequency**: Quick Check-In is limited to once per session or until all daily metrics are pulse-checked.

## 4. Onboarding Flow

### First-Time Exposure (New Users)
*   Integrated into the standard onboarding flow after condition selection.
*   Slide explaining: "Daily pulse: track your health in <10 seconds."

### Existing Users (Migration)
*   **Pulse Tooltip**: On first app launch after update, a high-contrast tooltip points to the center button.
*   **Copy**: "New! Log your daily health faster with Quick Check-In."

## 5. Analytics Event Schema

| Event Name | Parameters | Description |
|------------|------------|-------------|
| `check_in_started` | `mode` (quick\|classic), `trigger` (nav\|home_card) | User enters logging flow |
| `check_in_completed` | `mode`, `condition_id`, `duration_ms` | User successfully saves data |
| `check_in_abandoned` | `mode`, `step` | User closes without saving |
| `ab_group_assigned` | `group_id` (A\|B) | Tracking which cohort the user belongs to |

## 6. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Data Fragmentation | The "Health" tab remains for comprehensive multi-metric logging. |
| User Confusion | Onboarding tooltips and clear "Switch to Classic" link within the Quick flow. |
| Cognitive Load | Only ONE question per quick check-in. Never more. |

## 7. Final Recommendation

**Should Quick Check-In replace Classic Log long-term?**
No. It should **augment** it. 
Quick Check-In is for **consistency** (high-frequency, low-detail).
Classic Log is for **accuracy** (low-frequency, high-detail).
We recommend keeping the center button for Quick Check-In as the daily "Pulse" while retaining the "Health" tab for trend analysis and historical management.
