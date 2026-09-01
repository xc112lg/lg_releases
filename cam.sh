# Remove shared library modules
for MOD in \
    "camera\.msm8996" \
    "libmmcamera_interface" \
    "libmmjpeg_interface" \
    "libqomx_core" \
    "libmmcamera_tuning" \
    "libmm-qcamera"; do

    perl -0777 -i -pe "
    while (/cc_prebuilt_library_shared\s*\{/g) {
        my \$start = \$-[0];
        my \$pos = pos(\$_);
        my \$depth = 1;

        while (\$depth && \$pos < length(\$_)) {
            my \$c = substr(\$_, \$pos++, 1);
            \$depth++ if \$c eq '{';
            \$depth-- if \$c eq '}';
        }

        my \$block = substr(\$_, \$start, \$pos - \$start);

        if (\$block =~ /^\s*cc_prebuilt_library_shared\s*\{\s*name:\s*\"$MOD\",/s) {
            substr(\$_, \$start, \$pos - \$start) = '';
            pos(\$_) = \$start;
        }
    }
    " vendor/lge/g6-common/Android.bp
done

# Remove mm-qcamera-app binary
MOD="mm-qcamera-app"

perl -0777 -i -pe "
while (/cc_prebuilt_binary\s*\{/g) {
    my \$start = \$-[0];
    my \$pos = pos(\$_);
    my \$depth = 1;

    while (\$depth && \$pos < length(\$_)) {
        my \$c = substr(\$_, \$pos++, 1);
        \$depth++ if \$c eq '{';
        \$depth-- if \$c eq '}';
    }

    my \$block = substr(\$_, \$start, \$pos - \$start);

    if (\$block =~ /^\s*cc_prebuilt_binary\s*\{\s*name:\s*\"$MOD\",/s) {
        substr(\$_, \$start, \$pos - \$start) = '';
        pos(\$_) = \$start;
    }
}
" vendor/lge/g6-common/Android.bp

sed -i \
    -e '/^[[:space:]]*libmm-qcamera[[:space:]]*\\\{0,1\}[[:space:]]*$/d' \
    -e '/^[[:space:]]*libmmcamera_tuning[[:space:]]*\\\{0,1\}[[:space:]]*$/d' \
    -e '/^[[:space:]]*mm-qcamera-app[[:space:]]*\\\{0,1\}[[:space:]]*$/d' \
    vendor/lge/g6-common/g6-common-vendor.mk

for MOD in "camera\.msm8996" "libmmcamera_interface" "libmmjpeg_interface" "libqomx_core" "libmmcamera_tuning" "libmm-qcamera" "mm-qcamera-app"; do perl -i -ne "print unless /^\s*$MOD\s*\\\\?\s*\$/;" vendor/lge/g6-common/g6-common-vendor.mk; done

