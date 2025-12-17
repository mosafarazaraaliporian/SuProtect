# راهنمای سریع افزودن استوری در Firebase

## مراحل سریع:

### 1. Firebase Console → Firestore Database

### 2. ساخت Collection:
- Collection ID: `stories`
- Document ID: Auto ID یا دستی

### 3. فیلدهای ضروری برای هر استوری:

| Field Name | Type | مثال Value |
|------------|------|------------|
| `title` | string | "Welcome to SuProtect!" |
| `message` | string | "Your app protection..." |
| `icon` | string | "celebration" |
| `backgroundColor` | string | "#9C88FF" |
| `order` | number | 0 |
| `active` | boolean | true |

### 4. فیلدهای اختیاری (برای دکمه اکشن):

| Field Name | Type | مثال Value |
|------------|------|------------|
| `actionLabel` | string | "Join Channel" |
| `actionIcon` | string | "telegram" |
| `actionUrl` | string | "https://t.me/..." |

## مثال کامل یک استوری:

```
title: "Welcome to SuProtect!"
message: "Your comprehensive app protection solution."
icon: "celebration"
backgroundColor: "#9C88FF"
order: 0
active: true
```

## رنگ‌های پیشنهادی:

- بنفش: `#9C88FF`
- نارنجی: `#FF9800`
- زرد: `#FFC107`
- آبی تلگرام: `#0088cc`
- سبز: `#4CAF50`
- قرمز: `#F44336`

## آیکون‌های موجود:

celebration, star, lightbulb, telegram, info, security, shield, lock, check_circle, warning, error, favorite, thumb_up, notifications, settings

