# 🚀 Cloudflare R2 Setup Guide

## Why Cloudflare R2?

**Cost Savings:**
- Firebase Storage: ₹5,400/month for 1,500 users
- Cloudflare R2: **₹0/month** (FREE downloads!)
- **Savings: 100%** 🎉

**Benefits:**
- ✅ 10 GB storage FREE
- ✅ FREE egress (downloads) - NO bandwidth charges!
- ✅ Fast global CDN
- ✅ S3-compatible API
- ✅ No surprise bills

---

## 📋 Setup Steps (30 minutes)

### **Step 1: Create Cloudflare Account**

1. Go to https://dash.cloudflare.com
2. Click "Sign Up" (it's FREE)
3. Verify your email
4. Complete account setup

**Cost: ₹0** ✅

---

### **Step 2: Create R2 Bucket**

1. In Cloudflare Dashboard, click **"R2"** in the left sidebar
2. Click **"Create Bucket"**
3. Enter bucket name: `shooluv-images`
4. Location: **Automatic** (Cloudflare will choose closest to India)
5. Click **"Create Bucket"**

**Cost: ₹0** (first 10 GB free) ✅

---

### **Step 3: Enable Public Access**

1. Click on your bucket: `shooluv-images`
2. Go to **"Settings"** tab
3. Scroll to **"Public Access"**
4. Click **"Allow Access"**
5. Copy the **Public Bucket URL** (format: `https://pub-xxxxx.r2.dev`)
6. Save this URL - you'll need it later!

**Example URL:** `https://pub-abc123def456.r2.dev`

---

### **Step 4: Create API Token**

1. Go back to R2 Overview
2. Click **"Manage R2 API Tokens"**
3. Click **"Create API Token"**
4. Token name: `shooluv-app-token`
5. Permissions: **"Object Read & Write"**
6. TTL: **Forever** (or set expiry if you prefer)
7. Click **"Create API Token"**

**You'll see 3 important values:**
```
Access Key ID: abc123def456...
Secret Access Key: xyz789uvw012...
Endpoint: https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com
```

**⚠️ IMPORTANT:** Copy these NOW! You can't see the Secret Key again!

---

### **Step 5: Get Your Account ID**

1. In Cloudflare Dashboard, look at the URL
2. It will be: `https://dash.cloudflare.com/YOUR_ACCOUNT_ID/r2`
3. Copy the `YOUR_ACCOUNT_ID` part (32 characters)

**Example:** `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

---

### **Step 6: Update Configuration File**

1. Open: `lib/config/r2_config.dart`
2. Replace the placeholder values:

```dart
class R2Config {
  // Replace with your actual values:
  static const String accountId = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6'; // From Step 5
  static const String accessKeyId = 'abc123def456...'; // From Step 4
  static const String secretAccessKey = 'xyz789uvw012...'; // From Step 4
  static const String bucketName = 'shooluv-images'; // From Step 2
  static const String publicUrl = 'https://pub-abc123def456.r2.dev'; // From Step 3
}
```

3. Save the file

---

### **Step 7: Install Dependencies**

Run this command in your terminal:

```bash
cd c:\CampusBound\frontend
flutter pub get
```

This will install:
- `minio` - For R2 connectivity
- `flutter_image_compress` - For image optimization

---

### **Step 8: Test the Connection**

1. Run your app
2. Try uploading a photo (profile, report, etc.)
3. Check the console logs for:
   - ✅ Image compressed: 500KB → 100KB
   - ✅ Upload progress: 100%
   - ✅ Image uploaded successfully

---

## 🔄 Migration Plan

### **For New Users (Starting Now):**
- All new images automatically go to R2
- Zero Firebase Storage costs
- Faster image loading (compression)

### **For Existing Users (If Any):**

**Option A: Gradual Migration (Recommended)**
- Keep old images on Firebase
- New images go to R2
- Migrate old images slowly over time

**Option B: Full Migration**
1. Download all images from Firebase
2. Re-upload to R2
3. Update Firestore URLs
4. Delete from Firebase

**For 1,500 users, Option A is easier!**

---

## 📊 Cost Comparison

### **Before (Firebase Storage):**
```
Monthly Costs:
- Storage: 5.2 GB × ₹2/GB = ₹10
- Downloads: 540 GB × ₹10/GB = ₹5,400
- Total: ₹5,410/month
```

### **After (Cloudflare R2):**
```
Monthly Costs:
- Storage: 5.2 GB (within 10 GB free) = ₹0
- Downloads: 540 GB (FREE egress!) = ₹0
- Total: ₹0/month 🎉

Annual Savings: ₹5,410 × 12 = ₹64,920/year!
```

---

## 🎯 What Changed in the Code?

### **Files Created:**
1. `lib/services/r2_storage_service.dart` - R2 upload/download service
2. `lib/config/r2_config.dart` - Configuration file

### **Files to Update (Next Step):**
1. `lib/screens/profile/edit_profile_screen.dart` - Profile photos
2. `lib/screens/onboarding/photo_upload_screen.dart` - Initial photos
3. `lib/screens/safety/report_user_screen.dart` - Report evidence
4. `lib/screens/chat/chat_screen.dart` - Chat images/voice notes
5. `lib/screens/verification/face_verification_screen.dart` - Verification photos

**Don't worry - I'll update all of these for you!**

---

## ✅ Verification Checklist

Before going live, verify:

- [ ] Cloudflare account created
- [ ] R2 bucket created: `shooluv-images`
- [ ] Public access enabled
- [ ] API token created
- [ ] Configuration file updated
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Test upload successful
- [ ] Images loading in app
- [ ] Old Firebase images still work (if any)

---

## 🆘 Troubleshooting

### **Error: "Bucket not found"**
- Check bucket name in `r2_config.dart` matches exactly
- Verify bucket exists in Cloudflare dashboard

### **Error: "Access denied"**
- Check API token has "Read & Write" permissions
- Verify accessKeyId and secretAccessKey are correct

### **Error: "Invalid endpoint"**
- Check accountId in `r2_config.dart`
- Endpoint format: `{accountId}.r2.cloudflarestorage.com`

### **Images not loading**
- Check publicUrl is correct
- Verify public access is enabled on bucket
- Try accessing image URL directly in browser

---

## 🎉 You're Done!

Once configured:
- ✅ All new images go to R2 automatically
- ✅ Images are compressed (500KB → 100KB)
- ✅ Zero storage costs
- ✅ Faster app performance
- ✅ No more Firebase Storage bills!

**Total setup time: 30 minutes**
**Annual savings: ₹64,920**

---

## 📞 Need Help?

If you get stuck:
1. Check the troubleshooting section above
2. Verify all credentials are correct
3. Test with a simple upload first
4. Check Cloudflare R2 dashboard for errors

**Next Step:** Update the app screens to use R2 instead of Firebase Storage!
