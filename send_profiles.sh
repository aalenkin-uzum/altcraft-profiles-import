#!/bin/bash
source altcraft_settings.sh

echo "URL: $URL"
echo "FILES_DIR: $FILES_DIR"
echo "TOKEN: $TOKEN"

for file in "$FILES_DIR"/*.json; do
    json_data=$(cat "$file")

    body="{\"token\":\"$TOKEN\",\"db_id\":1,\"matching\":\"phone\",\"data\":$json_data}"

    response=$(curl -X POST -H "Content-Type: application/json" -d "$body" "$URL")

    echo "Response from $file:"
    echo "$response"
    echo
done