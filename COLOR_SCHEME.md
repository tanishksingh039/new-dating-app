# CampusBound Color Scheme

This document describes the app's color palette and usage guidelines.

## Color Palette

### Primary Colors
- **Magenta Pink** `#A82953` - Primary brand color, used for main CTAs and highlights
- **Warm Peach** `#DA8568` - Secondary color, used for accents and gradients
- **Soft Warm Pink** `#BD585A` - Tertiary color, used for error states and pass actions
- **Deep Purple-Pink** `#7E1555` - Dark accent, used for super like actions
- **Shadowy Purple** `#4F2A51` - Darker shade, used for premium features
- **Muted Mauve** `#85474D` - Subtle accent for subtle UI elements

## Usage

### Gradients
- **Primary Gradient**: Magenta Pink → Soft Warm Pink → Warm Peach (Login screen, splash)
- **Dark Gradient**: Deep Purple-Pink → Shadowy Purple → Muted Mauve (Premium features)
- **Accent Gradient**: Warm Peach → Soft Warm Pink (Highlights)

### Action Buttons
- **Like**: Magenta Pink `#A82953`
- **Pass**: Soft Warm Pink `#BD585A`
- **Super Like**: Deep Purple-Pink `#7E1555`
- **Rewind**: Warm Peach `#DA8568`
- **Boost**: Shadowy Purple `#4F2A51`

### UI Elements
- **App Bar**: White background, Dark text
- **Bottom Nav**: White background, Magenta Pink selected
- **Cards**: White background with subtle shadow
- **Background**: Light gray `#F5F7FA`
- **Text Primary**: Dark gray `#2D3142`
- **Text Secondary**: Medium gray `#666666`

## Implementation

All colors are defined in `lib/constants/app_colors.dart` and used throughout the app via:

```dart
import 'package:auth_demo/constants/app_colors.dart';

// Usage
Container(color: AppColors.primary)
```

## Updated Components
- ✅ Main Theme (Material 3)
- ✅ Login Screen
- ✅ Discovery Screen
- ✅ Filter Dialog
- ✅ Action Buttons
- ✅ Bottom Navigation
- ✅ App Logo Widget

## Notes
- All colors maintain WCAG AA accessibility standards
- Gradients create visual depth and modern feel
- Colors work well together as they share similar warm/cool undertones
