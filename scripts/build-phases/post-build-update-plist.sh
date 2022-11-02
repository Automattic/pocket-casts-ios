#!/usr/bin/env bash
PLIST_FILE="$TARGET_BUILD_DIR/$INFOPLIST_PATH"

if [ -f "$GOOGLE_SIGN_IN_SECRETS_PATH" ] && [ -f "$PLIST_FILE" ]; then
	# The CFBundleURLName key to look for
	replace_key="GoogleSignIn"

	# Get the REVERSED_CLIENT_ID from the plist
	url_scheme=$(plutil -extract REVERSED_CLIENT_ID raw -expect string $GOOGLE_SIGN_IN_SECRETS_PATH)

	# Grab the number of elements in the URL Types array
	count=$(plutil -extract CFBundleURLTypes raw -expect array $PLIST_FILE)
	echo $count
	# Loop through the URL Types array until we find the sign in item
	for (( i=0; i<$count; i++ )) do
		key=$(plutil -extract CFBundleURLTypes.$i.CFBundleURLName raw -expect string $PLIST_FILE)
		echo $key
		if [ "$key" == "$replace_key" ]; then 
			echo "found"
			# Empty out the array, and then insert the scheme into the file
			plutil -replace CFBundleURLTypes.$i.CFBundleURLSchemes -array $PLIST_FILE
			plutil -insert CFBundleURLTypes.$i.CFBundleURLSchemes.0 -string $url_scheme $PLIST_FILE
			
			plutil -extract CFBundleURLTypes.$i.CFBundleURLSchemes.0 raw -expect string $PLIST_FILE
		fi
	done
	exit 0
fi