#!/bin/bash
set -ex
echo "uploading app apk to browserstack"
upload_app_response="$(curl -u $browserstack_username:$browserstack_access_key -X POST https://api-cloud.browserstack.com/app-automate/upload -F file=@$app_apk_path)"
app_url=$(echo "$upload_app_response" | jq .app_url)

echo "uploading test apk to browserstack"
upload_test_response="$(curl -u $browserstack_username:$browserstack_access_key -X POST https://api-cloud.browserstack.com/app-automate/espresso/test-suite -F file=@$test_apk_path)"
test_url=$(echo "$upload_test_response" | jq .test_url)

echo "starting automated tests"
payload=""
[[ -n "$browserstack_package" ]] && payload="$payload package: \$package,"
[[ -n "$browserstack_class" ]] && payload="$payload class: \$class,"
[[ -n "$browserstack_annotation" ]] && payload="$payload annotation: \$annotation,"
[[ -n "$browserstack_size" ]] && payload="$payload size: \$size,"
[[ -n "$browserstack_device_logs" ]] && payload="$payload logs: \$logs,"
[[ -n "$browserstack_video" ]] && payload="$payload video: \$video,"
[[ -n "$browserstack_local" ]] && payload="$payload local: \$loc,"
[[ -n "$browserstack_local_identifier" ]] && payload="$payload localIdentifier: \$locId,"
[[ -n "$browserstack_gps_location" ]] && payload="$payload gpsLocation: \$gpsLocation,"
[[ -n "$browserstack_language" ]] && payload="$payload language: \$language,"
[[ -n "$browserstack_locale" ]] && payload="$payload locale: \$locale,"
[[ -n "$callback_url" ]] && payload="$payload callbackURL: \$callback,"

payload="$payload app: \$app_url, testSuite: \$test_url, devices: \$devices"

json=$( jq -n \
                --argjson app_url $app_url \
                --argjson test_url $test_url \
                --argjson devices ["$browserstack_device_list"] \
                --argjson package ["$browserstack_package"] \
                --argjson class ["$browserstack_class"] \
                --argjson annotation ["$browserstack_annotation"] \
                --arg size "$browserstack_size" \
                --arg logs "$browserstack_device_logs" \
                --arg video "$browserstack_video" \
                --arg loc "$browserstack_local" \
                --arg locId "$browserstack_local_identifier" \
                --arg gpsLocation "$browserstack_gps_location" \
                --arg language "$browserstack_language" \
                --arg locale "$browserstack_locale" \
                --arg callback "$callback_url" \
                "{ $payload }")
run_test_response="$(curl -X POST https://api-cloud.browserstack.com/app-automate/espresso/build -d \ "$json" -H "Content-Type: application/json" -u "$browserstack_username:$browserstack_access_key")"
build_id=$(echo "$run_test_response" | jq .build_id | envman add --key BROWSERSTACK_BUILD_ID)

echo "build id: $build_id"
