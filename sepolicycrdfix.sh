# sed -i '$r /dev/stdin' device/lge/msm8996-common/sepolicy/vendor/file_contexts <<'EOF'

# # ODM sepolicy fragments
# # AOSP's private/file_contexts only matches /(odm|vendor/odm)/etc/selinux/...
# # On this device there is no separate /vendor partition (merged into
# # /system/vendor), so the real runtime path is /system/vendor/odm/etc/selinux/...
# # which falls outside that pattern and was falling back to the generic
# # vendor_file label, causing zygote/installd/system_server (and adb shell)
# # to be denied getattr/read on these files. Types below match AOSP's own
# # per-file types (see system/sepolicy private/file_contexts) exactly.
# /system/vendor/odm/etc/selinux/odm_file_contexts                 u:object_r:file_contexts_file:s0
# /system/vendor/odm/etc/selinux/odm_seapp_contexts                u:object_r:seapp_contexts_file:s0
# /system/vendor/odm/etc/selinux/odm_property_contexts             u:object_r:property_contexts_file:s0
# /system/vendor/odm/etc/selinux/odm_service_contexts              u:object_r:vendor_service_contexts_file:s0
# /system/vendor/odm/etc/selinux/odm_hwservice_contexts            u:object_r:hwservice_contexts_file:s0
# /system/vendor/odm/etc/selinux/odm_mac_permissions\.xml          u:object_r:mac_perms_file:s0
# /system/vendor/odm/etc/selinux/odm_sepolicy\.cil                 u:object_r:sepolicy_file:s0
# EOF


# cat > device/lge/msm8996-common/sepolicy/vendor/cameraserver.te << 'EOF'
# # communicate with perfd
# allow cameraserver mpctl_data_file:dir search;
# allow cameraserver mpctl_data_file:sock_file write;
# allow cameraserver mpctl_socket:dir search;
# allow cameraserver mpctl_socket:sock_file write;
# allow cameraserver sysfs_kgsl:file r_file_perms;
# allow cameraserver camera_data_file:dir search;
# allow cameraserver mm-qcamerad:unix_dgram_socket sendto;
# set_prop(cameraserver, vendor_camera_prop)
# get_prop(cameraserver, vendor_default_prop)
# #r_dir_file(cameraserver, camera_data_file);
# EOF

# cat device/lge/msm8996-common/sepolicy/vendor/cameraserver.te

[ "$(sha1sum vendor/lge/g6-common/proprietary/vendor/lib/libmmcamera2_stats_modules.so 2>/dev/null | cut -d' ' -f1)" = "c2d54db2750abfa19c4f6078fd715f5f58788e9d" ] && echo "already patched, skipping" || curl -sL https://github.com/xc112lg/lg_releases/raw/refs/heads/main/libmmcamera2_stats_modules.so -o vendor/lge/g6-common/proprietary/vendor/lib/libmmcamera2_stats_modules.so
#grep -q '^import android.os.SystemClock$' packages/apps/Aperture/app/src/main/java/org/lineageos/aperture/CameraActivity.kt && echo "already applied, skipping" || curl -sL https://raw.githubusercontent.com/xc112lg/lg_releases/refs/heads/main/0001-CameraActivity-enforce-cooldown-between-camera-rebin.patch | patch -d packages/apps/Aperture -p1


#grep -q 'mitigate mm-qcamera-daemon PDAF race' kernel/lge/msm8996/drivers/media/platform/msm/camera_v2/sensor/actuator/msm_actuator.c && echo "already applied, skipping" || curl -sL https://raw.githubusercontent.com/xc112lg/lg_releases/refs/heads/main/msm_actuator_claf_delay1.patch | patch -d kernel/lge/msm8996 -p1