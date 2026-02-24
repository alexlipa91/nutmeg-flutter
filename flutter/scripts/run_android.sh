#!/bin/bash

# Default values
DEVICE="android"
DEVICE_EXPLICIT=false
ENV_FILE=".env.prod"
START_EMULATOR=false
EMULATOR_NAME=""

resolve_android_sdk_bin() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        command -v "$tool"
        return 0
    fi

    local sdk_dirs=(
        "${ANDROID_SDK_ROOT:-}"
        "${ANDROID_HOME:-}"
        "$HOME/Library/Android/sdk"
    )

    for sdk in "${sdk_dirs[@]}"; do
        [[ -z "$sdk" ]] && continue
        if [[ "$tool" == "emulator" && -x "$sdk/emulator/emulator" ]]; then
            echo "$sdk/emulator/emulator"
            return 0
        fi
        if [[ "$tool" == "adb" && -x "$sdk/platform-tools/adb" ]]; then
            echo "$sdk/platform-tools/adb"
            return 0
        fi
    done

    return 1
}

start_emulator_if_needed() {
    local emulator_bin
    local adb_bin
    emulator_bin="$(resolve_android_sdk_bin emulator)" || {
        echo "Could not find Android emulator binary. Install Android SDK emulator tools."
        exit 1
    }
    adb_bin="$(resolve_android_sdk_bin adb)" || {
        echo "Could not find adb binary. Install Android platform-tools."
        exit 1
    }

    local running_emulator
    running_emulator="$("$adb_bin" devices | awk '/^emulator-/{print $1; exit}')"
    if [[ -n "$running_emulator" ]]; then
        echo "Emulator already running: $running_emulator"
        if [[ "$DEVICE_EXPLICIT" == false ]]; then
            DEVICE="$running_emulator"
        fi
        return 0
    fi

    if [[ -z "$EMULATOR_NAME" ]]; then
        EMULATOR_NAME="$("$emulator_bin" -list-avds | awk 'NR==1{print; exit}')"
    fi

    if [[ -z "$EMULATOR_NAME" ]]; then
        echo "No Android Virtual Devices found. Create one in Android Studio > Device Manager."
        exit 1
    fi

    echo "Starting emulator '$EMULATOR_NAME'..."
    nohup "$emulator_bin" -avd "$EMULATOR_NAME" >/tmp/nutmeg-emulator.log 2>&1 &

    local serial=""
    local timeout_seconds=120
    local elapsed=0
    until [[ -n "$serial" || "$elapsed" -ge "$timeout_seconds" ]]; do
        sleep 2
        elapsed=$((elapsed + 2))
        serial="$("$adb_bin" devices | awk '/^emulator-/{print $1; exit}')"
    done

    if [[ -z "$serial" ]]; then
        echo "Timed out waiting for emulator to appear in adb devices."
        exit 1
    fi

    echo "Waiting for emulator boot completion ($serial)..."
    elapsed=0
    local boot_completed=""
    until [[ "$boot_completed" == "1" || "$elapsed" -ge "$timeout_seconds" ]]; do
        sleep 2
        elapsed=$((elapsed + 2))
        boot_completed="$("$adb_bin" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
    done

    if [[ "$boot_completed" != "1" ]]; then
        echo "Timed out waiting for emulator to finish booting."
        exit 1
    fi

    echo "Emulator is ready: $serial"
    if [[ "$DEVICE_EXPLICIT" == false ]]; then
        DEVICE="$serial"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE="$2"
            DEVICE_EXPLICIT=true
            shift 2
            ;;
        -e|--env)
            ENV_FILE="$2"
            shift 2
            ;;
        -s|--start-emulator)
            START_EMULATOR=true
            shift
            ;;
        -a|--avd)
            START_EMULATOR=true
            EMULATOR_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: ./scripts/run_android.sh [options]"
            echo ""
            echo "Options:"
            echo "  -d, --device   Android device id/name (default: android)"
            echo "  -e, --env      Environment file (default: .env.prod)"
            echo "  -s, --start-emulator   Start an Android emulator if none is running"
            echo "  -a, --avd      Start specific AVD name (implies --start-emulator)"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "Connected Android devices:"
            flutter devices | grep -i "android" || true
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ "$START_EMULATOR" == true ]]; then
    start_emulator_if_needed
fi

./scripts/pre_build.sh "$ENV_FILE"

echo "Running app on $DEVICE with $ENV_FILE..."
flutter run -d "$DEVICE" \
    --dart-define-from-file="$ENV_FILE"
