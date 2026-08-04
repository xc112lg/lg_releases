sed -i '/ro.hardware.egl=adreno \\/a\    ro.surface_flinger.supports_background_blur=1 \\' device/lge/msm8996-common/vendor_prop.mk
#cat device/lge/msm8996-common/vendor_prop.mk
KERNEL_DIR="kernel/lge/msm8996"
if ! grep -q "stendro_+_AShiningRay_+_continued_by_xc112lg" "$KERNEL_DIR/scripts/mkcompile_h"; then
  sed -i \
    -e '/if test -z "\$KBUILD_BUILD_USER"; then/,/^fi$/c\
LINUX_COMPILE_BY="stendro_+_AShiningRay_+_continued_by_xc112lg"' \
    -e '/if test -z "\$KBUILD_BUILD_HOST"; then/,/^fi$/c\
LINUX_COMPILE_HOST="crave.io"' \
    "$KERNEL_DIR/scripts/mkcompile_h"
fi
sed -i \
  -e '/<path name="headphones-hifi-dac">/a\        <ctl name="Es9218 Bypass" value="0" />' \
  -e '/<path name="headphones-hifi-dac-advanced">/a\        <ctl name="Es9218 Bypass" value="0" />' \
  -e '/<path name="headphones-hifi-dac-aux">/a\        <ctl name="Es9218 Bypass" value="0" />' \
  -e '/<path name="headphones-hifi-dacdop">/a\        <ctl name="Es9218 Bypass" value="0" />' \
  -e '/<path name="headphones-hifi-dacdop-advanced">/a\        <ctl name="Es9218 Bypass" value="0" />' \
  -e '/<path name="headphones-hifi-dacdop-aux">/a\        <ctl name="Es9218 Bypass" value="0" />' \
  device/lge/g6-common/audio/mixer_paths_tasha.xml

  sed -i '/<\/resources>/i\
\    <!-- Blur radius behind Notification Shade -->\n    <dimen name="max_shade_window_blur_radius">17dp</dimen>\n' "device/lge/msm8996-common/overlay/frameworks/base/packages/SystemUI/res/values/config.xml"


# Directory structure
mkdir -p device/lge/msm8996-common/rro_overlays/LauncherOverlayMsm8996/res/values

# Android.bp
cat > device/lge/msm8996-common/rro_overlays/LauncherOverlayMsm8996/Android.bp << 'EOF'
runtime_resource_overlay {
    name: "LauncherOverlayMsm8996",
    sdk_version: "current",
    vendor: true,
}
EOF

# AndroidManifest.xml
cat > device/lge/msm8996-common/rro_overlays/LauncherOverlayMsm8996/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<!--
     Copyright (C) 2025 PixelOS
     Copyright (C) 2025 LineageOS
     SPDX-License-Identifier: Apache-2.0
-->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.android.launcher.overlay.msm8996">

    <overlay
        android:isStatic="true"
        android:priority="1"
        android:targetPackage="com.android.launcher3" />
</manifest>
EOF

# res/values/config.xml
cat > device/lge/msm8996-common/rro_overlays/LauncherOverlayMsm8996/res/values/config.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<!-- Copyright (C) 2018 The Android Open Source Project
     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at
        http://www.apache.org/licenses/LICENSE-2.0
     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
-->
<resources>
    <dimen name="max_depth_blur_radius_enhanced">20dp</dimen>
</resources>
EOF

# Register in msm8996.mk
sed -i '/^    WifiOverlay \\$/a\    LauncherOverlayMsm8996 \\' device/lge/msm8996-common/msm8996.mk