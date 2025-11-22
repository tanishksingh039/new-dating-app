# Gender Options Update

## Summary
Removed the "Other" gender option from the onboarding flow and profile settings, keeping only "Male" and "Female" options.

## Changes Made

### 1. **Constants File** (`lib/utils/constants.dart`)
- **Line 138-141**: Updated `genderOptions` list
- **Before**: Had 3 options - Male, Female, Other
- **After**: Only 2 options - Male, Female

```dart
static const List<Map<String, dynamic>> genderOptions = [
  {'value': 'male', 'label': 'Male', 'icon': '👨'},
  {'value': 'female', 'label': 'Female', 'icon': '👩'},
];
```

### 2. **Edit Profile Screen** (`lib/screens/profile/edit_profile_screen.dart`)
- **Line 57**: Changed default `interestedIn` from 'Everyone' to 'Male'
- **Line 67**: Changed fallback from 'Everyone' to 'Male'
- **Line 511**: Removed 'Everyone' from dropdown options

```dart
// Dropdown now shows only:
items: ['Male', 'Female'].map((option) {
  return DropdownMenuItem(value: option, child: Text(option));
}).toList(),
```

## Impact

### Onboarding Flow
- **Basic Info Screen** (Step 2/10): Now shows only Male and Female gender options
- **Preferences Screen** (Step 5/5): Already only showed "Men" and "Women" - no changes needed

### Profile Management
- **Edit Profile Screen**: "Interested in" dropdown now shows only Male and Female options
- Default preference changed from "Everyone" to "Male"

## UI Changes
The gender selection in the onboarding "Tell us about yourself" screen now displays:
- 👨 Male
- 👩 Female

(Previously also had: 🧑 Other)

## Testing Checklist
- [ ] Test onboarding flow - verify only 2 gender options appear
- [ ] Test edit profile - verify "Interested in" dropdown has only 2 options
- [ ] Test existing users with "other" or "everyone" preferences - should default to "Male"
- [ ] Verify profile display for users who previously selected "other"

## Notes
- Users who previously selected "Other" or "Everyone" will automatically default to "Male" when they edit their profile
- No database migration needed - existing data remains unchanged
- The app gracefully handles legacy values through the normalization function
