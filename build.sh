#!/bin/bash

mkdir -p /tmp/rom
cd /tmp/rom

git config --global user.name AlexThundrous
git config --global user.email alexthundrous2104@gmail.com

echo "${GIT_COOKIES}" > ~/gitcookies.sh
bash ~/gitcookies.sh

export rom=bootleggers

rom_one(){
 repo init --no-repo-verify -u git://github.com/Bootleggers-brokenlab/manifest.git -b rimbon -g default,-device,-mips,-darwin,-notdefault
 repo sync --no-tags --no-clone-bundle --force-sync --optimized-fetch -j30
 git clone https://github.com/AlexThundrous/device_xiaomi_sakura.git -b bootleg device/xiaomi/sakura
 git clone https://github.com/AlexThundrous/vendor_xiaomi_sakura.git -b 11 vendor/xiaomi
  rm -rf hardware/qcom-caf/msm8996/audio hardware/qcom-caf/msm8996/display hardware/qcom-caf/msm8996/media
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_audio -b 11.0 hardware/qcom-caf/msm8996/audio
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_display -b 11.0 hardware/qcom-caf/msm8996/display
 git clone https://github.com/Jabiyeff-Project/android_hardware_qcom_media -b 11.0 hardware/qcom-caf/msm8996/media
 rm -rf vendor/qcom/opensource/power && git clone https://github.com/PixelExperience/vendor_qcom_opensource_power vendor/qcom/opensource/power
  . build/envsetup.sh
 #cd build/soong && git remote add -f los https://github.com/LineageOS/android_build_soong && git cherry-pick fa55b7ca14307218264487ca85e30cfa5b987a1c 
 cd system/core && git revert 9cbabc19cb4f91cc4576f9845c9b95652bfd2871
 croot && lunch bootleg_sakura-userdebug
}

git clone https://github.com/darkhz/revvz_sakura -b beta-4.9-Q kernel/xiaomi/msm8953 
git clone https://github.com/geopd/vendor_custom_prebuilts -b master vendor/custom/prebuilts
git clone https://github.com/mvaisakh/gcc-arm64.git -b gcc-master prebuilts/gcc/linux-x86/aarch64/aarch64-elf

sed -i 's/ccache //g' kernel/xiaomi/msm8953/Makefile

case "$rom" in
 "bootleggers") rom_one
    ;;
*) echo "Invalid option!"
    exit 1
    ;;
esac

BUILD_DATE=$(date +"%Y%m%d")
BUILD_START=$(date +"%s")

telegram_message() {
    curl -s -X POST "https://api.telegram.org/bot$BOTTOKEN/sendMessage" -d chat_id="$CHATID" \
    -d "parse_mode=html" \
    -d text="$1"
}

telegram_message "<b>🌟 $rom Build Triggered 🌟</b>%0A%0A<b>Date: </b><code>$(TZ=Asia/Kolkata date +"%d-%m-%Y %T")</code>"

export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 20G && ccache -o compression=true && ccache -z
make api-stubs-docs && make system-api-stubs-docs && make test-api-stubs-docs

case "$rom" in
 "bootleggers") mka bacon -j20
    ;;  
 *) echo "Invalid option!"
    exit 1
    ;;
esac

BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

telegram_build() {
 curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot$BOTTOKEN/sendDocument" \
 -F chat_id="$CHATID" \
 -F "disable_web_page_preview=true" \
 -F "parse_mode=Markdown" \
 -F caption="$2"
}

telegram_post(){
 if [ -f $(pwd)/out/target/product/sakura/*sakura*"${BUILD_DATE}"*.zip ]; then
	curl -sL https://git.io/file-transfer | sh
	ZIP="$(echo "$(pwd)/out/target/product/sakura/*sakura*"${BUILD_DATE}"*.zip")"
	MD5CHECK=$(md5sum $ZIP | cut -d' ' -f1)
	WET=$(echo "./transfer wet $ZIP")
	ZIPNAME=$(echo "$($WET |  cut -s -d'/' -f 8)")
	DWD=$(echo "$($WET | sed '$!d' | cut -d' ' -f3)")
	telegram_message "<b>✅ Build finished after $((DIFF / 3600)) hour(s), $((DIFF % 3600 / 60)) minute(s) and $((DIFF % 60)) seconds</b>%0A%0A<b>ROM: </b><code>$ZIPNAME</code>%0A%0A<b>MD5 Checksum: </b><code>$MD5CHECK</code>%0A<b>Download Link: </b><code>$DWD</code>%0A%0A<b>Date: </b><code>$(TZ=Asia/Kolkata date +"%d-%m-%Y %T")</code>"
 else
	LOG="$(echo "$(pwd)/out/build_error")"
	telegram_build $LOG "*❌ Build failed to compile after $(($DIFF / 3600)) hour(s) and $(($DIFF % 3600 / 60)) minute(s) and $(($DIFF % 60)) seconds*
	_Date:  $(TZ=Asia/Kolkata date +"%d-%m-%Y %T")_"
 fi
}

telegram_post
