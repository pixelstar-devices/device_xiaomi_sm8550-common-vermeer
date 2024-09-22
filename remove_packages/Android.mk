LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := RemovePackages
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_OVERRIDES_PACKAGES := \
    Eleven \
    Etar \
    ExactCalculator \
    Jelly \
    Seedvault \
    Updater \
    CalendarGoogle \
    MarkupGoogle \
    MlkitBarcodeUIPrebuilt \
    NgaResources \
    PrebuiltExchange3Google \
    SpeechServicesByGoogle \
    talkback \
    VisionBarcodePrebuilt \
    AndroidAutoStub \
    PrebuiltGmsCoreSc_AdsDynamite \
    PrebuiltGmsCoreSc_CronetDynamite \
    PrebuiltGmsCoreSc_DynamiteLoader \
    PrebuiltGmsCoreSc_DynamiteModulesA \
    PrebuiltGmsCoreSc_DynamiteModulesC \
    PrebuiltGmsCoreSc_GoogleCertificates \
    PrebuiltGmsCoreSc_MapsDynamite \
    PrebuiltGmsCoreSc_MeasurementDynamite \
    GoogleRestore \
    Velvet \
    WellbeingPrebuilt \
    GoogleFeedback

LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := /dev/null
include $(BUILD_PREBUILT)