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

protoc --swift_out=../Sources/PocketCastsServer/Private/Protobuffer/ --proto_path=$API_BASE_FOLDER/ $API_BASE_FOLDER/api.proto
protoc --swift_out=../Sources/PocketCastsServer/Private/Protobuffer/ --proto_path=$API_BASE_FOLDER/ $API_BASE_FOLDER/files.proto
