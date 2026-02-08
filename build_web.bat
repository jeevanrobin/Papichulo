@echo off
echo Building Papichulo Food Ordering Web App...
echo.

echo Step 1: Getting dependencies...
flutter pub get

echo.
echo Step 2: Building for web...
flutter build web --release

echo.
echo Step 3: Build completed!
echo Your web app is ready in the 'build\web' directory.
echo.
echo To serve locally, run: flutter run -d chrome
echo To deploy, upload the contents of 'build\web' to your web server.
echo.
pause