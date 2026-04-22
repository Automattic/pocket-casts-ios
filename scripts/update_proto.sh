#!/usr/bin/env bash

# This script generates the protobuffer Swift files required for the server module, based on the definitions in the API project
# It takes one parameter, the path to the folder inside the API project from which these files are generated

set -e

API_BASE_FOLDER=$1
if [[ -z $API_BASE_FOLDER ]];
then
    echo "Missing argument, please specify the full path to the protobuffer files for the API project."
    echo "Eg: update_proto.sh ~/pocketcasts-api/api/modules/protobuf/src/main/proto"
    exit 1
fi

if command -v brew &> /dev/null; then
    for pkg in protobuf swift-protobuf; do
        if brew list --formula "$pkg" &> /dev/null; then
            # Upgrades are best-effort: a transient Homebrew failure shouldn't
            # block proto generation when the installed version already works.
            brew upgrade "$pkg" || echo "Warning: failed to upgrade $pkg; continuing with the installed version."
        else
            brew install "$pkg"
        fi
    done
else
    echo "Brew is not installed. Make sure protoc + protoc-gen-swift is installed."
fi

for tool in protoc protoc-gen-swift; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not on PATH. Install protobuf and swift-protobuf and try again."
        exit 1
    fi
done

PROTO_OUT=./Modules/Sources/PocketCastsServer/Private/Protobuffer
protoc --swift_out="$PROTO_OUT" --proto_path="$API_BASE_FOLDER" "$API_BASE_FOLDER/api.proto"
protoc --swift_out="$PROTO_OUT" --proto_path="$API_BASE_FOLDER" "$API_BASE_FOLDER/files.proto"
