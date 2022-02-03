import fileinput
import sys
import os

new_tag = ""

for line in fileinput.input("pubspec.yaml", inplace=True):
    if line.startswith("version"):
        version_and_build = line.split(":")[1].strip()
        (version, build) = version_and_build.split("+")

        (major, minor, patch) = version.split(".")
        new_version = major + "." + minor + "." + str(int(patch) + 1) + "+" + str(int(build) + 1)
        new_tag = "v" + new_version
        line = "version: " + new_version + "\n"
    sys.stdout.write(line)

print("version set ")
print("tagging  " + new_tag)

os.system("git tag " + new_tag)
