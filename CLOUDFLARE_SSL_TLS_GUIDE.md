# 🔐 How to Find Your Cloudflare SSL/TLS Mode

## Step-by-Step Guide

### **Step 1: Go to Cloudflare Dashboard**

1. Open your browser and go to: **https://dash.cloudflare.com**
2. Log in with your Cloudflare account
3. You should see your domains listed

```
Example:
┌─────────────────────────────────────┐
│ Cloudflare Dashboard                │
├─────────────────────────────────────┤
│ Your Domains:                       │
│ ✓ shooluv.com                       │
│ ✓ example.com                       │
└─────────────────────────────────────┘
```

---

### **Step 2: Select Your Domain**

Click on the domain where your app is hosted (e.g., **shooluv.com**)

```
After clicking, you'll see:
┌─────────────────────────────────────┐
│ shooluv.com                         │
├─────────────────────────────────────┤
│ Overview                            │
│ Analytics                           │
│ DNS                                 │
│ SSL/TLS ← CLICK HERE                │
│ Firewall                            │
│ Performance                         │
│ Workers                             │
└─────────────────────────────────────┘
```

---

### **Step 3: Click on "SSL/TLS"**

In the left sidebar, click on **SSL/TLS**

```
You'll see:
┌─────────────────────────────────────┐
│ SSL/TLS                             │
├─────────────────────────────────────┤
│ Overview ← CLICK HERE               │
│ Edge Certificates                   │
│ Client Certificates                 │
│ Origin Server                       │
│ Custom Hostnames                    │
└─────────────────────────────────────┘
```

---

### **Step 4: Check the "Overview" Tab**

Click on **Overview** (it's usually already selected)

```
You'll see the SSL/TLS Mode section:

┌─────────────────────────────────────┐
│ SSL/TLS Mode                        │
├─────────────────────────────────────┤
│ ○ Off (not secure)                  │
│ ○ Flexible                          │
│ ◉ Full                              │ ← Current mode
│ ○ Full (Strict)                     │
│ ○ Strict (SSL only)                 │
└─────────────────────────────────────┘
```

---

## 🎯 What Each Mode Means

### **1. Off (not secure)** ❌
- No SSL/TLS encryption
- **Don't use this!**

### **2. Flexible** ⚠️ **PROBLEMATIC FOR FIRESTORE**
```
Your App (HTTPS)
    ↓
Cloudflare (HTTPS)
    ↓
Your Server (HTTP) ← Unencrypted!
    ↓
Firestore (HTTPS)

Problem: Certificate mismatch, Firestore rejects connection
```

### **3. Full** ✅ **GOOD**
```
Your App (HTTPS)
    ↓
Cloudflare (HTTPS)
    ↓
Your Server (HTTPS with self-signed cert)
    ↓
Firestore (HTTPS)

Good: Works, but doesn't validate certificate
```

### **4. Full (Strict)** ✅✅ **BEST FOR FIRESTORE**
```
Your App (HTTPS)
    ↓
Cloudflare (HTTPS)
    ↓
Your Server (HTTPS with valid cert)
    ↓
Firestore (HTTPS)

Best: Validates certificate, most secure
```

### **5. Strict (SSL only)** 🔒 **MOST SECURE**
- Requires valid SSL certificate
- Highest security level

---

## 📸 Visual Guide (Screenshots)

### **Location 1: Cloudflare Dashboard Home**
```
https://dash.cloudflare.com/
│
├─ Your Domains
│  └─ shooluv.com ← Click here
│
└─ (You'll be taken to domain settings)
```

### **Location 2: Domain Settings**
```
https://dash.cloudflare.com/[account-id]/shooluv.com/
│
├─ Left Sidebar
│  ├─ Overview
│  ├─ Analytics
│  ├─ DNS
│  ├─ SSL/TLS ← Click here
│  ├─ Firewall
│  ├─ Performance
│  └─ Workers
│
└─ Main Content Area
   └─ SSL/TLS Settings
```

### **Location 3: SSL/TLS Overview**
```
https://dash.cloudflare.com/[account-id]/shooluv.com/ssl-tls/overview
│
├─ SSL/TLS Mode (Top section)
│  ├─ Off
│  ├─ Flexible
│  ├─ Full ← Current selection (example)
│  ├─ Full (Strict)
│  └─ Strict (SSL only)
│
├─ Edge Certificates
├─ Origin Server
└─ Custom Hostnames
```

---

## ✅ What to Look For

When you open the SSL/TLS Overview page, you'll see:

```
┌────────────────────────────────────────────┐
│ SSL/TLS Mode                               │
├────────────────────────────────────────────┤
│                                            │
│ Choose your SSL/TLS encryption mode:       │
│                                            │
│ ○ Off (not secure)                         │
│ ○ Flexible                                 │
│ ◉ Full                                     │ ← Filled circle = Current
│ ○ Full (Strict)                            │
│ ○ Strict (SSL only)                        │
│                                            │
│ Current Mode: Full                         │
│ Status: Active                             │
│                                            │
└────────────────────────────────────────────┘
```

**The filled circle (◉) shows your current mode!**

---

## 🔍 How to Identify Your Current Mode

### **Method 1: Look for the Filled Circle**
The selected option will have a **filled circle (◉)** instead of an empty circle (○)

### **Method 2: Look for "Current Mode" Text**
Below the options, it usually says: **"Current Mode: [Your Mode]"**

### **Method 3: Look for the Blue Highlight**
The selected option might be highlighted in blue

---

## 🚨 What You Should See

### **If it says "Flexible"** ❌
```
Current Mode: Flexible
Status: Active

⚠️ THIS IS THE PROBLEM!
This is why your leaderboard stopped working!
```

### **If it says "Full"** ✅
```
Current Mode: Full
Status: Active

✅ This should work, but might have issues
```

### **If it says "Full (Strict)"** ✅✅
```
Current Mode: Full (Strict)
Status: Active

✅ This is the best option for Firestore
```

---

## 📋 Quick Checklist

```
□ Go to https://dash.cloudflare.com
□ Click on your domain (shooluv.com)
□ Click "SSL/TLS" in the left sidebar
□ Click "Overview" tab
□ Look at the "SSL/TLS Mode" section
□ Note which option has the filled circle (◉)
□ Write down the current mode
□ Share it with me!
```

---

## 💬 Once You Find It

After you find your SSL/TLS mode, tell me:

**"My Cloudflare SSL/TLS mode is: [Flexible/Full/Full (Strict)]"**

Then I can tell you exactly what to do next! 🎯

---

## 🆘 Can't Find It?

If you can't find the SSL/TLS settings:

1. **Make sure you're logged in** to Cloudflare
2. **Make sure you selected the right domain**
3. **Try this direct link:** 
   ```
   https://dash.cloudflare.com/[your-account-id]/[your-domain]/ssl-tls/overview
   ```
   (Replace [your-account-id] and [your-domain])

4. **If still stuck:** Take a screenshot and share it with me!

---

## 🎯 Why This Matters

Your SSL/TLS mode determines how Firestore connects to your app:

- **Flexible** → ❌ Firestore can't connect properly
- **Full** → ✅ Might work, but not ideal
- **Full (Strict)** → ✅✅ Best for Firestore

This is likely **the root cause** of your leaderboard issue!

---

## 📞 Next Steps

1. Find your SSL/TLS mode using this guide
2. Tell me what it says
3. I'll give you the exact fix!

**Let's get your leaderboard working! 🚀**
