#!/usr/bin/env bash
PLIST_FILE="$TARGET_BUILD_DIR/$INFOPLIST_PATH"

if [ -f "$GOOGLE_SIGN_IN_SECRETS_PATH" ] && [ -f "$PLIST_FILE" ]; then
	# The CFBundleURLName key to look for
	replace_key="GoogleSignIn"

	# Get the URL Scheme
	url_scheme=$(cat $GOOGLE_SIGN_IN_SECRETS_PATH)

	# Grab the number of elements in the URL Types array
	count=$(plutil -extract CFBundleURLTypes raw -expect array $PLIST_FILE)
	# Loop through the URL Types array until we find the sign in item
	for (( i=0; i<$count; i++ )) do
		key=$(plutil -extract CFBundleURLTypes.$i.CFBundleURLName raw -expect string $PLIST_FILE)
		if [ "$key" == "$replace_key" ]; then 
			# Empty out the array, and then insert the scheme into the file
			plutil -replace CFBundleURLTypes.$i.CFBundleURLSchemes -array $PLIST_FILE
			plutil -insert CFBundleURLTypes.$i.CFBundleURLSchemes.0 -string $url_scheme $PLIST_FILE
		fi
	done
	exit 0
fi