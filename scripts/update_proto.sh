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
    brew upgrade protobuf
    brew upgrade swift-protobuf
else
    echo "Brew is not installed. Make sure protoc + protoc-gen-swift is installed."
fi

protoc --swift_out=./Modules/Server/Sources/PocketCastsServer/Private/Protobuffer --proto_path=$API_BASE_FOLDER/ $API_BASE_FOLDER/api.proto
protoc --swift_out=./Modules/Server/Sources/PocketCastsServer/Private/Protobuffer --proto_path=$API_BASE_FOLDER/ $API_BASE_FOLDER/files.proto
