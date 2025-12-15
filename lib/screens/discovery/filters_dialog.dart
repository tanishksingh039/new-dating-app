import 'package:flutter/material.dart';
import '../../models/discovery_filters.dart';
import '../../constants/app_colors.dart';
import '../../utils/constants.dart';

// Wrapper class to distinguish between "dismissed" and "reset clicked"
class FilterDialogResult {
  final DiscoveryFilters? filters;
  final bool wasReset;
  
  FilterDialogResult({this.filters, this.wasReset = false});
}

class FiltersDialog extends StatefulWidget {
  final DiscoveryFilters currentFilters;

  const FiltersDialog({
    Key? key,
    required this.currentFilters,
  }) : super(key: key);

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<FiltersDialog> {
  late DiscoveryFilters _filters;
  late RangeValues _ageRange;
  double? _maxDistance;
  String? _selectedCourseStream;
  List<String> _selectedInterests = [];

  final List<String> _availableInterests = [
    'Travel',
    'Music',
    'Movies',
    'Food',
    'Fitness',
    'Sports',
    'Reading',
    'Photography',
    'Art',
    'Dancing',
    'Cooking',
    'Gaming',
    'Fashion',
    'Technology',
    'Nature',
    'Pets',
    'Coffee',
    'Wine',
    'Yoga',
    'Beach',
    'Mountains',
    'Shopping',
    'Comedy',
    'Adventure',
    'Cars',
    'Bikes',
    'Writing',
    'Volunteering',
    'Meditation',
    'DIY',
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _ageRange = RangeValues(
      _filters.minAge.toDouble(),
      _filters.maxAge.toDouble(),
    );
    _maxDistance = _filters.maxDistance;
    _selectedCourseStream = _filters.courseStream;
    _selectedInterests = List.from(_filters.interests);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course/Stream
                    _buildSectionTitle('Course/Stream'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCourseStream,
                          hint: const Text('Select Course/Stream'),
                          isExpanded: true,
                          items: AppConstants.courseStreamOptions.map((String course) {
                            return DropdownMenuItem<String>(
                              value: course,
                              child: Text(course),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _selectedCourseStream = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Interests
                    _buildSectionTitle('Interests'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF6B9D).withOpacity(0.3),
                          checkmarkColor: const Color(0xFFFF6B9D),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedInterests.add(interest);
                              } else {
                                _selectedInterests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset means "no filters" - return wrapper with wasReset=true
                      Navigator.pop(context, FilterDialogResult(filters: null, wasReset: true));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final updatedFilters = DiscoveryFilters(
                        minAge: _ageRange.start.round(),
                        maxAge: _ageRange.end.round(),
                        maxDistance: _maxDistance,
                        courseStream: _selectedCourseStream,
                        interests: _selectedInterests,
                      );
                      Navigator.pop(context, FilterDialogResult(filters: updatedFilters, wasReset: false));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
