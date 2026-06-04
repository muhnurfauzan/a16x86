#!/bin/bash

# ==========================================
# Skrip Build LineageOS x86 (Branch: 23.2)
# ==========================================

# 1. Konfigurasi
BRANCH_NAME="lineage-23.2" 
TARGET_DEVICE="lineage_x86-userdebug" # Target untuk arsitektur x86
WORKING_DIR="$HOME/lineageos_x86"

# 2. Setup direktori kerja
mkdir -p "$WORKING_DIR"
cd "$WORKING_DIR" || exit

# 3. Mengunduh tool 'repo' dari Google
echo ">>> Mengunduh tool repo..."
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

# Konfigurasi identitas Git (Wajib)
# Ubah dengan nama dan email Anda jika perlu
git config --global user.name "BuildBot"
git config --global user.email "buildbot@example.com"

# 4. Inisialisasi Repository LineageOS
echo ">>> Menginisialisasi repositori LineageOS (Branch: $BRANCH_NAME)..."
repo init -u https://github.com/LineageOS/android.git -b $BRANCH_NAME

# 5. Sinkronisasi Source Code (Ini akan memakan waktu SANGAT lama)
echo ">>> Memulai sinkronisasi source code (Downloading...)"
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

echo ">>> Mengunduh Google Services (MindTheGapps)..."
git clone https://gitlab.com/MindTheGapps/vendor_gapps.git vendor/gapps

echo ">>> Mengintegrasikan KernelSU..."
KERNEL_DIR=$(find kernel device -maxdepth 4 -type f -name "Makefile" -exec grep -l "VERSION =" {} + | xargs dirname | head -n 1)
if [ ! -z "$KERNEL_DIR" ]; then
    echo "Ditemukan direktori kernel di: $KERNEL_DIR"
    cd $KERNEL_DIR
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
    cd -
else
    echo "Peringatan: Direktori kernel tidak ditemukan. KernelSU mungkin tidak terpasang."
fi

# 6. Menyiapkan Environment Build
echo ">>> Menyiapkan environment..."
source build/envsetup.sh

# Flag agar LineageOS menyertakan Google Apps (Play Store dll)
export WITH_GAPPS=true

# 7. Memulai Kompilasi (Build)
echo ">>> Memulai build untuk arsitektur x86 dengan GApps..."
lunch $TARGET_DEVICE
mka iso_img -j$(nproc --all)

echo ">>> Selesai! Jika berhasil, file .iso ROM (dengan GApps) akan berada di out/target/product/x86/ (biasanya dengan format lineage-23.2-x86.iso)"
