# 🚀 Cloudflare R2 - Quick Reference Card

## 💰 The Bottom Line

**Firebase Storage Cost:** ₹5,410/month  
**Cloudflare R2 Cost:** ₹0/month  
**Savings:** 100% (₹64,920/year)

---

## ⚡ Quick Setup (30 Minutes)

### 1. Create Cloudflare Account
→ https://dash.cloudflare.com  
→ Sign up (FREE)

### 2. Create R2 Bucket
→ Dashboard → R2 → Create Bucket  
→ Name: `shooluv-images`  
→ Location: Automatic

### 3. Enable Public Access
→ Bucket Settings → Public Access → Allow  
→ Copy Public URL: `https://pub-xxxxx.r2.dev`

### 4. Create API Token
→ R2 → Manage R2 API Tokens → Create  
→ Permissions: Read & Write  
→ Copy: Access Key ID, Secret Key

### 5. Get Account ID
→ Look at URL: `dash.cloudflare.com/YOUR_ACCOUNT_ID/r2`  
→ Copy the 32-character ID

### 6. Update Config
→ Edit: `lib/config/r2_config.dart`  
→ Paste your credentials

### 7. Install Dependencies
```bash
flutter pub get
```

### 8. Test
→ Report a user with images  
→ Check console logs  
→ Done! 🎉

---

## 📋 Credentials Checklist

```dart
// lib/config/r2_config.dart

✅ accountId: 'a1b2c3d4...' (32 chars)
✅ accessKeyId: 'abc123...' (from API token)
✅ secretAccessKey: 'xyz789...' (from API token)
✅ bucketName: 'shooluv-images'
✅ publicUrl: 'https://pub-xxxxx.r2.dev'
```

---

## 🔍 How to Know It's Working

### Console Logs:
```
✅ Image compressed: 500KB → 100KB
📊 Upload progress: 100%
✅ Image uploaded successfully
```

### Image URLs:
```
✅ https://pub-xxxxx.r2.dev/reports/...
❌ https://firebasestorage.googleapis.com/...
```

### Cloudflare Dashboard:
→ R2 → Your Bucket → Files appear

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| Bucket not found | Check bucket name: `shooluv-images` |
| Access denied | Verify API token permissions |
| Images not loading | Enable public access on bucket |
| Compression failed | Run `flutter pub get` |

---

## 📊 What's Using R2 Now

✅ **Report evidence images** - DONE  
⚠️ Profile photos - TODO  
⚠️ Onboarding photos - TODO  
⚠️ Chat images - TODO  
⚠️ Verification photos - TODO

---

## 💡 Key Benefits

✅ **FREE downloads** (no bandwidth charges)  
✅ **Auto compression** (500KB → 100KB)  
✅ **Faster loading** (smaller files)  
✅ **10 GB free storage**  
✅ **Global CDN** (fast worldwide)

---

## 📞 Support

**Setup Guide:** `CLOUDFLARE_R2_SETUP.md`  
**Implementation Status:** `R2_IMPLEMENTATION_STATUS.md`  
**Code:** `lib/services/r2_storage_service.dart`  
**Config:** `lib/config/r2_config.dart`

---

## ✅ Next Steps

1. [ ] Set up Cloudflare R2 (30 mins)
2. [ ] Update config file (5 mins)
3. [ ] Run `flutter pub get` (2 mins)
4. [ ] Test report images (5 mins)
5. [ ] Update other screens (optional)

**Total Time:** 42 minutes  
**Total Savings:** ₹64,920/year

🎉 **Let's save some money!**
