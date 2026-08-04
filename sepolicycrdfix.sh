sed -i '$r /dev/stdin' device/lge/msm8996-common/sepolicy/vendor/file_contexts <<'EOF'

# ODM sepolicy fragments
# AOSP's private/file_contexts only matches /(odm|vendor/odm)/etc/selinux/...
# On this device there is no separate /vendor partition (merged into
# /system/vendor), so the real runtime path is /system/vendor/odm/etc/selinux/...
# which falls outside that pattern and was falling back to the generic
# vendor_file label, causing zygote/installd/system_server (and adb shell)
# to be denied getattr/read on these files. Types below match AOSP's own
# per-file types (see system/sepolicy private/file_contexts) exactly.
/system/vendor/odm/etc/selinux/odm_file_contexts                 u:object_r:file_contexts_file:s0
/system/vendor/odm/etc/selinux/odm_seapp_contexts                u:object_r:seapp_contexts_file:s0
/system/vendor/odm/etc/selinux/odm_property_contexts             u:object_r:property_contexts_file:s0
/system/vendor/odm/etc/selinux/odm_service_contexts              u:object_r:vendor_service_contexts_file:s0
/system/vendor/odm/etc/selinux/odm_hwservice_contexts            u:object_r:hwservice_contexts_file:s0
/system/vendor/odm/etc/selinux/odm_mac_permissions\.xml          u:object_r:mac_perms_file:s0
/system/vendor/odm/etc/selinux/odm_sepolicy\.cil                 u:object_r:sepolicy_file:s0
EOF

cat device/lge/msm8996-common/sepolicy/vendor/file_contexts