# Terms & Conditions - Quick Reference

## What Was Added

✅ **Professional Terms & Conditions Screen** integrated into onboarding flow

## Key Features

- **Mandatory Agreement**: Users CANNOT proceed without checking the box
- **Professional UI**: Modern, clean design matching app aesthetic
- **Comprehensive Content**: 4 sections covering all legal requirements
- **Visual Feedback**: Checkbox and button enable/disable based on agreement status
- **Data Persistence**: Agreement saved to Firestore with timestamp

## Onboarding Flow

```
Phone Verification → Terms & Conditions → Basic Info → ...
```

## Screen Components

### 1. Header
- Icon with title
- "Terms & Conditions" heading
- Back button

### 2. Scrollable Content (4 Sections)
- **Terms of Service**: Legal terms and conditions
- **Community Guidelines**: User behavior expectations
- **Privacy Policy**: Data handling and protection
- **Safety & Security**: Safety measures and reporting

### 3. Agreement Section
- **Checkbox**: "I agree to the Terms & Conditions"
- **Continue Button**: Enabled only when checked
- **Go Back Button**: Return to previous screen

## User Experience

| Action | Result |
|--------|--------|
| Load screen | See terms, checkbox unchecked, button disabled |
| Click Continue (unchecked) | Snackbar: "Please agree to continue" |
| Check box | Button becomes enabled, visual feedback |
| Click Continue (checked) | Save agreement, navigate to Basic Info |
| Click Go Back | Return to Phone Verification |

## Files

| File | Status | Changes |
|------|--------|---------|
| `terms_and_conditions_screen.dart` | NEW | Complete screen implementation |
| `phone_verification_screen.dart` | MODIFIED | Updated navigation routes |
| `main.dart` | MODIFIED | Added import and route |

## Database Schema

When user agrees:
```json
{
  "agreedToTerms": true,
  "termsAcceptedAt": "2025-12-04T21:30:00Z",
  "onboardingStep": "terms_accepted"
}
```

## Testing Checklist

- [ ] Cannot proceed without checking box
- [ ] Button enables when box is checked
- [ ] Button disables when box is unchecked
- [ ] Continue button navigates to Basic Info
- [ ] Go Back button returns to Phone Verification
- [ ] Agreement data saves to Firestore
- [ ] All content is readable and scrollable
- [ ] No layout issues on different screen sizes

## Customization

### Change Terms Content
Edit sections in `terms_and_conditions_screen.dart`:
```dart
_buildSection('Title', 'Content here...')
```

### Change Button Text
Update text in the button widgets

### Change Colors
Modify `AppColors.primary` references

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Button not enabling | Check `setState()` in checkbox handler |
| Navigation failing | Verify route in main.dart |
| Data not saving | Check Firebase initialization |
| Checkbox not showing | Verify `_agreeToTerms` state |

## Next Steps

1. Test the flow end-to-end
2. Customize terms content as needed
3. Monitor agreement rates in analytics
4. Consider version control for future updates
5. Add multi-language support if needed

## Support

- Full implementation in `terms_and_conditions_screen.dart`
- Comprehensive guide in `TERMS_AND_CONDITIONS_GUIDE.md`
- Check debug logs for any errors
- Verify Firestore data is being saved
