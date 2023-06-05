# Change directory into the root folder.
cd "$(dirname "${BASH_SOURCE[0]}")/..";
# Copy test files.
rm -rf tests > /dev/null 2>&1;
cp -r ext/woke tests;
mv tests/woke*.toml .;
# Generate pytypes.
woke init pytypes;
# Run tests and cleanup files.
woke test && rm -rf tests woke*.toml;
