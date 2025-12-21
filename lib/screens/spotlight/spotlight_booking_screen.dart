import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/spotlight_service.dart';
import '../../services/google_play_billing_service.dart';
import '../../models/spotlight_booking.dart';
import '../../config/spotlight_config.dart';

class SpotlightBookingScreen extends StatefulWidget {
  const SpotlightBookingScreen({Key? key}) : super(key: key);

  @override
  State<SpotlightBookingScreen> createState() => _SpotlightBookingScreenState();
}

class _SpotlightBookingScreenState extends State<SpotlightBookingScreen> {
  final SpotlightService _spotlightService = SpotlightService();
  final GooglePlayBillingService _billingService = GooglePlayBillingService();
  bool _isProcessing = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, SpotlightDateStatus> _dateStatuses = {};
  bool _isLoadingCalendar = true;

  @override
  void initState() {
    super.initState();
    _initializeBilling();
    _loadCalendarData();
    
    // Debug: Print calendar date range
    final now = DateTime.now();
    final lastDay = now.add(Duration(days: SpotlightConfig.maxAdvanceBookingDays));
    print('\n📅 ===== CALENDAR CONFIGURATION =====');
    print('First Day: ${now.day}/${now.month}/${now.year}');
    print('Last Day: ${lastDay.day}/${lastDay.month}/${lastDay.year}');
    print('Max Advance Days: ${SpotlightConfig.maxAdvanceBookingDays}');
    print('====================================\n');
  }

  Future<void> _initializeBilling() async {
    await _billingService.initialize();
    
    _billingService.onPurchaseSuccess = (purchaseId) async {
      if (mounted && _selectedDay != null) {
        setState(() => _isProcessing = true);
        
        try {
          // Create spotlight booking after successful purchase
          await _spotlightService.createSpotlightBooking(
            selectedDate: _selectedDay!,
            purchaseId: purchaseId,
          );
          
          if (mounted) {
            setState(() => _isProcessing = false);
            await _loadCalendarData();
            _showSuccessDialog();
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isProcessing = false);
            _showErrorDialog('Failed to create booking: $e');
          }
        }
      }
    };
    
    _billingService.onPurchaseError = (error) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog(error);
      }
    };
    
    _billingService.onPurchasePending = () {
      if (mounted) {
        setState(() => _isProcessing = true);
      }
    };
  }

  Future<void> _loadCalendarData() async {
    print('\n🔄 ===== LOADING CALENDAR DATA =====');
    setState(() => _isLoadingCalendar = true);

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 3, 0); // Next 3 months
      
      print('📅 Date range: ${startDate.day}/${startDate.month} to ${endDate.day}/${endDate.month}');

      final statuses = await _spotlightService.getDateStatuses(startDate, endDate);
      
      print('✅ Loaded ${statuses.length} booked dates from Firestore');

      final Map<DateTime, SpotlightDateStatus> statusMap = {};
      for (var status in statuses) {
        final dateKey = DateTime(status.date.year, status.date.month, status.date.day);
        statusMap[dateKey] = status;
        print('   📅 ${dateKey.day}/${dateKey.month}/${dateKey.year}: booked=${status.isBooked}, yours=${status.isBookedByCurrentUser}');
      }

      if (mounted) {
        setState(() {
          _dateStatuses = statusMap;
          _isLoadingCalendar = false;
        });
        print('✅ Calendar state updated with ${statusMap.length} entries');
        print('=====================================\n');
      }
    } catch (e, stackTrace) {
      print('\n❌ Error loading calendar: $e');
      print('Stack trace: $stackTrace');
      print('=====================================\n');
      
      if (mounted) {
        setState(() => _isLoadingCalendar = false);
        
        // Fallback: Retry after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            print('🔄 Retrying calendar load (fallback)...');
            _loadCalendarData();
          }
        });
      }
    }
  }

  void _handleSpotlightPurchase() async {
    if (_selectedDay == null) return;
    
    if (!_billingService.isAvailable) {
      _showErrorDialog('Google Play Billing is not available');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final success = await _billingService.purchaseSpotlight();
      if (!success && mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog('Failed to start purchase. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _bookSpotlight() async {
    if (_selectedDay == null) {
      _showErrorDialog('Please select a date');
      return;
    }

    // Check if date is in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    if (selected.isBefore(today)) {
      _showErrorDialog('Cannot book past dates');
      return;
    }

    // Check if already booked
    final status = _dateStatuses[selected];
    if (status?.isBooked == true && !status!.isBookedByCurrentUser) {
      _showErrorDialog('This date is already booked');
      return;
    }

    // Call the placeholder handler
    _handleSpotlightPurchase();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Spotlight Booked!'),
          ],
        ),
        content: Text(
          'Your profile will be featured on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Great!',
              style: TextStyle(
                color: Color(0xFFFF6B9D),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Booking Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFFF6B9D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _billingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Spotlight',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingCalendar
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B9D).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 36,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Get Featured!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Appear ${SpotlightConfig.appearancesPerDay}x/day',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    SpotlightConfig.spotlightPriceDisplay,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Calendar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(
                          Duration(days: SpotlightConfig.maxAdvanceBookingDays),
                        ),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        enabledDayPredicate: (day) {
                          // Disable past dates
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final checkDate = DateTime(day.year, day.month, day.day);
                          if (checkDate.isBefore(today)) {
                            print('🚫 Disabled past date: ${checkDate.day}/${checkDate.month}');
                            return false;
                          }
                          
                          // Disable already booked dates (by others)
                          final status = _dateStatuses[checkDate];
                          if (status?.isBooked == true && !status!.isBookedByCurrentUser) {
                            print('🚫 Disabled booked date: ${checkDate.day}/${checkDate.month}');
                            return false;
                          }
                          
                          print('✅ Enabled date: ${checkDate.day}/${checkDate.month}');
                          return true;
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          // Check if date is available before selecting
                          final dateKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                          final status = _dateStatuses[dateKey];
                          
                          if (status?.isBooked == true && !status!.isBookedByCurrentUser) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This date is already booked'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFFFF6B9D),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFFFF6B9D).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          disabledDecoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final dateKey = DateTime(day.year, day.month, day.day);
                            final status = _dateStatuses[dateKey];

                            // Only show special styling if there's a booking
                            if (status != null && status.isBooked) {
                              print('🎨 Rendering ${dateKey.day}/${dateKey.month}: yours=${status.isBookedByCurrentUser}');
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: status.isBookedByCurrentUser
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: status.isBookedByCurrentUser
                                          ? Colors.green.shade700
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                            // Return null for default rendering (white background)
                            return null;
                          },
                          disabledBuilder: (context, day, focusedDay) {
                            final dateKey = DateTime(day.year, day.month, day.day);
                            final status = _dateStatuses[dateKey];
                            
                            // Check if it's disabled because it's booked by someone else
                            if (status != null && status.isBooked && !status.isBookedByCurrentUser) {
                              print('🎨 Rendering DISABLED ${dateKey.day}/${dateKey.month}: booked by others');
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            // Past dates - lighter gray
                            return Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(
                                color: const Color(0xFFFF6B9D),
                                label: 'Selected',
                              ),
                              _buildLegendItem(
                                color: Colors.green.withOpacity(0.5),
                                label: 'Your Booking',
                              ),
                              _buildLegendItem(
                                color: Colors.grey.withOpacity(0.5),
                                label: 'Booked',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                // Sticky Book Button at Bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _bookSpotlight,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B9D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFFFF6B9D).withOpacity(0.3),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Book Spotlight - ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    SpotlightConfig.spotlightPriceDisplay,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
