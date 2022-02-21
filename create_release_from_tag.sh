TAG=$1
BUILD=$(echo $TAG | cut -d'+' -f2)

# promote android build
(cd android; fastlane run upload_to_play_store track_promote_to:production version_code:$BUILD track:internal)

# submit ios build
(cd ios; fastlane submit_for_review build_number:$BUILD --env .env.relase)

# create release in github
gh release create $TAG --notes "General improvements"