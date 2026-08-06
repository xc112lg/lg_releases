
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
