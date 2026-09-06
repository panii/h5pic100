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

## Build

The project can be built with the Android SDK command-line tools. The generated APK is `app/build/H5Pic100.apk`.

The current build uses Android API 37 and Build Tools 36.0.0.

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
