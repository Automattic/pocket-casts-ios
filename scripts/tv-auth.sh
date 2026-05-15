# Requires jq (brew install jq)

read -p "PC email?" PC_EMAIL

read -sp "Password?" PC_PASSWORD
echo 

PC_BASE_URL="https://api.pocketcasts.com"

read -p "Auth code?" PC_USER_CODE

# Run this once to get an access token (Simulates user logging in)
PC_LOGIN_RESPONSE=$(curl -s -X POST $PC_BASE_URL/user/login \
   -H "Content-Type: application/json" \
   -d "{\"email\": \"$PC_EMAIL\", \"password\": \"$PC_PASSWORD\"}")
echo "$PC_LOGIN_RESPONSE" | jq
PC_TOKEN=$(echo "$PC_LOGIN_RESPONSE" | jq -r .token)

# Approve the session (Simulates user)
curl -s -X POST $PC_BASE_URL/device/approve \
   -H "Content-Type: application/json" \
   -H "Authorization: Bearer $PC_TOKEN" \
   -d "{\"userCode\": \"$PC_USER_CODE\", \"deny\": false}" | jq
