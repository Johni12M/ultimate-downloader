@echo off

powershell -Command "Invoke-WebRequest http://www.unifoundry.com/pub/unifont/unifont-15.0.01/font-builds/unifont-15.0.01.ttf -OutFile unifont-15.0.01.ttf"

winget install ImageMagick.ImageMagick
winget install Gyan.FFmpeg
winget install OpenJS.NodeJS
winget install ArtifexSoftware.mutool

REM Install EbookDownloader dependencies
npm install

REM Build d4sd (included as a submodule)
cd d4sd
npm install
node_modules\.bin\tsc --module es2022
node_modules\.bin\tsc-alias
node_modules\.bin\tsc --module commonjs --outDir cjs
echo {"type": "commonjs"} > cjs\package.json
cd ..

echo Setup complete! Run with: node src/EbookDownloader.js
PAUSE
