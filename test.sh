#!/bin/bash
# ==============================================================================
# blossom superscript — unified build + release dispatcher for Xiaomi "blossom"
#
# Usage:
#   ./build.sh lunaris     # or lineage / evolution / axion / crdroid / derpfest
#   ./build.sh axion upload   # skip the build, only stage + release + notify
#                              # (uses whatever is already in out/target/product/*/*.zip)
#   curl -sf <raw-url-to-this-file> | bash -s lunaris
#   curl -sf <raw-url-to-this-file> | bash -s -- lineage
#
# Every ROM builds the same 5 sub-devices in a single pass: h872 / h870 /
# us997 / h873 / h870d. Use the 3rd arg to scope which of them get built:
#   ./build.sh crdroid build            # all 5 devices (default)
#   ./build.sh crdroid build all        # same as above, explicit
#   ./build.sh crdroid build h872       # just h872 (single-device build)
#   ./build.sh lunaris build h870       # same idea for any other ROM
# Naming a device not in that ROM's list is rejected.
#
# One script now does the whole pipeline per target (build → package → GitHub
# release → Telegram announce), merging what used to be build.sh + upload.sh
# (itself a merge of upevo.sh + multi_upload3.sh):
#   1. Build the ROM (Lunaris AOSP / LineageOS / Evolution X / AxionAOSP /
#      crDroid) for device "blossom". crDroid builds on the AxionAOSP source
#      tree with crDroid's cr_config.xml feature-flag overlays layered on top.
#   2. Stage the resulting zip/img/tar into the blossom_releases repo
#   3. Create/replace the GitHub release + tag and upload the artifacts
#   4. Send the Telegram announcement (Telegraph changelog + image fallback)
#
# All five ROMs release into ONE shared GitHub repo: blossom_releases
# (must already exist on GitHub under xc112lg). Each ROM keeps its own
# release tag/version string (e.g. LunarisAOSP-20260712, lineage-23.2-...,
# EvolutionX-16.0-..., AxionAOSP-..., crDroid-...) so releases never collide
# in the shared repo.
#
# Override the release repo without editing the script:
#   RELEASE_REPO=some_other_repo ./build.sh lunaris
# ==============================================================================
#set -euo pipefail
shopt -s nullglob

TARGET="${1:-}"
MODE="${2:-build}"
DEVICE="${3:-all}"

# Set repo name globally to ensure consistency across all functions
RELEASE_REPO="${RELEASE_REPO:-lg_releases}"

# Every ROM builds one or more sub-devices in a single pass; DEVICE selects
# among a given ROM's list (see the run_* functions below).
declare -A ROM_DEVICES=(
    [lunaris]="h872 h870 us997 h873 h870d"
    [lineage]="h872 h870 us997 h873 h870d"
   # [evolution]="h872 h870 us997 h873 h870d"
    [derpfest]="h872 h870 us997 h873 h870d"
    [axion]="h872 h870 us997 h873 h870d"
    [crdroid]="h872 h870 us997 h873 h870d"
    #[crdroid]="h872 h870d"
    [evolution]="h872"
)

usage() {
    echo "Usage: $0 <lunaris|lineage|evolution|axion|crdroid|derpfest> [build|upload] [device]"
    echo "   or: curl -sf <url> | bash -s <lunaris|lineage|evolution|axion|crdroid|derpfest> [build|upload] [device]"
    echo ""
    echo "  build   (default) run the full pipeline: build + stage + release + notify"
    echo "  upload  skip the build, only stage + release + notify using whatever is"
    echo "          already in out/target/product/*/*.zip"
    echo ""
    echo "  device  'all' (default) builds every device for that ROM, or name one"
    echo "          of them for a single-device build. Valid devices per ROM:"
    for rom in "${!ROM_DEVICES[@]}"; do
        echo "            $rom: ${ROM_DEVICES[$rom]}"
    done
    exit 1
}

[ -z "$TARGET" ] && usage

case "$TARGET" in
    lunaris|lineage|evolution|axion|crdroid|derpfest) ;;
    *)
        echo "✗ Unknown target: '$TARGET'"
        usage
        ;;
esac

case "$MODE" in
    build|upload) ;;
    *)
        echo "✗ Unknown mode: '$MODE'"
        usage
        ;;
esac

if [ "$DEVICE" != "all" ]; then
    valid_device=0
    for d in ${ROM_DEVICES[$TARGET]}; do
        [ "$d" = "$DEVICE" ] && valid_device=1 && break
    done
    if [ "$valid_device" -ne 1 ]; then
        echo "✗ Unknown device '$DEVICE' for target '$TARGET'"
        echo "  Valid devices for $TARGET: all, ${ROM_DEVICES[$TARGET]}"
        usage
    fi
fi

# ------------------------------------------------------------------------------
# Shared setup (identical across all three variants)
# ------------------------------------------------------------------------------
load_env() {
    if [ -f .env ]; then
        export $(cat .env | grep -v '#' | xargs)
    elif [ -f ../.env ]; then
        export $(cat ../.env | grep -v '#' | xargs)
    else
        echo no env 
    fi
}

common_prep() {
    load_env
rm -rf .repo/local_manifests/
rm -rf device/lge
rm -rf vendor/lge/msm8996-common kernel/lge/msm8996
rm -rf vendor/bacon-priv/keys vendor/lineage-priv/keys
rm -rf packages/apps/Aperture
}

common_env_exports() {
    export TARGET_USES_PICO_GAPPS=true
    export SELINUX_IGNORE_NEVERALLOWS=true
    export WITH_GMS=false
    export TARGET_INCLUDE_BCR=false
    export TARGET_PREBUILT_BCR=false
    export TARGET_ENABLE_BLUR=false
    export AXION_MAINTAINER=xc112lg
    
}

# ------------------------------------------------------------------------------
# Variant: Evolution X
# ------------------------------------------------------------------------------
run_evolution() {
    common_prep
        repo init -u https://github.com/Evolution-X/manifest -b vic --git-lfs --depth=1
        git clone https://github.com/xc112lg/local_manifests --depth 1 -b lg .repo/local_manifests
        repo sync -c -j64 --force-sync --no-clone-bundle --no-tags
        /opt/crave/resync.sh
    common_env_exports
        sed -i '$a -include vendor/evolution-priv/keys/keys.mk' device/lge/msm8996-common/msm8996.mk
        source <(curl -sf https://raw.githubusercontent.com/xc112lg/lg_releases/refs/heads/main/fixes.sh)
        grep -q '"com.lazada.android"' frameworks/base/core/java/com/android/internal/util/evolution/PixelPropsUtils.java || \
sed -i '/"com.android.chrome",/a\        "com.lazada.android",\n        "com.shopee.ph",' frameworks/base/core/java/com/android/internal/util/evolution/PixelPropsUtils.java
cat frameworks/base/core/java/com/android/internal/util/evolution/PixelPropsUtils.java
    . build/envsetup.sh

    local devices=(${ROM_DEVICES[evolution]})
    if [ "$DEVICE" != "all" ]; then
        devices=("$DEVICE")
    fi

    #echo "▶ crdroid: building device(s): ${devices[*]}"
    for dev in "${devices[@]}"; do
        #echo "▶ crdroid: lunch lineage_${dev}-bp1a-user"
        lunch "lineage_${dev}-bp1a-user"
        make installclean
        m evolution
    done

    run_upload_evolution
}

# ------------------------------------------------------------------------------
# Variant: crDroid (built on the AxionAOSP/lineage-23.2 source tree, with
# crDroid's feature-flag overlay files layered on top — same overlay paths
# crDroid's own docs use when adding cr_config.xml onto a non-crDroid tree)
# ------------------------------------------------------------------------------
run_crdroid() {
    common_prep
        repo init -u https://github.com/crdroidandroid/android.git -b 15.0 --git-lfs --depth=1
        git clone https://github.com/xc112lg/local_manifests --depth 1 -b lgcrd1 .repo/local_manifests
        repo sync -c -j64 --force-sync --no-clone-bundle --no-tags
        /opt/crave/resync.sh
    common_env_exports
         sed -i '$a -include vendor/lineage-priv/keys/keys.mk' device/lge/msm8996-common/msm8996.mk
         source <(curl -sf https://raw.githubusercontent.com/xc112lg/lg_releases/refs/heads/main/fixes.sh)
         source <(curl -sf https://raw.githubusercontent.com/xc112lg/lg_releases/refs/heads/main/crdframework.sh)
         #source <(curl -sf https://raw.githubusercontent.com/xc112lg/lg_releases/refs/heads/main/sepolicycrdfix.sh)


    
   
curl -sL https://github.com/xc112lg/android_device_lge_g6-common/commit/89433a836be4dbc067d75ab631604039718322c3.patch -o /tmp/fp-null-guard.patch && (git -C device/lge/g6-common apply -R --check /tmp/fp-null-guard.patch 2>/dev/null && echo "already applied, skipping" || git -C device/lge/g6-common am /tmp/fp-null-guard.patch)
    . build/envsetup.sh

    local devices=(${ROM_DEVICES[crdroid]})
    if [ "$DEVICE" != "all" ]; then
        devices=("$DEVICE")
    fi

   # echo "▶ crdroid: building device(s): ${devices[*]}"
    for dev in "${devices[@]}"; do
        #echo "▶ crdroid: lunch lineage_${dev}-bp1a-userdebug"
        lunch "lineage_${dev}-bp1a-user"
        make installclean
        m bacon
    done

    run_upload_crdroid
}


# ------------------------------------------------------------------------------
# Stage 1 (equivalent of upevo.sh): clone the target repo and copy build output
# into it. Sets STAGE_DIR to the directory to cd into for stage 2.
# ------------------------------------------------------------------------------
stage_artifacts() {
    local repo="$RELEASE_REPO"

    local built_zips=(out/target/product/*/*.zip)
    if [ ${#built_zips[@]} -eq 0 ]; then
        echo "✗ No built zip found under out/target/product/*/ — did the build succeed?"
        exit 1
    fi

    rm -rf "$repo"
    git clone -q "https://${GH_TOKEN}@github.com//xc112lg/${repo}" >/dev/null 2>&1

    cp out/target/product/*/*.zip "$repo/"

    for img in out/target/product/*/recovery.img; do
        device=$(basename "$(dirname "$img")")
        cp "$img" "$repo/${device}_recovery.img"
    done
    
    for img in out/target/product/*/boot.img; do
        device=$(basename "$(dirname "$img")")
        cp "$img" "$repo/${device}_boot.img"
    done
    cd "$repo"

    # lineage's upevo.sh drops the stock recovery/OTA package before uploading
    if [ "$TARGET" = "lineage" ] || [ "$TARGET" = "axion" ]; then
        rm -f *-ota.zip
    fi
}

# ------------------------------------------------------------------------------
# Stage 2 (equivalent of multi_upload3.sh): GitHub release + Telegram notify.
# Only the handful of fields that actually differ between ROMs (title, banner,
# issues/fixes/notes bullets, hashtag) are passed in — everything else in the
# Telegram message comes from the one shared TEMPLATE below.
# ------------------------------------------------------------------------------
release_and_notify() {
    local version_default="$1"
    local banner_image="$2"
    local title="$3"
    local hashtag="$4"
    local issues="$5"
    local fixes="$6"
    local notes="$7"
    
    local github_repo_default="$RELEASE_REPO"

    local telegram_message
    read -r -d '' telegram_message << TEMPLATE || true
<b>{{TITLE}} | UNOFFICIAL📱</b>

<b>Device:</b>Blossom
<b>👨‍💻 Builder:</b> <a href="http://t.me/xc112lg">xc112lg</a>
<b>🤖 Android Version:</b> 15
<b>📅 Build Date:</b> {{BUILD_DATE}}

{{DOWNLOADS_SECTION}}

<b>📝 Notes:</b>
• Work with both core and basic gapps
• Signed
• July security patch
• Default Kernel Swan

<b>❤️ Credits & Thanks:</b>
• npjohnson
• lineageOS dev team
• ROMSG for kernel
• Thanks to <a href="http://foss.crave.io">crave.io</a> for server
• Thanks to all other devs

<b>🌐 Stay Updated:</b>
📢 @LGG6_group
📢 @LGG6_releases

#LGG6 #UNOFFICIAL #{{HASHTAG}}  #Rom
TEMPLATE

    telegram_message="${telegram_message//\{\{TITLE\}\}/$title}"
    telegram_message="${telegram_message//\{\{HASHTAG\}\}/$hashtag}"
    telegram_message="${telegram_message//\{\{ISSUES\}\}/$issues}"
    telegram_message="${telegram_message//\{\{FIXES\}\}/$fixes}"
    telegram_message="${telegram_message//\{\{NOTES\}\}/$notes}"

    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

    if ! command -v gh &> /dev/null; then
        echo "GitHub CLI 'gh' not found. Downloading and installing..."
        wget -q https://github.com/cli/cli/releases/download/v2.40.1/gh_2.40.1_linux_amd64.tar.gz
        tar -xf gh_2.40.1_linux_amd64.tar.gz
        sudo mv gh_*_linux_amd64/bin/gh /usr/local/bin/ >/dev/null 2>&1
        echo "GitHub CLI 'gh' installed successfully."
    else
        echo "GitHub CLI 'gh' is already installed."
    fi

    if ! gh auth status &> /dev/null; then
        gh auth login --with-token "$GH_TOKEN" >/dev/null 2>&1
    else
        echo "Already authenticated with GitHub."
    fi

    local version="${custom_version:-$version_default}"

    if gh release view "$version" &> /dev/null; then
        echo "Deleting existing tag and releases for $version..."
        gh release delete "$version" --yes >/dev/null 2>&1 || true
        git tag -d "$version" >/dev/null 2>&1 || true
        git push origin --delete "$version" >/dev/null 2>&1 || true
        echo "Existing tag and releases deleted."
    fi

    git tag -a "$version" -m "Release $version"
    git push origin "$version" --force -q >/dev/null 2>&1

    declare -a filenames
    filenames=(*.zip *.img *.txt *.json)

    if ! gh release create "$version" --title "Release $version" --notes "Release notes" >/dev/null 2>&1; then
        echo "Error: Failed to create the release."
        exit 1
    fi

    for filename in "${filenames[@]}"; do
        if ! gh release upload "$version" "$filename" --clobber >/dev/null 2>&1; then
            echo "⚠ Failed to upload $filename — continuing"
        fi
    done

    echo "Files uploaded successfully."

    # ============================================
    # TELEGRAM NOTIFICATION
    # ============================================
    echo "Preparing to send Telegram notification..."

    local RELEASE_TAG="$version"
    local GITHUB_REPO="${GITHUB_REPO:-$github_repo_default}"

    declare -a FILE_ENTRIES
    declare -a BBCODE_ROM
    declare -a BBCODE_RECOVERY
    for filename in "${filenames[@]}"; do
        if [ -f "$filename" ]; then
            local download_url="https://github.com/$GITHUB_OWNER/$GITHUB_REPO/releases/download/$RELEASE_TAG/$filename"
            local file_size
            file_size=$(du -h "$filename" 2>/dev/null | cut -f1)
            FILE_ENTRIES+=("${filename}|${download_url}|${file_size}")
        fi
    done

    local CHANGELOG_URL="https://t.me/ProjectInfinityX/1882"

    if [ -n "${TELEGRAPH_TOKEN:-}" ]; then
        local CHANGELOG_CONTENT
        CHANGELOG_CONTENT=$(curl -fsSL \
            "https://raw.githubusercontent.com/Evolution-X/changelog/refs/heads/bka/changelogs/LATEST.txt" 2>/dev/null)

        if [ -n "$CHANGELOG_CONTENT" ]; then
            local TELEGRAPH_RESPONSE
            TELEGRAPH_RESPONSE=$(curl -s \
                -X POST "https://api.telegra.ph/createPage" \
                -d "access_token=$TELEGRAPH_TOKEN" \
                --data-urlencode "title=Changelog $(date '+%Y-%m-%d')" \
                --data-urlencode "author_name=xc112lg" \
                --data-urlencode "content=[{\"tag\":\"pre\",\"children\":[$(jq -Rs . <<< "$CHANGELOG_CONTENT")]}]")

            CHANGELOG_URL=$(echo "$TELEGRAPH_RESPONSE" | jq -r '.result.url // empty')
            if [ -n "$CHANGELOG_URL" ]; then
                echo "✓ Changelog uploaded: $CHANGELOG_URL"
            else
                CHANGELOG_URL="https://t.me/ProjectInfinityX/1882"
                echo "⚠ Failed to create Telegraph page"
            fi
        fi
    fi

    local DOWNLOADS_SECTION="
<b>📥 Downloads:</b>"

    for file_entry in "${FILE_ENTRIES[@]}"; do
        local filename="${file_entry%%|*}"
        local remaining="${file_entry#*|}"
        local url="${remaining%%|*}"
        local size="${remaining##*|}"

# Known device codenames to detect in the filename (add more as needed)
    known_devices=( "h870d" "h870" "h871" "h872" "h873" "h930" "us997" "ls993" "vs988" "as993")
    device_code=""
    filename_lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
    for dev in "${known_devices[@]}"; do
        if [[ "$filename_lower" == *"$dev"* ]]; then
            device_code="$dev"
            break
        fi
    done

    # Create label based on filename but don't show actual filename
    label="File"
    download_links=""

    if [[ "$filename" == *"Vanilla"* ]] || [[ "$filename" == *"vanilla"* ]]; then
        if [ -n "$device_code" ]; then
            label="📱 ${device_code} Vanilla ROM"
        else
            label="📱 Vanilla ROM"
        fi
        download_links="<a href=\"${url}\">GitHub</a>"
    elif [[ "$filename" == *"GApps"* ]] || [[ "$filename" == *"gapps"* ]]; then
        label="🎯 GApps Package"
        download_links="<a href=\"${url}\">GitHub</a> | <a href=\"https://sourceforge.net/projects/nikgapps/files/Releases/Android-16/\">SourceForge</a>"
    elif [[ "$filename" == *"recovery"* ]] || [[ "$filename" == *"Recovery"* ]]; then
        if [ -n "$device_code" ]; then
            label="🔧 ${device_code} Recovery"
        else
            label="🔧 Recovery"
        fi
        download_links="<a href=\"${url}\">Download</a>"
    elif [[ "$filename" == *"boot"* ]] || [[ "$filename" == *"boot"* ]]; then
        if [ -n "$device_code" ]; then
            label="🔧 ${device_code} boot"
        else
            label="🔧 boot"
        fi
        download_links="<a href=\"${url}\">Download</a>"
    elif [[ "$filename" == *.zip ]]; then
        if [ -n "$device_code" ]; then
            label="📦 ${device_code} ROM"
        else
            label="📦 ROM"
        fi
        download_links="<a href=\"${url}\">Download</a>"
    elif [[ "$filename" == *.img ]]; then
        if [ -n "$device_code" ]; then
            label="💾 ${device_code} Image File"
        else
            label="💾 Image File"
        fi
        download_links="<a href=\"${url}\">Download</a>"
    fi

    # Only show label and links, NO original full filename anywhere
    DOWNLOADS_SECTION+="
🔹 ${label} - ${download_links} (${size})"

    # --- XDA BBCode entries (same file_entry data, formatted for xdaforums.com) ---
    bbcode_dev_label="${device_code:-device}"
    if [[ "$filename" == *"Vanilla"* ]] || [[ "$filename" == *"vanilla"* ]]; then
        BBCODE_ROM+=("[*][B]📱 ${bbcode_dev_label} Vanilla ROM[/B] ([SIZE=3]${size}[/SIZE])[URL='${url}']Download[/URL]")
    elif [[ "$filename" == *"recovery"* ]] || [[ "$filename" == *"Recovery"* ]]; then
        BBCODE_RECOVERY+=("[*][B]🔧 ${bbcode_dev_label} Recovery Image[/B] ([SIZE=3]${size}[/SIZE])[URL='${url}']Download[/URL]")
    elif [[ "$filename" == *"boot"* ]] || [[ "$filename" == *"Boot"* ]]; then
        BBCODE_RECOVERY+=("[*][B]🔧 ${bbcode_dev_label} Boot Image[/B] ([SIZE=3]${size}[/SIZE])[URL='${url}']Download[/URL]")
    elif [[ "$filename" == *.zip ]]; then
        BBCODE_ROM+=("[*][B]📦 ${bbcode_dev_label} ROM[/B] ([SIZE=3]${size}[/SIZE])[URL='${url}']Download[/URL]")
    elif [[ "$filename" == *.img ]]; then
        BBCODE_RECOVERY+=("[*][B]💾 ${bbcode_dev_label} Image File[/B] ([SIZE=3]${size}[/SIZE])[URL='${url}']Download[/URL]")
    fi

done

# GApps line shown once, not repeated per entry
DOWNLOADS_SECTION+="
🔹 🎯 GApps Package <a href=\"https://sourceforge.net/projects/nikgapps/files/Releases/Android-15/\">SourceForge</a>"

    # ============================================
    # XDA BBCODE OUTPUT (built from the same FILE_ENTRIES as the Telegram post,
    # saved to disk + printed so it can be pasted straight into two separate
    # xdaforums.com posts — one for ROM zips, one for recovery images)
    # ============================================
    local BBCODE_FILE
    BBCODE_FILE="$(pwd)/bbcode_${version}.txt"
    {
        echo "[LIST]"
        printf '%s\n' "${BBCODE_ROM[@]}"
        echo "[/LIST]"
        echo
        echo "[LIST]"
        printf '%s\n' "${BBCODE_RECOVERY[@]}"
        echo "[/LIST]"
    } > "$BBCODE_FILE"

    echo "✓ XDA BBCode saved to ${BBCODE_FILE}"
    echo "-------------------- XDA BBCode --------------------"
    cat "$BBCODE_FILE"
    echo "------------------------------------------------------"

    # Send the same BBCode as its own separate Telegram message (plain text —
    # no parse_mode, so the [brackets] are sent as-is and not misread as HTML)
    if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
        echo "Sending XDA BBCode as a separate Telegram message..."
        local BBCODE_JSON
        BBCODE_JSON=$(mktemp)
        cat > "$BBCODE_JSON" << JSONEOF
{
    "chat_id": $TELEGRAM_CHAT_ID,
    "text": $(jq -R -s . < "$BBCODE_FILE")
}
JSONEOF
        local BBCODE_RESPONSE
        BBCODE_RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d @"$BBCODE_JSON" \
            "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage")
        rm -f "$BBCODE_JSON"

        if echo "$BBCODE_RESPONSE" | grep -q '"ok":true'; then
            echo "✓ XDA BBCode sent to Telegram (separate message)!"
        else
            echo "✗ Failed to send XDA BBCode to Telegram"
            echo "Response: $BBCODE_RESPONSE"
        fi
    else
        echo "⚠ Telegram credentials not set. Skipping BBCode Telegram send."
    fi

    # Substitute placeholders now that CHANGELOG_URL/DOWNLOADS_SECTION are known
    telegram_message="${telegram_message//\{\{CHANGELOG_URL\}\}/$CHANGELOG_URL}"
    telegram_message="${telegram_message//\{\{DOWNLOADS_SECTION\}\}/$DOWNLOADS_SECTION}"
    telegram_message="${telegram_message//\{\{BUILD_DATE\}\}/$(date '+%d/%m/%y')}"

    if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
        echo "⚠ Telegram credentials not set. Skipping Telegram notification."
    else
        echo "Sending Telegram notification..."

        local MSG_LENGTH=${#telegram_message}
        echo "Message length: $MSG_LENGTH characters"
        local CAPTION_LIMIT=3500
        local FALLBACK=0

        if [ $MSG_LENGTH -le $CAPTION_LIMIT ]; then
            echo "✓ Message fits in caption - sending merged (image + text in one)"
            local TEMP_JSON
            TEMP_JSON=$(mktemp)
            cat > "$TEMP_JSON" << JSONEOF
{
    "chat_id": $TELEGRAM_CHAT_ID,
    "photo": "$banner_image",
    "caption": $(printf '%s\n' "$telegram_message" | jq -R -s .),
    "parse_mode": "HTML"
}
JSONEOF
            local RESPONSE
            RESPONSE=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -d @"$TEMP_JSON" \
                "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendPhoto")
            rm -f "$TEMP_JSON"

            if echo "$RESPONSE" | grep -q '"ok":true'; then
                echo "✓ Telegram notification sent successfully (merged)!"
            else
                echo "⚠ Merged send failed, trying fallback..."
                FALLBACK=1
            fi
        else
            echo "⚠ Message too long for caption ($MSG_LENGTH > $CAPTION_LIMIT)"
            echo "✓ Using fallback: Sending image + text as separate messages"
            FALLBACK=1
        fi

        if [ "$FALLBACK" == "1" ]; then
            echo "Sending image first..."
            curl -s -X POST \
                -H "Content-Type: application/json" \
                -d "{\"chat_id\": $TELEGRAM_CHAT_ID, \"photo\": \"$banner_image\", \"parse_mode\": \"HTML\"}" \
                "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendPhoto" > /dev/null

            echo "Sending full message..."
            local TEMP_JSON
            TEMP_JSON=$(mktemp)
            cat > "$TEMP_JSON" << JSONEOF
{
    "chat_id": $TELEGRAM_CHAT_ID,
    "text": $(printf '%s\n' "$telegram_message" | jq -R -s .),
    "parse_mode": "HTML"
}
JSONEOF
            local RESPONSE
            RESPONSE=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -d @"$TEMP_JSON" \
                "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage")
            rm -f "$TEMP_JSON"

            if echo "$RESPONSE" | grep -q '"ok":true'; then
                echo "✓ Telegram notification sent successfully (fallback)!"
            else
                echo "✗ Failed to send Telegram notification"
                echo "Response: $RESPONSE"
            fi
        fi
    fi

    echo "✓ Release complete!"
}

# ------------------------------------------------------------------------------
# Variant configs
# ------------------------------------------------------------------------------
run_upload_evolution() {
    stage_artifacts
    release_and_notify \
        "lgevo" \
        "https://github.com/Evolution-X/manifest/raw/bka/Banner.png" \
        "EvolutionX-15.0" \
        "Evolution-X" \
        "NFC not working" \
        "NFC wont spawn on non NFC variant
Remove font showing up on setting" \
        "Deleted additional fonts to save more space
Debloated
Reintroduce Sandbox cause someone need to hide apps from wife
Work with both core and basic gapps
Signed
Includes MIUI Camera,Lunari Dolby
July security patch
Default Kernel Sashimi"
}


run_upload_crdroid() {
    stage_artifacts
    release_and_notify \
        "lgcrDroid" \
        "https://avatars.githubusercontent.com/u/9610671?s=200&v=4" \
        "crDroid" \
        "crDroid" \
        "NFC not working" \
        "NFC wont spawn on non NFC variant
Remove font showing up on setting" \
        "Deleted additional fonts to save more space
Debloated
Reintroduce Sandbox cause someone need to hide apps from wife
Work with both core and basic gapps
Signed
Includes MIUI Camera,Lunari Dolby
July security patch
Default Kernel Sashimi"
}

# ------------------------------------------------------------------------------
# Dispatch
# ------------------------------------------------------------------------------
load_env

if [ "$MODE" = "upload" ]; then
    echo "▶ Starting blossom upload-only: $TARGET"
    case "$TARGET" in
        evolution) run_upload_evolution ;;
        lineage)   run_upload_lineage ;;
        lunaris)   run_upload_lunaris ;;
        axion)     run_upload_axion ;;
        crdroid)   run_upload_crdroid ;;
        derpfest)  run_upload_derpfest ;;
    esac
    echo "✓ Finished blossom upload-only: $TARGET"
else
    #echo "▶ Starting blossom build: $TARGET"
    case "$TARGET" in
        evolution) run_evolution ;;
        lineage)   run_lineage ;;
        lunaris)   run_lunaris ;;
        axion)     run_axion ;;
        crdroid)   run_crdroid ;;
        derpfest)  run_derpfest ;;
    esac
   # echo "✓ Finished blossom build: $TARGET"
fi
