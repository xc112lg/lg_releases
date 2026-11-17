
cat >> device/axion/common/sepolicy/private/ax_diagnostics.te << 'EOF'

# battery, devfreq, graphics, kgsl sysfs (moved from vendor/qcom)
allow ax_diagnostics sysfs_battery_supply:dir r_dir_perms;
allow ax_diagnostics sysfs_battery_supply:file r_file_perms;
allow ax_diagnostics sysfs_devfreq:dir r_dir_perms;
allow ax_diagnostics sysfs_devfreq:file r_file_perms;
allow ax_diagnostics sysfs_graphics:dir r_dir_perms;
allow ax_diagnostics sysfs_graphics:file r_file_perms;
allow ax_diagnostics sysfs_kgsl:dir r_dir_perms;
allow ax_diagnostics sysfs_kgsl:file r_file_perms;
allow ax_diagnostics sysfs_kgsl:lnk_file read;
EOF

rm device/axion/common/sepolicy/vendor/qcom/ax_diagnostics.te
sed -i '/sysfs_battery_supply/d' device/axion/common/sepolicy/private/ax_diagnostics.te
sed -i '/vendor_sysfs_/d' device/axion/common/sepolicy/vendor/qcom/ax_kernel_manager.te