import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPaymentsTab extends StatefulWidget {
  const AdminPaymentsTab({Key? key}) : super(key: key);

  @override
  State<AdminPaymentsTab> createState() {
    print('═══════════════════════════════════════');
    print('[AdminPaymentsTab] 🏗️ CREATE STATE CALLED');
    print('[AdminPaymentsTab] Creating _AdminPaymentsTabState');
    print('═══════════════════════════════════════');
    return _AdminPaymentsTabState();
  }
}

class _AdminPaymentsTabState extends State<AdminPaymentsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _totalRevenue = 0;
  int _totalPayments = 0;
  int _successfulPayments = 0;
  int _spotlightPayments = 0;
  int _premiumPayments = 0;
  
  // Filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFilter = 'all'; // all, today, week, month, custom
  
  // Filtered data
  int _filteredRevenue = 0;
  int _filteredPayments = 0;
  int _filteredSuccessful = 0;
  int _filteredSpotlight = 0;
  int _filteredPremium = 0;
  
  // Growth analysis
  double _growthPercentage = 0.0;
  int _previousPeriodRevenue = 0;
  
  // Store last snapshot for re-processing
  QuerySnapshot? _lastSnapshot;

  @override
  void initState() {
    super.initState();
    print('═══════════════════════════════════════');
    print('[AdminPaymentsTab] 🚀 INIT STATE CALLED');
    print('[AdminPaymentsTab] Widget initialized');
    print('[AdminPaymentsTab] Setting up listeners...');
    print('═══════════════════════════════════════');
    _setupRealTimeListeners();
  }

  void _setupRealTimeListeners() {
    print('═══════════════════════════════════════');
    print('[AdminPaymentsTab] 🔄 Setting up payment listeners...');
    print('[AdminPaymentsTab] 📊 Listening to: payment_orders collection');
    print('[AdminPaymentsTab] Current Filter: $_selectedFilter');
    print('[AdminPaymentsTab] Start Date: $_startDate');
    print('[AdminPaymentsTab] End Date: $_endDate');
    print('[AdminPaymentsTab] Firestore instance: $_firestore');
    print('═══════════════════════════════════════');
    
    _firestore.collection('payment_orders').snapshots().listen(
      (snapshot) {
        print('═══════════════════════════════════════');
        print('[AdminPaymentsTab] 🔔 LISTENER FIRED!');
        print('[AdminPaymentsTab] Mounted: $mounted');
        print('[AdminPaymentsTab] Snapshot docs: ${snapshot.docs.length}');
        print('═══════════════════════════════════════');
        
        if (!mounted) {
          print('[AdminPaymentsTab] ⚠️ Widget not mounted, skipping processing');
          return;
        }
        
        // Store snapshot for re-processing when filter changes
        _lastSnapshot = snapshot;
        print('[AdminPaymentsTab] ✅ Snapshot stored in _lastSnapshot');
        print('[AdminPaymentsTab] _lastSnapshot is null: ${_lastSnapshot == null}');

        print('═══════════════════════════════════════');
        print('[AdminPaymentsTab] ✅ Received ${snapshot.docs.length} payments from Firestore');
        print('[AdminPaymentsTab] Filter Active: $_selectedFilter');
        print('[AdminPaymentsTab] Calling _processPaymentData()...');
        print('═══════════════════════════════════════');
        
        // Process the payment data
        _processPaymentData(snapshot);
      },
      onError: (error) {
        print('═══════════════════════════════════════');
        print('[AdminPaymentsTab] ❌ ERROR listening to payments:');
        print('[AdminPaymentsTab] Error: $error');
        print('[AdminPaymentsTab] Error type: ${error.runtimeType}');
        print('═══════════════════════════════════════');
      },
    );
    
    print('[AdminPaymentsTab] ✅ Listener setup complete');
  }
  
  void _processPaymentData(QuerySnapshot snapshot) {
    if (!mounted) return;
    
    int revenue = 0;
        int total = 0;
        int successful = 0;
        int spotlight = 0;
        int premium = 0;
        
        // Filtered data
        int filteredRevenue = 0;
        int filteredTotal = 0;
        int filteredSuccessful = 0;
        int filteredSpotlight = 0;
        int filteredPremium = 0;
        int previousPeriodRevenue = 0;
        
        print('═══════════════════════════════════════');
        print('[AdminPaymentsTab] 🔄 STARTING DATA PROCESSING');
        print('[AdminPaymentsTab] Total documents to process: ${snapshot.docs.length}');
        print('[AdminPaymentsTab] Active filter: $_selectedFilter');
        print('[AdminPaymentsTab] Filter start date: $_startDate');
        print('[AdminPaymentsTab] Filter end date: $_endDate');
        print('═══════════════════════════════════════');

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final status = (data['status'] ?? '').toString().toLowerCase();
            final amount = data['amount'];
            
            print('[AdminPaymentsTab] 📋 Payment Doc:');
            print('[AdminPaymentsTab]   Status: $status');
            print('[AdminPaymentsTab]   Amount: $amount (type: ${amount.runtimeType})');
            print('[AdminPaymentsTab]   CreatedAt: $createdAt');
            print('[AdminPaymentsTab]   Keys: ${data.keys.toList()}');
            
            total++;

            // Check for successful payment - support multiple status values
            if (status == 'success' || status == 'completed' || status == 'captured' || data['verified'] == true) {
              successful++;
              
              // Extract amount - handle different formats
              int amountInPaise = 0;
              print('[AdminPaymentsTab] 🔍 AMOUNT EXTRACTION:');
              print('[AdminPaymentsTab]   Raw amount: $amount');
              print('[AdminPaymentsTab]   Type: ${amount.runtimeType}');
              
              if (amount is int) {
                amountInPaise = amount;
                print('[AdminPaymentsTab]   Detected as int: $amountInPaise');
              } else if (amount is double) {
                amountInPaise = (amount * 100).toInt();
                print('[AdminPaymentsTab]   Detected as double: $amount → $amountInPaise paise');
              } else if (amount is String) {
                amountInPaise = int.tryParse(amount) ?? 0;
                print('[AdminPaymentsTab]   Detected as String: $amount → $amountInPaise paise');
              } else {
                amountInPaise = (amount as num?)?.toInt() ?? 0;
                print('[AdminPaymentsTab]   Detected as num: $amount → $amountInPaise paise');
              }
              
              print('[AdminPaymentsTab] 🔄 CONVERSION CHECK:');
              print('[AdminPaymentsTab]   amountInPaise: $amountInPaise');
              print('[AdminPaymentsTab]   Is >= 100? ${amountInPaise >= 100}');
              
              // Convert paise to rupees
              // If amount is less than 100, it's likely already in rupees
              final amountInRupees = amountInPaise >= 100 
                ? (amountInPaise / 100).round()  // Convert from paise to rupees
                : amountInPaise;  // Already in rupees
              
              print('[AdminPaymentsTab] ✅ FINAL AMOUNT:');
              print('[AdminPaymentsTab]   Amount in rupees: ₹$amountInRupees');
              print('[AdminPaymentsTab]   Old revenue: ₹$revenue');
              revenue += amountInRupees;
              print('[AdminPaymentsTab]   New revenue: ₹$revenue');
              print('[AdminPaymentsTab]   Added ₹$amountInRupees to revenue (total: ₹$revenue)');

              // Extract payment type - check multiple field names
              final type = (data['type'] ?? data['paymentType'] ?? data['productType'] ?? data['description'] ?? '').toString().toLowerCase();
              
              print('[AdminPaymentsTab] 📦 Payment Type: $type');
              
              if (type.contains('spotlight')) {
                spotlight++;
              } else if (type.contains('premium')) {
                premium++;
              }
              
              // Apply date filter with detailed logging
              print('[AdminPaymentsTab] 🔎 Checking date filter for payment:');
              print('[AdminPaymentsTab]   CreatedAt: $createdAt');
              print('[AdminPaymentsTab]   CreatedAt Type: ${createdAt.runtimeType}');
              print('[AdminPaymentsTab]   Filter: $_selectedFilter');
              print('[AdminPaymentsTab]   Amount: ₹$amountInRupees');
              print('[AdminPaymentsTab]   Current filter state:');
              print('[AdminPaymentsTab]     - _selectedFilter: $_selectedFilter');
              print('[AdminPaymentsTab]     - _startDate: $_startDate');
              print('[AdminPaymentsTab]     - _endDate: $_endDate');
              
              final isInRange = _isDateInRange(createdAt);
              print('[AdminPaymentsTab]   isInRange result: $isInRange');
              print('[AdminPaymentsTab]   Calling _isDateInRange() with:');
              print('[AdminPaymentsTab]     - date: $createdAt');
              print('[AdminPaymentsTab]     - filter: $_selectedFilter');
              
              if (isInRange) {
                filteredTotal++;
                filteredSuccessful++;
                final oldFiltered = filteredRevenue;
                filteredRevenue += amountInRupees;
                
                print('[AdminPaymentsTab] ✅ Payment IN RANGE: ₹$amountInRupees');
                print('[AdminPaymentsTab]   Old filtered total: ₹$oldFiltered');
                print('[AdminPaymentsTab]   New filtered total: ₹$filteredRevenue');
                print('[AdminPaymentsTab]   Calculation: $oldFiltered + $amountInRupees = $filteredRevenue');
                
                if (type.contains('spotlight')) {
                  filteredSpotlight++;
                } else if (type.contains('premium')) {
                  filteredPremium++;
                }
              } else {
                final isPrevious = _isPreviousPeriod(createdAt);
                print('[AdminPaymentsTab]   isPreviousPeriod result: $isPrevious');
                
                if (isPrevious) {
                  final oldPrevious = previousPeriodRevenue;
                  previousPeriodRevenue += amountInRupees;
                  print('[AdminPaymentsTab] 📊 Payment in PREVIOUS PERIOD: ₹$amountInRupees');
                  print('[AdminPaymentsTab]   Old previous total: ₹$oldPrevious');
                  print('[AdminPaymentsTab]   New previous total: ₹$previousPeriodRevenue');
                } else {
                  print('[AdminPaymentsTab] ⏭️ Payment OUT OF RANGE: ₹$amountInRupees');
                  print('[AdminPaymentsTab]   Not in current period and not in previous period');
                }
              }
            } else {
              print('[AdminPaymentsTab] ⚠️ Payment not successful - Status: $status');
            }
          } catch (e, stackTrace) {
            print('[AdminPaymentsTab] ❌ Error processing payment: $e');
            print('[AdminPaymentsTab] Stack trace: $stackTrace');
          }
        }

        // Calculate growth percentage
        double growth = 0.0;
        if (previousPeriodRevenue > 0) {
          growth = ((filteredRevenue - previousPeriodRevenue) / previousPeriodRevenue * 100);
        }
        
        print('═══════════════════════════════════════');
        print('[AdminPaymentsTab] 📊 FILTER SUMMARY');
        print('[AdminPaymentsTab] Filter Type: $_selectedFilter');
        print('[AdminPaymentsTab] Total Payments: $total');
        print('[AdminPaymentsTab] Successful: $successful');
        print('[AdminPaymentsTab] Total Revenue: ₹$revenue');
        print('[AdminPaymentsTab] ───────────────────────────────────────');
        print('[AdminPaymentsTab] Filtered Payments: $filteredTotal');
        print('[AdminPaymentsTab] Filtered Successful: $filteredSuccessful');
        print('[AdminPaymentsTab] Filtered Revenue: ₹$filteredRevenue');
        print('[AdminPaymentsTab] Previous Period Revenue: ₹$previousPeriodRevenue');
        print('[AdminPaymentsTab] Growth: ${growth.toStringAsFixed(1)}%');
        print('[AdminPaymentsTab] ───────────────────────────────────────');
        print('[AdminPaymentsTab] Spotlight: $filteredSpotlight');
        print('[AdminPaymentsTab] Premium: $filteredPremium');
        print('═══════════════════════════════════════');
        
        // Log the state that will be set
        print('═══════════════════════════════════════');
        print('[AdminPaymentsTab] 🔄 ABOUT TO UPDATE STATE');
        print('[AdminPaymentsTab] Current State Values:');
        print('[AdminPaymentsTab]   _totalRevenue: $_totalRevenue');
        print('[AdminPaymentsTab]   _filteredRevenue: $_filteredRevenue');
        print('[AdminPaymentsTab]   _selectedFilter: $_selectedFilter');
        print('[AdminPaymentsTab]   _growthPercentage: $_growthPercentage');
        print('[AdminPaymentsTab] New Values to Set:');
        print('[AdminPaymentsTab]   _totalRevenue: $revenue');
        print('[AdminPaymentsTab]   _filteredRevenue: $filteredRevenue');
        print('[AdminPaymentsTab]   _selectedFilter: $_selectedFilter');
        print('[AdminPaymentsTab]   _growthPercentage: $growth');
        print('[AdminPaymentsTab] Will Change:');
        print('[AdminPaymentsTab]   Revenue: $_totalRevenue → $revenue');
        print('[AdminPaymentsTab]   Filtered: $_filteredRevenue → $filteredRevenue');
        print('[AdminPaymentsTab]   Growth: $_growthPercentage → $growth');
        print('═══════════════════════════════════════');

        // If no premium payments found, count premium users from users collection
        if (premium == 0) {
          print('[AdminPaymentsTab] ℹ️ No premium payments found, counting premium users...');
          _firestore.collection('users').snapshots().listen((userSnapshot) {
            int premiumUserCount = 0;
            for (var doc in userSnapshot.docs) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                if (data['isPremium'] == true) {
                  premiumUserCount++;
                }
              } catch (e) {
                print('[AdminPaymentsTab] ⚠️ Error checking user: $e');
              }
            }
            
            print('[AdminPaymentsTab] 👑 Found $premiumUserCount premium users');
            
            setState(() {
              _totalRevenue = revenue;
              _totalPayments = total;
              _successfulPayments = successful;
              _spotlightPayments = spotlight;
              _premiumPayments = premiumUserCount;
              _filteredRevenue = filteredRevenue;
              _filteredPayments = filteredTotal;
              _filteredSuccessful = filteredSuccessful;
              _filteredSpotlight = filteredSpotlight;
              _filteredPremium = filteredPremium;
              _growthPercentage = growth;
              _previousPeriodRevenue = previousPeriodRevenue;
            });
            
            print('═══════════════════════════════════════');
            print('[AdminPaymentsTab] ✅ STATE UPDATED SUCCESSFULLY');
            print('[AdminPaymentsTab] State Values After Update:');
            print('[AdminPaymentsTab]   _totalRevenue: $_totalRevenue');
            print('[AdminPaymentsTab]   _filteredRevenue: $_filteredRevenue');
            print('[AdminPaymentsTab]   _selectedFilter: $_selectedFilter');
            print('[AdminPaymentsTab]   _growthPercentage: $_growthPercentage');
            print('[AdminPaymentsTab]   _filteredPayments: $_filteredPayments');
            print('[AdminPaymentsTab]   _filteredSuccessful: $_filteredSuccessful');
            print('[AdminPaymentsTab]   _filteredSpotlight: $_filteredSpotlight');
            print('[AdminPaymentsTab]   _filteredPremium: $_filteredPremium');
            print('[AdminPaymentsTab]   _previousPeriodRevenue: $_previousPeriodRevenue');
            print('═══════════════════════════════════════');
            
            print('═══════════════════════════════════════');
            print('[AdminPaymentsTab] 💰 Total Revenue: ₹$revenue');
            print('[AdminPaymentsTab] 💰 Filtered Revenue: ₹$filteredRevenue');
            print('[AdminPaymentsTab] 📈 Growth: ${growth.toStringAsFixed(1)}%');
            print('═══════════════════════════════════════');
          });
        } else {
          setState(() {
            _totalRevenue = revenue;
            _totalPayments = total;
            _successfulPayments = successful;
            _spotlightPayments = spotlight;
            _premiumPayments = premium;
            _filteredRevenue = filteredRevenue;
            _filteredPayments = filteredTotal;
            _filteredSuccessful = filteredSuccessful;
            _filteredSpotlight = filteredSpotlight;
            _filteredPremium = filteredPremium;
            _growthPercentage = growth;
            _previousPeriodRevenue = previousPeriodRevenue;
          });
          
          print('═══════════════════════════════════════');
          print('[AdminPaymentsTab] ✅ STATE UPDATED SUCCESSFULLY');
          print('[AdminPaymentsTab] State Values After Update:');
          print('[AdminPaymentsTab]   _totalRevenue: $_totalRevenue');
          print('[AdminPaymentsTab]   _filteredRevenue: $_filteredRevenue');
          print('[AdminPaymentsTab]   _selectedFilter: $_selectedFilter');
          print('[AdminPaymentsTab]   _growthPercentage: $_growthPercentage');
          print('[AdminPaymentsTab]   _filteredPayments: $_filteredPayments');
          print('[AdminPaymentsTab]   _filteredSuccessful: $_filteredSuccessful');
          print('[AdminPaymentsTab]   _filteredSpotlight: $_filteredSpotlight');
          print('[AdminPaymentsTab]   _filteredPremium: $_filteredPremium');
          print('[AdminPaymentsTab]   _previousPeriodRevenue: $_previousPeriodRevenue');
          print('═══════════════════════════════════════');
          
          print('═══════════════════════════════════════');
          print('[AdminPaymentsTab] 💰 Total Revenue: ₹$revenue');
          print('[AdminPaymentsTab] 💰 Filtered Revenue: ₹$filteredRevenue');
          print('[AdminPaymentsTab] 📈 Growth: ${growth.toStringAsFixed(1)}%');
          print('═══════════════════════════════════════');
        }
  }
  
  bool _isDateInRange(DateTime? date) {
    if (date == null) {
      print('[AdminPaymentsTab] ⚠️ Date is null, returning false');
      return false;
    }
    
    switch (_selectedFilter) {
      case 'today':
        try {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final dateOnly = DateTime(date.year, date.month, date.day);
          final match = dateOnly == today;
          print('[AdminPaymentsTab] 🔍 Today filter: today=$today, dateOnly=$dateOnly, match=$match');
          return match;
        } catch (e) {
          print('[AdminPaymentsTab] ❌ Error in today filter: $e');
          return false;
        }
      
      case 'week':
        try {
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          final endOfToday = now.add(const Duration(days: 1));
          final isInRange = date.isAfter(weekAgo) && date.isBefore(endOfToday);
          print('[AdminPaymentsTab] 🔍 Week filter: date=$date, weekAgo=$weekAgo, now=$now, inRange=$isInRange');
          
          // Fallback: if not in range, check if it's exactly on boundary
          if (!isInRange && (date.isBefore(weekAgo) || date.isAfter(endOfToday))) {
            print('[AdminPaymentsTab] ℹ️ Week filter fallback: date outside range');
          }
          return isInRange;
        } catch (e) {
          print('[AdminPaymentsTab] ❌ Error in week filter: $e');
          return false;
        }
      
      case 'month':
        try {
          final now = DateTime.now();
          final monthAgo = now.subtract(const Duration(days: 30));
          final endOfToday = now.add(const Duration(days: 1));
          final isInRange = date.isAfter(monthAgo) && date.isBefore(endOfToday);
          print('[AdminPaymentsTab] 🔍 Month filter: date=$date, monthAgo=$monthAgo, now=$now, inRange=$isInRange');
          
          // Fallback: if not in range, check if it's exactly on boundary
          if (!isInRange && (date.isBefore(monthAgo) || date.isAfter(endOfToday))) {
            print('[AdminPaymentsTab] ℹ️ Month filter fallback: date outside range');
          }
          return isInRange;
        } catch (e) {
          print('[AdminPaymentsTab] ❌ Error in month filter: $e');
          return false;
        }
      
      case 'custom':
        try {
          if (_startDate == null || _endDate == null) {
            print('[AdminPaymentsTab] 🔍 Custom filter: No dates set, returning true (fallback)');
            return true;
          }
          final endOfEndDate = _endDate!.add(const Duration(days: 1));
          final isInRange = date.isAfter(_startDate!) && date.isBefore(endOfEndDate);
          print('[AdminPaymentsTab] 🔍 Custom filter: date=$date, start=$_startDate, end=$_endDate, inRange=$isInRange');
          
          // Fallback: check boundary conditions
          if (!isInRange) {
            if (date.isBefore(_startDate!)) {
              print('[AdminPaymentsTab] ℹ️ Custom filter fallback: date before start');
            } else if (date.isAfter(endOfEndDate)) {
              print('[AdminPaymentsTab] ℹ️ Custom filter fallback: date after end');
            }
          }
          return isInRange;
        } catch (e) {
          print('[AdminPaymentsTab] ❌ Error in custom filter: $e');
          return false;
        }
      
      default: // 'all'
        print('[AdminPaymentsTab] 🔍 All filter: returning true');
        return true;
    }
  }
  
  bool _isPreviousPeriod(DateTime? date) {
    if (date == null) return false;
    
    switch (_selectedFilter) {
      case 'today':
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        final dateOnly = DateTime(date.year, date.month, date.day);
        return dateOnly == yesterday;
      
      case 'week':
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        final twoWeeksAgo = now.subtract(const Duration(days: 14));
        return date.isAfter(twoWeeksAgo) && date.isBefore(weekAgo);
      
      case 'month':
        final now = DateTime.now();
        final monthAgo = now.subtract(const Duration(days: 30));
        final twoMonthsAgo = now.subtract(const Duration(days: 60));
        return date.isAfter(twoMonthsAgo) && date.isBefore(monthAgo);
      
      default:
        return false;
    }
  }
  
  void _reprocessData() {
    if (_lastSnapshot == null || !mounted) {
      print('[AdminPaymentsTab] ⚠️ Cannot reprocess - no snapshot or not mounted');
      return;
    }
    
    print('═══════════════════════════════════════');
    print('[AdminPaymentsTab] 🔄 MANUALLY REPROCESSING DATA');
    print('[AdminPaymentsTab] Using filter: $_selectedFilter');
    print('[AdminPaymentsTab] Processing ${_lastSnapshot!.docs.length} documents');
    print('[AdminPaymentsTab] Calling _processPaymentData() with last snapshot...');
    print('═══════════════════════════════════════');
    
    // Re-process the last snapshot with the new filter
    _processPaymentData(_lastSnapshot!);
  }
  
  Future<void> _selectDateRange() async {
    print('═══════════════════════════════════════');
    print('[AdminPaymentsTab] 📅 Opening date range picker');
    print('[AdminPaymentsTab] Current Start Date: $_startDate');
    print('[AdminPaymentsTab] Current End Date: $_endDate');
    print('═══════════════════════════════════════');
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      print('═══════════════════════════════════════');
      print('[AdminPaymentsTab] ✅ Date range selected');
      print('[AdminPaymentsTab] Start Date: ${picked.start}');
      print('[AdminPaymentsTab] End Date: ${picked.end}');
      print('[AdminPaymentsTab] Duration: ${picked.end.difference(picked.start).inDays} days');
      print('═══════════════════════════════════════');
      
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 'custom';
        
        print('[AdminPaymentsTab] 🔄 State updated');
        print('[AdminPaymentsTab] Filter changed to: custom');
        print('[AdminPaymentsTab] Triggering data refresh...');
      });
      
      // Re-process data with new date range
      _reprocessData();
    } else {
      print('[AdminPaymentsTab] ❌ Date range picker cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final successRate = _totalPayments > 0
        ? (_successfulPayments / _totalPayments * 100).toStringAsFixed(1)
        : '0.0';
    
    final filteredSuccessRate = _filteredPayments > 0
        ? (_filteredSuccessful / _filteredPayments * 100).toStringAsFixed(1)
        : '0.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Filter by Date Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterButton('Today', 'today'),
                      const SizedBox(width: 8),
                      _buildFilterButton('This Week', 'week'),
                      const SizedBox(width: 8),
                      _buildFilterButton('This Month', 'month'),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Custom'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedFilter == 'custom'
                              ? Colors.purple
                              : Colors.grey[300],
                          foregroundColor: _selectedFilter == 'custom'
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedFilter == 'custom' && _startDate != null && _endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '📅 ${_startDate!.toString().split(' ')[0]} to ${_endDate!.toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Filtered Revenue Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Filtered Revenue',
                  '₹$_filteredRevenue',
                  'Period earnings',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Growth',
                  '${_growthPercentage.toStringAsFixed(1)}%',
                  'vs previous period',
                  _growthPercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  _growthPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Revenue Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Revenue',
                  '₹$_totalRevenue',
                  'All time earnings',
                  Icons.currency_rupee,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Success Rate',
                  '$successRate%',
                  '$_successfulPayments/$_totalPayments',
                  Icons.check_circle,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment Methods
          const Text(
            'Payment Methods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPaymentMethodRow('SPOTLIGHT', _spotlightPayments),
                const Divider(height: 24),
                _buildPaymentMethodRow('PREMIUM', _premiumPayments),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(String method, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          method,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return ElevatedButton(
      onPressed: () {
        print('═══════════════════════════════════════');
        print('[AdminPaymentsTab] 🔘 Filter button clicked');
        print('[AdminPaymentsTab] Button Label: $label');
        print('[AdminPaymentsTab] Filter Type: $filter');
        print('[AdminPaymentsTab] Previous Filter: $_selectedFilter');
        print('[AdminPaymentsTab] Is Selected: $isSelected');
        print('═══════════════════════════════════════');
        
        setState(() {
          final oldFilter = _selectedFilter;
          _selectedFilter = filter;
          
          print('[AdminPaymentsTab] 🔄 State updating');
          print('[AdminPaymentsTab] Old Filter: $oldFilter');
          print('[AdminPaymentsTab] New Filter: $_selectedFilter');
          print('[AdminPaymentsTab] Filter Changed: ${oldFilter != filter}');
          
          // Log filter-specific info
          switch (filter) {
            case 'today':
              print('[AdminPaymentsTab] 📅 Today filter activated');
              print('[AdminPaymentsTab] Will show: Today\'s transactions');
              break;
            case 'week':
              print('[AdminPaymentsTab] 📅 Week filter activated');
              print('[AdminPaymentsTab] Will show: Last 7 days');
              break;
            case 'month':
              print('[AdminPaymentsTab] 📅 Month filter activated');
              print('[AdminPaymentsTab] Will show: Last 30 days');
              break;
            case 'all':
              print('[AdminPaymentsTab] 📅 All filter activated');
              print('[AdminPaymentsTab] Will show: All transactions');
              break;
            default:
              print('[AdminPaymentsTab] 📅 Unknown filter: $filter');
          }
          
          print('[AdminPaymentsTab] ✅ State updated, rebuilding widget...');
          print('[AdminPaymentsTab] 🔄 Filter changed - manually re-processing last snapshot');
          print('[AdminPaymentsTab] Last snapshot available: ${_lastSnapshot != null}');
        });
        
        // Re-process the last snapshot with new filter
        if (_lastSnapshot != null) {
          print('[AdminPaymentsTab] 🔄 Re-processing ${_lastSnapshot!.docs.length} payments with new filter');
          _reprocessData();
        } else {
          print('[AdminPaymentsTab] ⚠️ No snapshot available to re-process');
        }
        
        print('═══════════════════════════════════════');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: isSelected ? 4 : 0,
      ),
      child: Text(label),
    );
  }
}
