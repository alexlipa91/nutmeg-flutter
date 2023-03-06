set -x

TAG=$1
NOTES=$2
BUILD=$(echo $TAG | cut -d'+' -f2)
VERSION=$(echo $TAG | cut -d'v' -f2 | cut -d'+' -f1)

if [ -z "$NOTES" ]
then
  echo "pass release notes as second argument"
  exit -1
fi

# populate ios and android release notes
echo $NOTES > ios/fastlane/metadata/en-GB/release_notes.txt
echo $NOTES > android/fastlane/metadata/en-GB/changelogs/$BUILD.txt

# promote android build
(cd android; fastlane run upload_to_play_store track_promote_to:production version_code:$BUILD track:internal)

# submit ios build
(cd ios; fastlane submit_for_review build_number:$BUILD version:$VERSION)

# promote beta hosting site to live
firebase hosting:clone nutmeg-9099c:beta nutmeg-9099c:live

# create release in github
gh release create $TAG --notes "$NOTES"

# bump minor (we need to do this because of appstore)
python bump_patch.py

# commit new cycle bump
git commit -am "Start new version cycle"
git push