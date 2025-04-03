#!/usr/bin/env bash
set -e

upload_to_sourceforge() {
    local file="$1"
    local dest="$2"  # Destination directory on SourceForge
    echo "Attempting to upload $file to SourceForge: $dest"
    sshpass -p "$SF_PASSWORD" rsync -avP -e "ssh -o StrictHostKeyChecking=no" "$file" $SF_USERNAME@$SF_HOST:$dest
    if [ $? -eq 0 ]; then
        echo "Uploaded $file to SourceForge successfully."
        return 0  # Explicitly return 0 for success
    else
        echo "Error: Upload of $file to SourceForge failed."
        return 1  # Explicitly return 1 for failure
    fi
}

TARGET_DIR="/home/arman/rising-ci/out/target/product/${CODENAME}"
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' does not exist."
    exit 1
fi

cd "$TARGET_DIR"

# Get build date (YYYY-MM-DD)
BUILD_DATE=$(date +%Y-%m-%d)

# Get build time (HHMM)
BUILD_TIME=$(date +%H%M)

# Destination directory for all uploads
UPLOAD_DIR="/home/frs/project/risingos-revived/CI/$CODENAME/$BUILD_TIME-$BUILD_DATE/"

# Upload .zip files
FILES=(RisingOS_Revived*.zip)
for FILE in "${FILES[@]}"; do
    if [ ! -e "$FILE" ]; then
        echo "Error: File '$FILE' not found in $TARGET_DIR."
        exit 1
    fi
    upload_to_sourceforge "$FILE" "$UPLOAD_DIR/" || exit 1
done

# Attempt to upload specific images, but don't fail if they don't upload
IMAGES=("boot.img" "dtbo.img" "vendor_boot.img" "recovery.img")
for IMAGE in "${IMAGES[@]}"; do
    if [ -e "$IMAGE" ]; then
        upload_to_sourceforge "$IMAGE" "$UPLOAD_DIR/IMGs/"
    fi
done

echo "All uploads to SourceForge completed."
echo "Uploaded to here: https://sourceforge.net/projects/risingos-revived/files/CI/$CODENAME/$BUILD_TIME-$BUILD_DATE"
