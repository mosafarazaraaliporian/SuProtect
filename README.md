# SuProtect

a app for protect your app.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## GitHub Actions - Build and Telegram

این پروژه شامل یک GitHub Actions workflow است که به صورت خودکار برنامه را build می‌کند و APK را در تلگرام ارسال می‌کند.

### تنظیمات Secrets

برای استفاده از این workflow، باید دو Secret در GitHub repository خود تنظیم کنید:

1. **TELEGRAM_BOT_TOKEN**: توکن ربات تلگرام شما
   - برای دریافت توکن، با [@BotFather](https://t.me/BotFather) در تلگرام صحبت کنید
   - دستور `/newbot` را بزنید و مراحل را دنبال کنید
   - توکن دریافتی را کپی کنید

2. **TELEGRAM_CHAT_ID**: شناسه چت یا کانال شما
   - برای دریافت Chat ID، با ربات [@userinfobot](https://t.me/userinfobot) صحبت کنید
   - یا در کانال خود، یک پیام بفرستید و از `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates` استفاده کنید

### نحوه تنظیم Secrets در GitHub

1. به repository خود در GitHub بروید
2. روی **Settings** کلیک کنید
3. در منوی سمت چپ، **Secrets and variables** > **Actions** را انتخاب کنید
4. روی **New repository secret** کلیک کنید
5. نام secret را وارد کنید (مثلاً `TELEGRAM_BOT_TOKEN`)
6. مقدار را وارد کنید و **Add secret** را بزنید
7. همین کار را برای `TELEGRAM_CHAT_ID` تکرار کنید

### فعال‌سازی Workflow

Workflow به صورت خودکار در موارد زیر اجرا می‌شود:
- Push به branch `main`
- Pull Request به branch `main`
- اجرای دستی از طریق **Actions** tab در GitHub

بعد از هر build موفق، APK به تلگرام شما ارسال می‌شود! 🚀
