wget "http://www.unifoundry.com/pub/unifont/unifont-15.0.01/font-builds/unifont-15.0.01.ttf"
sudo apt install imagemagick ffmpeg nodejs npm mupdf-tools

# Install EbookDownloader dependencies
npm install

# Build d4sd (included as a submodule)
cd d4sd
npm install
./node_modules/.bin/tsc --module es2022
./node_modules/.bin/tsc-alias   # adds .js extensions to ESM imports (required)
./node_modules/.bin/tsc --module commonjs --outDir cjs
echo '{"type": "commonjs"}' > cjs/package.json
cd ..

echo ""
echo "Setup complete! Run with: ultimate-downloader"
