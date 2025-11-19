/// Cloudflare R2 Storage Configuration
/// 
/// Setup Instructions:
/// 1. Go to https://dash.cloudflare.com
/// 2. Navigate to R2 Object Storage
/// 3. Create a bucket named "shooluv-images"
/// 4. Go to "Manage R2 API Tokens" → Create API Token
/// 5. Copy the credentials and paste them below
/// 6. Enable public access for the bucket
/// 7. Get the public URL from bucket settings

class R2Config {
  // ⚠️ IMPORTANT: Replace these with your actual Cloudflare R2 credentials
  
  /// Your Cloudflare Account ID
  /// Find it at: Cloudflare Dashboard → R2 → Overview
  /// Format: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  static const String accountId = 'fdc2de2661f53f7ad8a0520cba0ec2a5';
  
  /// R2 Endpoint
  /// Format: {accountId}.r2.cloudflarestorage.com
  static String get endpoint => '$accountId.r2.cloudflarestorage.com';
  
  /// R2 API Access Key ID
  /// Get from: R2 → Manage R2 API Tokens → Create API Token
  static const String accessKeyId = 'f2966d054b4af6fb7d2cdbf2e16a7fb0b';
  
  /// R2 API Secret Access Key
  /// Get from: R2 → Manage R2 API Tokens → Create API Token
  static const String secretAccessKey = 'c2d109e6022700e9d57aecb3d3191f31cc4e5dc1b64f4f977cbc024994ccd0ce';
  
  /// Bucket Name
  /// Create in: R2 → Create Bucket
  static const String bucketName = 'shooluv-images';
  
  /// Region (always 'auto' for R2)
  static const String region = 'auto';
  
  /// Public URL for accessing images
  /// 
  /// Option A: R2 Public URL (easiest)
  /// 1. Go to your bucket settings
  /// 2. Enable "Public Access"
  /// 3. Copy the public URL (format: https://pub-xxxxx.r2.dev)
  /// 
  /// Option B: Custom Domain (recommended for production)
  /// 1. Go to bucket settings → Custom Domains
  /// 2. Add domain: images.shooluv.com
  /// 3. Add CNAME record in your DNS
  /// 4. Use: https://images.shooluv.com
  static const String publicUrl = 'https://pub-f2e6d84a6b2f497bb491f77fe7090276.r2.dev';
  
  /// Validate configuration
  static bool isConfigured() {
    return accountId != 'YOUR_ACCOUNT_ID' &&
           accessKeyId != 'YOUR_ACCESS_KEY_ID' &&
           secretAccessKey != 'YOUR_SECRET_ACCESS_KEY' &&
           publicUrl != 'https://pub-xxxxx.r2.dev';
  }
  
  /// Get configuration status message
  static String getConfigStatus() {
    if (isConfigured()) {
      return '✅ R2 is configured and ready to use';
    } else {
      return '⚠️ R2 is not configured. Please update lib/config/r2_config.dart with your credentials';
    }
  }
}
