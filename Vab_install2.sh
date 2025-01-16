#!/data/data/com.termux/files/usr/bin/bash

echo '================ Checking Architecture and Android Version ==================='
# Architecture check
case $(uname -m) in
    aarch64)   echo 'aarch64 detected, continuing...' ;;
    arm)       dpkg --print-architecture | grep -q "arm64" && \
               echo 'aarch64 detected, continuing...' || \
               { echo 'Error: Only aarch64 is supported'; exit 1; } ;;
    *)         echo 'Error: Only aarch64 is supported'; exit 1 ;;
esac

# Android version check
android_version=$(termux-info | grep -A1 "Android version" | grep -Po "\d+")
if [ "$android_version" -lt 9 ]; then
    echo 'Error: Android 9 or above is required'
    exit 1
fi

echo '================================================================'
echo '                     Installing Dependencies'
echo '================================================================'
pkg update -y && pkg upgrade -y
pkg install -y aapt apksigner dx ecj openjdk-17 git wget

echo '================================================================'
echo '                     Downloading Latest SDK'
echo '================================================================'
cd ~ || exit 1
# Get latest SDK release URL
SDK_URL=$(curl -s https://api.github.com/repos/lzhiyong/termux-ndk/releases/latest | 
          grep "browser_download_url.*android-sdk-aarch64.zip" | 
          cut -d '"' -f 4)
wget "$SDK_URL"
unzip -qq android-sdk-aarch64.zip
rm android-sdk-aarch64.zip

echo '================================================================'
echo '                     Downloading Latest NDK'
echo '================================================================'
# Get latest NDK release URL
NDK_URL=$(curl -s https://api.github.com/repos/lzhiyong/termux-ndk/releases/latest | 
          grep "browser_download_url.*android-ndk.*aarch64.zip" | 
          cut -d '"' -f 4)
wget "$NDK_URL"
NDK_ZIP=$(basename "$NDK_URL")
unzip -qq "$NDK_ZIP"
rm "$NDK_ZIP"

# Get NDK directory name from the extracted folder
NDK_DIR=$(find . -maxdepth 1 -type d -name "android-ndk-*" -printf '%f\n')

echo '================================================================'
echo '                     Setting Environment Variables'
echo '================================================================'
# Update profile with latest paths
PROFILE=~/../usr/etc/profile
# Remove any existing ANDROID related exports
sed -i '/^export ANDROID_/d' "$PROFILE"
# Add new exports
echo "export ANDROID_HOME=/data/data/com.termux/files/home/android-sdk/" >> "$PROFILE"
echo "export ANDROID_NDK_HOME=/data/data/com.termux/files/home/$NDK_DIR/" >> "$PROFILE"
echo "export ANDROID_NDK_ROOT=\$ANDROID_NDK_HOME" >> "$PROFILE"
source "$PROFILE"

echo '================================================================'
echo '                     Installing V Language'
echo '================================================================'
pkg install -y clang libexecinfo libgc libgc-static make cmake
cd ~ || exit 1
rm -rf v  # Remove existing V directory if it exists
git clone https://github.com/vlang/v
cd v || exit 1
make
./v symlink

echo '================================================================'
echo '                     Installing VAB'
echo '================================================================'
v install vab
v ~/.vmodules/vab
# Update symlink
rm -f /data/data/com.termux/files/usr/bin/vab
ln -s /data/data/com.termux/files/home/.vmodules/vab/vab /data/data/com.termux/files/usr/bin/

echo '================================================================'
echo '                     Installation Complete'
echo '================================================================'
echo ''
echo 'Please run: source ~/./../usr/etc/profile'
echo 'Then try: vab ./v/examples/2048'
