
 mkdir -p device/lge/msm8996-common/overlay/frameworks/base/core/res/res/values
    curl -sf -o device/lge/msm8996-common/overlay/frameworks/base/core/res/res/values/cr_config.xml \
        https://raw.githubusercontent.com/crdroidandroid/android_frameworks_base/16.0/core/res/res/values/cr_config.xml

mkdir -p device/lge/msm8996-common/overlay/frameworks/base/packages/SystemUI/res/values
curl -sf -o device/lge/msm8996-common/overlay/frameworks/base/packages/SystemUI/res/values/cr_config.xml \
    https://raw.githubusercontent.com/crdroidandroid/android_frameworks_base/16.0/packages/SystemUI/res/values/cr_config.xml
