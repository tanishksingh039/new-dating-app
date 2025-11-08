import 'package:flutter/material.dart';
import '../../models/discovery_filters.dart';
import '../../constants/app_colors.dart';

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
  bool _showVerifiedOnly = false;
  String? _selectedEducation;
  List<String> _selectedInterests = [];

  // Available options
  final List<String> _educationLevels = [
    'High School',
    'Bachelor\'s',
    'Master\'s',
    'PhD',
    'Other',
  ];

  final List<String> _availableInterests = [
    'Sports',
    'Music',
    'Art',
    'Movies',
    'Travel',
    'Food',
    'Reading',
    'Gaming',
    'Fitness',
    'Photography',
    'Technology',
    'Fashion',
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
    _showVerifiedOnly = _filters.showVerifiedOnly;
    _selectedEducation = _filters.education;
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
                    // Age Range
                    _buildSectionTitle('Age Range'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: RangeSlider(
                        values: _ageRange,
                        min: 18,
                        max: 100,
                        divisions: 82,
                        activeColor: const Color(0xFFFF6B9D),
                        labels: RangeLabels(
                          _ageRange.start.round().toString(),
                          _ageRange.end.round().toString(),
                        ),
                        onChanged: (values) {
                          setState(() => _ageRange = values);
                        },
                      ),
                    ),
                    Center(
                      child: Text(
                        '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Distance
                    _buildSectionTitle('Maximum Distance'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Slider(
                            value: _maxDistance ?? 100,
                            min: 1,
                            max: 100,
                            divisions: 99,
                            activeColor: AppColors.primary,
                            label: _maxDistance == null
                                ? 'Any'
                                : '${_maxDistance!.round()} km',
                            onChanged: (value) {
                              setState(() => _maxDistance = value);
                            },
                          ),
                          Center(
                            child: Text(
                              _maxDistance == null
                                  ? 'Any distance'
                                  : '${_maxDistance!.round()} km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _maxDistance = null);
                            },
                            child: const Text('No limit'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verified Only
                    CheckboxListTile(
                      title: const Text('Show verified users only'),
                      subtitle: const Text('Users with verified profiles'),
                      value: _showVerifiedOnly,
                      activeColor: const Color(0xFFFF6B9D),
                      onChanged: (value) {
                        setState(() => _showVerifiedOnly = value ?? false);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Education Level
                    _buildSectionTitle('Education Level'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _educationLevels.map((edu) {
                        final isSelected = _selectedEducation == edu;
                        return FilterChip(
                          label: Text(edu),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF6B9D).withOpacity(0.3),
                          checkmarkColor: const Color(0xFFFF6B9D),
                          onSelected: (selected) {
                            setState(() {
                              _selectedEducation = selected ? edu : null;
                            });
                          },
                        );
                      }).toList(),
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
                      setState(() {
                        _ageRange = const RangeValues(18, 100);
                        _maxDistance = null;
                        _showVerifiedOnly = false;
                        _selectedEducation = null;
                        _selectedInterests.clear();
                      });
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
                        showVerifiedOnly: _showVerifiedOnly,
                        education: _selectedEducation,
                        interests: _selectedInterests,
                      );
                      Navigator.pop(context, updatedFilters);
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
