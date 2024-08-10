#! /bin/bash -x

# Set the baud rate as an environment variable
SET_BAUDRATE='-b 2000000'
BUILD_DIR="build"  # Directory where the build artifacts are stored
ESP_HOSTED_CONFIG="sdkconfig.defaults.esp32s3"

# Check the necessary variables and paths are provided
if [ -z "$BUILD_DIR" ] || [ ! -d "$BUILD_DIR/build-buildroot-esp32s3" ]; then
    echo "Build directory is not set correctly or does not exist."
    exit 1
fi

cd $BUILD_DIR

# Bootloader build or update
if [ -d "esp-hosted" ]; then
    pushd esp-hosted/esp_hosted_ng/esp/esp_driver
    cmake .
    cd esp-idf
    . export.sh
    cd ../network_adapter
    idf.py set-target esp32s3
    cp $ESP_HOSTED_CONFIG sdkconfig
    idf.py build
    read -p 'Ready to flash... Press Enter'
    while ! idf.py $SET_BAUDRATE flash; do
        read -p 'Failure... Press Enter to try again'
    done
    popd
else
    echo "esp-hosted directory not found. Make sure to run the build script first."
    exit 1
fi


if [ -f "build-buildroot-esp32s3/images/xipImage" ] && [ -f "build-buildroot-esp32s3/images/rootfs.cramfs" ]; then
    parttool.py $SET_BAUDRATE write_partition --partition-name linux  --input build-buildroot-esp32s3/images/xipImage
    parttool.py $SET_BAUDRATE write_partition --partition-name rootfs --input build-buildroot-esp32s3/images/rootfs.cramfs
    if [ -f "build-buildroot-esp32s3/images/etc.jffs2" ]; then
        read -p 'Ready to flash /etc... Press Enter'
        parttool.py $SET_BAUDRATE write_partition --partition-name etc --input build-buildroot-esp32s3/images/etc.jffs2
    fi
else
    echo "Required image files do not exist. Make sure to run the build script first."
    exit 1
fi
