import fileinput
import sys

for line in fileinput.input("pubspec.yaml", inplace=True):
    if line.startswith("version"):
        build_number = int(line.split("+")[-1])
        line = line.replace("+" + str(build_number), "+" + str(build_number + 1))
    sys.stdout.write(line)

for line in fileinput.input("ios/Flutter/Generated.xcconfig", inplace=True):
    if line.startswith("FLUTTER_BUILD_NUMBER"):
        build_number = int(line.split("=")[-1])
        line = line.replace("=" + str(build_number), "=" + str(build_number + 1))
    sys.stdout.write(line)
