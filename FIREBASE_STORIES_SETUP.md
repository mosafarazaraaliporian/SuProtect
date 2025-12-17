# راهنمای تنظیم استوری‌ها در Firebase

## ساختار داده در Firestore

برای استفاده از استوری‌های Firebase، باید یک collection به نام `stories` در Firestore ایجاد کنید.

### ساختار Document:

```json
{
  "title": "Welcome to SuProtect!",
  "message": "Your comprehensive app protection solution...",
  "icon": "celebration",
  "backgroundColor": "#9C88FF",
  "order": 0,
  "active": true,
  "actionLabel": "Join Channel",
  "actionIcon": "telegram",
  "actionUrl": "https://t.me/+N5X_RGNw_FJkM2Q0"
}
```

### فیلدها:

- **title** (string, required): عنوان استوری
- **message** (string, required): متن استوری
- **icon** (string, optional): نام آیکون (مثال: "celebration", "star", "telegram")
- **backgroundColor** (string, optional): رنگ پس‌زمینه به صورت hex (مثال: "#9C88FF")
- **order** (number, required): ترتیب نمایش استوری‌ها
- **active** (boolean, required): آیا استوری فعال است یا نه
- **actionLabel** (string, optional): متن دکمه اکشن
- **actionIcon** (string, optional): آیکون دکمه اکشن
- **actionUrl** (string, optional): URL برای اکشن (برای Telegram و غیره)

### آیکون‌های پشتیبانی شده:

- celebration
- star
- lightbulb
- telegram
- info
- security
- shield
- lock
- check_circle
- warning
- error
- favorite
- thumb_up
- notifications
- settings

### مثال Collection در Firestore:

```
stories/
  ├── story1/
  │   ├── title: "Welcome to SuProtect!"
  │   ├── message: "Your comprehensive app protection solution..."
  │   ├── icon: "celebration"
  │   ├── backgroundColor: "#9C88FF"
  │   ├── order: 0
  │   └── active: true
  ├── story2/
  │   ├── title: "Features"
  │   ├── message: "Discover powerful features..."
  │   ├── icon: "star"
  │   ├── backgroundColor: "#FF9800"
  │   ├── order: 1
  │   └── active: true
  └── story3/
      ├── title: "Join Our Telegram"
      ├── message: "Stay updated with the latest news..."
      ├── icon: "telegram"
      ├── backgroundColor: "#0088cc"
      ├── order: 2
      ├── active: true
      ├── actionLabel: "Join Channel"
      ├── actionIcon: "telegram"
      └── actionUrl: "https://t.me/+N5X_RGNw_FJkM2Q0"
```

## تنظیمات Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /stories/{storyId} {
      // Allow read for all authenticated users
      allow read: if request.auth != null;
      // Allow write only for admins (you can customize this)
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## نکات مهم:

1. استوری‌ها بر اساس فیلد `order` مرتب می‌شوند
2. فقط استوری‌هایی که `active: true` دارند نمایش داده می‌شوند
3. اگر Firebase در دسترس نباشد، استوری‌های پیش‌فرض نمایش داده می‌شوند
4. استوری‌ها به مدت 5 دقیقه cache می‌شوند
5. برای Telegram، اگر `actionUrl` تنظیم شود، به صورت خودکار باز می‌شود

