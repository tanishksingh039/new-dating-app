# Terms & Conditions Agreement - Implementation Guide

## Overview
A professional Terms & Conditions agreement screen has been integrated into the onboarding flow. Users must read and explicitly agree to the terms before proceeding with account setup.

## Features

### ✅ Professional UI/UX
- Clean, modern design with proper spacing and typography
- Scrollable content area for comprehensive terms
- Professional checkbox with visual feedback
- Disabled "Continue" button until agreement is checked
- Smooth animations and transitions

### ✅ Comprehensive Content
The agreement includes four main sections:

1. **Terms of Service**
   - Age requirement (18+)
   - Account responsibility
   - Prohibited activities
   - Content policies
   - Account suspension terms
   - Data processing notice

2. **Community Guidelines**
   - Respect and dignity requirements
   - No harassment policy
   - Explicit content prohibition
   - Anti-spam measures
   - Authentic profile requirement
   - Anti-scam measures
   - Reporting mechanism
   - Privacy respect

3. **Privacy Policy**
   - Data collection details
   - Data usage explanation
   - Data protection measures
   - Third-party services disclosure
   - Contact information

4. **Safety & Security**
   - Identity verification
   - Reporting mechanisms
   - Password security
   - Financial safety
   - Blocking features
   - Support contact

### ✅ User Flow Control
- Users CANNOT proceed without checking the agreement box
- "Continue" button is disabled until agreement is checked
- Visual feedback shows agreement status
- "Go Back" option allows users to reconsider
- Saves agreement acceptance to Firestore with timestamp

## File Structure

```
lib/screens/onboarding/
├── terms_and_conditions_screen.dart (NEW)
└── phone_verification_screen.dart (MODIFIED)

lib/main.dart (MODIFIED)
```

## Implementation Details

### Screen Location in Onboarding Flow
```
Welcome Screen
    ↓
Phone Verification
    ↓
Terms & Conditions ← NEW (MANDATORY)
    ↓
Basic Info
    ↓
Detailed Profile
    ↓
... (rest of onboarding)
```

### Database Schema
When user agrees to terms, the following is saved to Firestore:

```dart
{
  'agreedToTerms': true,
  'termsAcceptedAt': DateTime.now(),
  'onboardingStep': 'terms_accepted',
}
```

### Key Components

#### 1. Agreement Checkbox
```dart
GestureDetector(
  onTap: () {
    setState(() => _agreeToTerms = !_agreeToTerms);
  },
  child: Container(
    // Checkbox UI with visual feedback
  ),
)
```

#### 2. Continue Button
- **Enabled State**: When `_agreeToTerms == true`
- **Disabled State**: When `_agreeToTerms == false`
- **Loading State**: Shows spinner while saving

#### 3. Content Sections
Each section is built with `_buildSection()` method:
- Title
- Content in a styled container
- Proper spacing and typography

## User Experience Flow

### Step 1: View Terms
User sees the Terms & Conditions screen with:
- Header with icon
- Scrollable content with all terms
- Unchecked agreement checkbox
- Disabled "Continue" button

### Step 2: Read & Agree
User scrolls through content and checks the agreement box:
- Checkbox becomes checked
- "Continue" button becomes enabled
- Visual feedback (color change, checkmark)

### Step 3: Proceed
User clicks "Continue":
- Loading spinner appears
- Agreement saved to Firestore
- Navigates to Basic Info screen
- Success message shown

### Step 4: Go Back (Optional)
User can click "Go Back" to return to phone verification

## Customization

### Modify Terms Content
Edit the `_buildSection()` calls in the `build()` method:

```dart
_buildSection(
  'Your Title',
  '''
Your content here...
  ''',
),
```

### Change Colors
Update the color constants:
- `AppColors.primary` - Primary color
- `AppColors.textPrimary` - Text color
- `Colors.grey[50]` - Background color

### Modify Button Text
Change the button labels in the UI:
```dart
const Text('I Agree & Continue'),
const Text('Go Back'),
```

## Testing

### Test Cases

1. **Cannot Proceed Without Agreement**
   - Load screen
   - Try clicking "Continue" without checking box
   - Verify snackbar appears: "Please agree to the Terms & Conditions to continue"
   - Verify button remains disabled

2. **Agreement Acceptance**
   - Check the agreement box
   - Verify button becomes enabled
   - Click "Continue"
   - Verify navigation to Basic Info screen
   - Check Firestore for saved agreement data

3. **Go Back**
   - Click "Go Back" button
   - Verify navigation back to phone verification

4. **Scroll Content**
   - Scroll through all sections
   - Verify all content is readable
   - Verify no layout issues

### Manual Testing Steps
1. Run the app: `flutter run`
2. Complete phone verification
3. Verify Terms & Conditions screen appears
4. Try clicking Continue without checking box
5. Check the box and verify button enables
6. Click Continue and verify navigation
7. Check Firestore for saved data

## Security & Compliance

### Data Protection
- Agreement acceptance is timestamped
- Stored in user's Firestore document
- Can be audited for compliance
- User can view their acceptance history

### Legal Compliance
- Covers GDPR requirements (privacy policy)
- Includes age verification (18+)
- Addresses data processing
- Includes safety guidelines

### Audit Trail
Each user's agreement is tracked:
- `agreedToTerms`: boolean flag
- `termsAcceptedAt`: timestamp
- Can be used for legal compliance verification

## Future Enhancements

1. **Version Control**
   - Add `termsVersion` field to track which version user agreed to
   - Re-show terms if updated

2. **Detailed Logging**
   - Log when users view each section
   - Track time spent on terms screen

3. **Multi-Language Support**
   - Translate terms to multiple languages
   - Store user's language preference

4. **Dynamic Content**
   - Load terms from backend
   - Update without app release

5. **Analytics**
   - Track agreement rates
   - Monitor drop-off points
   - Analyze user behavior

## Troubleshooting

### Issue: Button not enabling after checking box
**Solution**: Verify `setState()` is being called in checkbox tap handler

### Issue: Navigation not working
**Solution**: Check route is registered in main.dart:
```dart
case '/onboarding/terms':
  return MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen());
```

### Issue: Data not saving to Firestore
**Solution**: Verify Firebase is initialized and user is authenticated

### Issue: Checkbox not showing as checked
**Solution**: Verify `_agreeToTerms` state variable is being updated

## Support

For issues or questions:
- Check the implementation in `terms_and_conditions_screen.dart`
- Review the onboarding flow in `main.dart`
- Check Firestore for saved agreement data
- Review debug logs for error messages

## Files Modified

1. **lib/screens/onboarding/terms_and_conditions_screen.dart** (NEW)
   - Complete Terms & Conditions screen implementation

2. **lib/screens/onboarding/phone_verification_screen.dart** (MODIFIED)
   - Updated navigation to route to terms screen instead of basic info
   - Lines 75 and 163 changed from `/onboarding/basic-info` to `/onboarding/terms`

3. **lib/main.dart** (MODIFIED)
   - Added import for `terms_and_conditions_screen.dart`
   - Added route for `/onboarding/terms`

## Summary

The Terms & Conditions screen is now fully integrated into the onboarding flow. Users must explicitly agree to the terms before proceeding, ensuring legal compliance and user acknowledgment of platform policies.
