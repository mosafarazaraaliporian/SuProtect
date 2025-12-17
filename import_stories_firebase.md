# راهنمای سریع Import استوری‌ها به Firebase

## روش 1: استفاده از Firebase Console (سریع‌تر)

### گام 1: آماده کردن داده‌ها
فایل `firestore_stories_import.json` رو باز کن و استوری‌ها رو ویرایش کن.

### گام 2: Import در Firebase Console
1. برو به Firebase Console → Firestore Database
2. روی منوی سه نقطه (⋮) کنار "stories" collection کلیک کن
3. "Import collection" رو انتخاب کن
4. فایل `firestore_stories_import.json` رو انتخاب کن
5. Import رو بزن

**تمام! همه استوری‌ها یکجا اضافه میشن** ✅

---

## روش 2: استفاده از Firebase CLI (حرفه‌ای)

### نصب Firebase CLI:
```bash
npm install -g firebase-tools
```

### Login:
```bash
firebase login
```

### Import:
```bash
firebase firestore:import firestore_stories_import.json --project YOUR_PROJECT_ID
```

---

## روش 3: Copy-Paste در Firebase Console (خیلی سریع)

1. برو به Firebase Console → Firestore
2. Collection `stories` رو بساز
3. Document جدید بساز (Auto ID)
4. این فیلدها رو یکی یکی اضافه کن (کپی-پیست):

### استوری 1:
```
title: Welcome to SuProtect!
message: Your comprehensive app protection solution. Keep your applications secure and safe from various threats.
icon: celebration
backgroundColor: #9C88FF
order: 0
active: true
```

### استوری 2:
```
title: Features
message: Discover powerful features:\n\n• Security Protection\n• Threat Detection\n• Data Encryption\n• Real-time Monitoring
icon: star
backgroundColor: #FF9800
order: 1
active: true
```

### استوری 3:
```
title: Tips
message: Best Practices:\n\n• Keep your app updated\n• Use strong passwords\n• Enable all security features\n• Regular security checks
icon: lightbulb
backgroundColor: #FFC107
order: 2
active: true
```

### استوری 4:
```
title: Join Our Telegram
message: Stay updated with the latest news, updates, and tips!\n\nJoin our Telegram channel for exclusive content and support.
icon: telegram
backgroundColor: #0088cc
order: 3
active: true
actionLabel: Join Channel
actionIcon: telegram
actionUrl: https://t.me/+N5X_RGNw_FJkM2Q0
```

---

## نکته:
بعد از import، حتماً Index رو بساز:
- Field: `active` (Ascending)
- Field: `order` (Ascending)

