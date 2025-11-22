import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStorageTab extends StatefulWidget {
  const AdminStorageTab({Key? key}) : super(key: key);

  @override
  State<AdminStorageTab> createState() => _AdminStorageTabState();
}

class _AdminStorageTabState extends State<AdminStorageTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  double _totalStorage = 0.0;
  int _totalFiles = 0;
  double _userPhotosStorage = 0.0;
  int _userPhotosCount = 0;
  double _chatImagesStorage = 0.0;
  int _chatImagesCount = 0;

  @override
  void initState() {
    super.initState();
    _calculateStorage();
  }

  Future<void> _calculateStorage() async {
    print('═══════════════════════════════════════');
    print('[AdminStorageTab] 🔄 Calculating storage...');
    print('═══════════════════════════════════════');
    
    try {
      // Calculate user photos storage
      print('[AdminStorageTab] 📊 Fetching users...');
      final usersSnapshot = await _firestore.collection('users').get();
      print('[AdminStorageTab] ✅ Got ${usersSnapshot.docs.length} users');
      
      int photoCount = 0;
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final photos = data['photos'] as List<dynamic>? ?? [];
        photoCount += photos.length;
      }
      
      print('[AdminStorageTab] 📸 Total user photos: $photoCount');

      // Estimate storage (assuming average 500KB per photo)
      final photosStorage = photoCount * 0.0005; // GB

      // Calculate chat images (if collection exists)
      int chatImageCount = 0;
      try {
        print('[AdminStorageTab] 💬 Fetching messages...');
        final messagesSnapshot = await _firestore.collection('messages').get();
        print('[AdminStorageTab] ✅ Got ${messagesSnapshot.docs.length} messages');
        
        for (var doc in messagesSnapshot.docs) {
          final data = doc.data();
          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
            chatImageCount++;
          }
        }
        print('[AdminStorageTab] 🖼️ Total chat images: $chatImageCount');
      } catch (e) {
        print('[AdminStorageTab] ⚠️ Messages collection error: $e');
      }

      final chatStorage = chatImageCount * 0.0003; // GB

      if (mounted) {
        setState(() {
          _userPhotosCount = photoCount;
          _userPhotosStorage = photosStorage;
          _chatImagesCount = chatImageCount;
          _chatImagesStorage = chatStorage;
          _totalStorage = photosStorage + chatStorage;
          _totalFiles = photoCount + chatImageCount;
        });
        
        print('═══════════════════════════════════════');
        print('[AdminStorageTab] ✅ Storage calculated:');
        print('[AdminStorageTab] Total: ${_totalStorage.toStringAsFixed(2)} GB');
        print('[AdminStorageTab] Files: $_totalFiles');
        print('═══════════════════════════════════════');
      }
    } catch (e) {
      print('═══════════════════════════════════════');
      print('[AdminStorageTab] ❌ ERROR calculating storage:');
      print('[AdminStorageTab] Error: $e');
      print('═══════════════════════════════════════');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Storage',
                  '${_totalStorage.toStringAsFixed(2)} GB',
                  '$_totalFiles files',
                  Icons.storage,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'User Photos',
                  '${_userPhotosStorage.toStringAsFixed(2)} GB',
                  '$_userPhotosCount files',
                  Icons.photo,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Storage Breakdown
          const Text(
            'Storage Breakdown',
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
                _buildStorageRow(
                  'User Photos',
                  '$_userPhotosCount files',
                  '${_userPhotosStorage.toStringAsFixed(2)} GB',
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildStorageRow(
                  'Chat Images',
                  '$_chatImagesCount files',
                  '${_chatImagesStorage.toStringAsFixed(2)} GB',
                  Colors.green,
                ),
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

  Widget _buildStorageRow(String title, String subtitle, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
