#!/usr/bin/env bash

set -e

DERIVED_PATH=${BUILT_PRODUCTS_DIR}/../DerivedSources
SCRIPT_PATH=${SOURCE_ROOT}/podcasts/Credentials/replace_secrets.rb

CREDS_INPUT_PATH=${SOURCE_ROOT}/podcasts/Credentials/ApiCredentials.tpl
LOCAL_SECRETS_FILE="${SRCROOT}/podcasts/Credentials/LocalApiCredentials.swift"
LOCAL_FIREBASE_PLIST="${SRCROOT}/podcasts/Credentials/mock-GoogleService-Info.plist"
CREDS_OUTPUT_PATH=${DERIVED_PATH}/ApiCredentials.swift

FIREBASE_OUTPUT_PATH=${DERIVED_PATH}/GoogleService-Info.plist

# If the developer has a local secrets file, use it
if [ -f "$LOCAL_SECRETS_FILE" ]; then
    echo "warning: Using local Secrets from $LOCAL_SECRETS_FILE. If you are an external contributor, this is expected and you can ignore this warning. If you are an internal contributor, make sure to use our shared credentials instead."
    echo "Applying Local Secrets"
    cp -v "$LOCAL_SECRETS_FILE" "${CREDS_OUTPUT_PATH}"
    echo "Copying mock GoogleService-Info.plist"
    echo $(<${LOCAL_FIREBASE_PLIST}) > "${FIREBASE_OUTPUT_PATH}"
    exit 0
fi

## Validate Secrets!
##
if [ ! -f $SECRETS_PATH ]; then
    echo "error: $SECRETS_PATH not found! Please run \`bundle exec fastlane run configure_apply\`."
    exit 1
else
    echo ">> Loading Secrets from ${SECRETS_PATH}"

    ## Generate the Derived Sources folder, if needed
    ##
    mkdir -p ${DERIVED_PATH}

    ## Generate ApiCredentials.swift
    ##
    echo ">> Generating Credentials ${CREDS_OUTPUT_PATH}"
    ruby ${SCRIPT_PATH} -i ${CREDS_INPUT_PATH} -s ${SECRETS_PATH} > "${CREDS_OUTPUT_PATH}"

    ## Copy private GoogleService-Info.plist
    ##
    echo ">> Copying Firebase Credentials from ${FIREBASE_SECRETS_PATH}"
    echo $(<${FIREBASE_SECRETS_PATH}) > "${FIREBASE_OUTPUT_PATH}"
fi
