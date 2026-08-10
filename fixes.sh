
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

mkdir -p device/lge/msm8996-common/sepolicy/vendor-user
if [ ! -f device/lge/msm8996-common/sepolicy/vendor-user/file.te ]; then
    echo 'type sensors_data_file, file_type, data_file_type;' > device/lge/msm8996-common/sepolicy/vendor-user/file.te
fi
grep -q "sepolicy/vendor-user" device/lge/msm8996-common/BoardConfigCommon.mk || cat >> device/lge/msm8996-common/BoardConfigCommon.mk << 'EOF'

ifeq ($(TARGET_BUILD_VARIANT),user)
BOARD_VENDOR_SEPOLICY_DIRS := $(COMMON_PATH)/sepolicy/vendor-user $(BOARD_VENDOR_SEPOLICY_DIRS)
endif
EOF


grep -q '^[[:space:]]*# props\.append("ro\.adb\.secure=1")' build/soong/scripts/gen_build_prop.py ||
sed -i 's/^\([[:space:]]*\)props\.append("ro\.adb\.secure=1")/\1# props.append("ro.adb.secure=1")/' build/soong/scripts/gen_build_prop.py

curl -sL https://raw.githubusercontent.com/xc112lg/evolutiion_lgg6/refs/heads/main/init.qcom.usb.rc.patch | patch -d device/lge/msm8996-common -p0

curl -sL https://raw.githubusercontent.com/xc112lg/lg_releases/refs/heads/main/0001-battery-config-override.patch  | patch -d device/lge/g6-common -p0
curl -sL https://raw.githubusercontent.com/xc112lg/lg_releases/refs/heads/main/0001-bcmdhd-fix-NULL-ndev-deref-in-wl_notify_pfn_status.patch  | patch -d kernel/lge/msm8996 -p0
#curl -sL https://github.com/xc112lg/android_device_lge_g6-common/commit/89433a836be4dbc067d75ab631604039718322c3.patch | git -C device/lge/g6-common am