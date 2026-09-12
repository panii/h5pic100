# H5Pic100

## View image actual size

H5Pic100 is a lightweight Android image viewer focused on inspecting images at their actual pixel size. It uses an HTML5 Canvas inside an Android WebView.

In the default mode, the viewer does not enlarge the image. The status bar reports the original image dimensions, display scale, and device pixel ratio so you can compare the source pixels with the physical display.

## Features

- Open local images with the system image picker.
- Render images with Canvas image smoothing enabled for high-quality scaling.
- Default mode for viewing image pixels without artificial enlargement.
- Double-tap to switch to Fit to Screen mode.
- Center the image in both default and fit modes.
- Show dimensions, scale percentage, DPR, and the current viewing mode.
- White viewing background for clear black image borders.

## Display modes

- **Actual Size**: preserves the source image dimensions in the status information and avoids enlarging the image for viewing.
- **Fit to Screen**: scales the image to use the available screen area. The status information shows the Canvas output dimensions and enlargement ratio.

## Changelog

- **2026-09-11** — Added in-app WebView navigation with a native close button for the H5 project. This lets H5 projects run at 120 FPS, since the phone's default Chrome caps the frame rate to save power.

## Build

The project is built with the Android SDK command-line tools (no Gradle wrapper). The generated APK is `app/build/H5Pic100.apk`.

Prerequisites:

- JDK 8 or newer
- Android SDK Build Tools 36.0.0
- Android SDK Platform 37 (`android.jar`)
- A signing keystore (`app/build/debug.keystore`; alias `androiddebugkey`, password `android`)

Quick build: double-click `build.bat` in the repository root. It locates the JDK and Android SDK automatically (via `JAVA_HOME` / `ANDROID_HOME`), picks the newest installed build-tools and platform, generates the debug keystore if missing, and writes the signed APK to `app/build/H5Pic100.apk`.

Manual build (equivalent steps):

Run these commands from the repository root (Git Bash on Windows; adjust the SDK paths if needed):

```bash
BT=/e/Android/sdk/build-tools/36.0.0
AJ=/e/Android/sdk/platforms/android-37.0/android.jar
SRC=app/src/main
B=app/build

mkdir -p $B/compiled $B/gen $B/classes $B/dex $B/linked $B/unsigned

# 1. Compile resources and link them into an APK (also generates R.java)
$BT/aapt2 compile --dir $SRC/res -o $B/compiled/res.zip
$BT/aapt2 link -o $B/linked/base.apk \
  -I $AJ \
  --manifest $SRC/AndroidManifest.xml \
  -A $SRC/assets \
  --java $B/gen \
  $B/compiled/res.zip \
  --auto-add-overlay

# 2. Compile Java sources
javac -source 1.8 -target 1.8 -classpath "$AJ" -d $B/classes \
  $B/gen/com/h5pic100/R.java \
  $SRC/java/com/h5pic100/MainActivity.java

# 3. Convert class files to a Dalvik dex
java -cp "$BT/lib/d8.jar" com.android.tools.r8.D8 \
  --release --lib "$AJ" \
  --output $B/dex \
  $B/classes/com/h5pic100/*.class

# 4. Add classes.dex to the APK
cp $B/linked/base.apk $B/unsigned/app-unsigned.apk
(cd $B/dex && jar uf ../unsigned/app-unsigned.apk classes.dex)

# 5. Zip-align the APK
$BT/zipalign -f 4 $B/unsigned/app-unsigned.apk $B/unsigned/app-aligned.apk

# 6. Sign the APK
java -jar "$BT/lib/apksigner.jar" sign \
  --ks $B/debug.keystore \
  --ks-pass pass:android \
  --ks-key-alias androiddebugkey \
  --out $B/H5Pic100.apk \
  $B/unsigned/app-aligned.apk
```

The final signed APK is written to `app/build/H5Pic100.apk`.

## Install

```powershell
adb install -r app\build\H5Pic100.apk
```

For a clean reinstall:

```powershell
adb uninstall com.h5pic100
adb install app\build\H5Pic100.apk
```

## Source

- Web UI: `app/src/main/assets/index.html`
- Android WebView host: `app/src/main/java/com/h5pic100/MainActivity.java`
