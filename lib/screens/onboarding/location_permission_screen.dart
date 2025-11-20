import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../../firebase_services.dart';
import '../../constants/app_colors.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;
  bool _locationGranted = false;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LocationPermissionScreen] $message');
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Please enable location services', Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission is required to find matches nearby', Colors.red);
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Please enable location permission in settings', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save location to Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseServices.saveOnboardingStep(
          userId: user.uid,
          stepData: {
            'location': {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': DateTime.now().toIso8601String(),
            },
            'locationEnabled': true,
            'profileComplete': 75, // 75% complete
            'onboardingStep': 'location_completed',
          },
        );
      }

      setState(() {
        _locationGranted = true;
        _isLoading = false;
      });

      _log('Location permission granted and saved');
      
      // Auto-continue after a short delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/notifications');
      }
    } catch (e) {
      _log('Error requesting location permission: $e');
      _showSnackBar('Failed to get location. Please try again.', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _skipLocation() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseServices.saveOnboardingStep(
          userId: user.uid,
          stepData: {
            'locationEnabled': false,
            'profileComplete': 70, // 70% complete (slightly less for skipping)
            'onboardingStep': 'location_skipped',
          },
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/notifications');
      }
    } catch (e) {
      _log('Error skipping location: $e');
      _showSnackBar('Failed to continue. Please try again.', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Location Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          _locationGranted ? Icons.location_on : Icons.location_on_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        _locationGranted ? 'Location enabled!' : 'Enable location',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        _locationGranted 
                          ? 'Great! Now we can show you people nearby'
                          : 'We\'ll show you people near you and hide your distance from others',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Benefits
                      if (!_locationGranted) ...[
                        _buildBenefit(
                          icon: '📍',
                          title: 'Find matches nearby',
                          description: 'See people in your area',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefit(
                          icon: '🔒',
                          title: 'Your privacy is protected',
                          description: 'We never share your exact location',
                        ),
                        const SizedBox(height: 16),
                        _buildBenefit(
                          icon: '⚡',
                          title: 'Better matches',
                          description: 'Distance-based recommendations',
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (!_locationGranted) ...[
                      CustomButton(
                        text: 'Allow Location',
                        onPressed: _isLoading ? null : _requestLocationPermission,
                        isLoading: _isLoading,
                        backgroundColor: Colors.white,
                        textColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _skipLocation,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ] else ...[
                      CustomButton(
                        text: 'Continue',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/onboarding/notifications');
                        },
                        backgroundColor: Colors.white,
                        textColor: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.7, // 70% - Step 7 of 10
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '7/10',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit({
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
