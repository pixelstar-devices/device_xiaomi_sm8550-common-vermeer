#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common )
                ONLY_COMMON=true
                ;;
        --only-target )
                ONLY_TARGET=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        product/etc/permissions/vendor.qti.hardware.data.connectionaidl-V1-java.xml)
            sed -i 's/xml version="2.0"/xml version="1.0"/g' "${2}"
            ;;
        product/etc/permissions/vendor.qti.hardware.data.connection-V1*.xml)
            sed -i 's/xml version="2.0"/xml version="1.0"/g' "${2}"
            ;;
        odm/etc/camera/aivsModel_6C06C006 | odm/lib64/libmialgo_aisn.so)
            split --bytes=20M -d "${2}" "${2}".part
            ;;
        odm/etc/camera/enhance_motiontuning.xml |odm/etc/camera/night_motiontuning.xml | odm/etc/camera/motiontuning.xml)
            sed -i 's/<?xml=/<?xml /g' "${2}"
            ;;
        odm/lib64/hw/displayfeature.default.so)
            "${PATCHELF}" --replace-needed "libstagefright_foundation.so" "libstagefright_foundation-v33.so" "${2}"
            ;;
        odm/lib64/libailab_rawhdr.so | odm/lib64/libxmi_high_dynamic_range_cdsp.so)
            "${ANDROID_ROOT}"/prebuilts/clang/host/linux-x86/clang-r450784e/bin/llvm-strip --strip-debug "${2}"
            ;;
        odm/lib64/libmt@1.3.so)
            "${PATCHELF}" --replace-needed "libcrypto.so" "libcrypto-v33.so" "${2}"
            ;;
        vendor/bin/hw/android.hardware.security.keymint-service-qti | vendor/lib64/libqtikeymint.so)
            "${PATCHELF}" --add-needed android.hardware.security.rkp-V3-ndk.so "${2}"
            ;;
        vendor/bin/hw/dolbycodec2 | vendor/bin/hw/vendor.dolby.hardware.dms@2.0-service | vendor/bin/hw/vendor.dolby.media.c2@1.0-service | vendor/lib64/hw/audio.primary.kalama.so)
            "${PATCHELF}" --add-needed "libstagefright_foundation-v33.so" "${2}"
            ;;
        vendor/bin/vendor.dpmd)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "vendor.libdpmframework.so" "${2}"
            "${PATCHELF}" --add-needed "libshim.so" "${2}"
            ;;
        vendor/lib64/c2.dolby.client.so)
            grep -q "dolbycodec_shim.so" "${2}" || "${PATCHELF}" --add-needed "dolbycodec_shim.so" "${2}"
            ;;
        vendor/etc/seccomp_policy/qwesd@2.0.policy)
            echo "pipe2: 1" >> "${2}"
            echo -e "\ngettid: 1" >> "${2}"
            ;;
        vendor/lib64/vendor.libdpmframework.so)
            "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v34.so" "${2}"
            ;;
        vendor/etc/seccomp_policy/modemManager.policy | vendor/etc/seccomp_policy/atfwd@2.0.policy | vendor/etc/seccomp_policy/wfdhdcphalservice.policy)
            echo -e "\ngettid: 1" >> "${2}"
            ;;
        vendor/lib64/libqcodec2_core.so)
            grep -q "qcodec2_shim.so" "${2}" || "${PATCHELF}" --add-needed "qcodec2_shim.so" "${2}"
            ;;
        vendor/etc/media_codecs_pineapple.xml|vendor/etc/media_codecs_pineapple_vendor.xml)
            sed -Ei "/media_codecs_(google_audio|google_c2|google_telephony|google_video|vendor_audio)/d" "${2}"
            ;;
    esac
}

if [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE_COMMON}" "${VENDOR_COMMON:-$VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../../${VENDOR}/${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
