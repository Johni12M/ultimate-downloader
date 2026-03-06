@echo off

powershell -Command "Invoke-WebRequest http://www.unifoundry.com/pub/unifont/unifont-15.0.01/font-builds/unifont-15.0.01.ttf -OutFile unifont-15.0.01.ttf"

winget install ImageMagick.ImageMagick
winget install Gyan.FFmpeg
winget install OpenJS.NodeJS
winget install ArtifexSoftware.mutool

echo Installing EbookDownloader dependencies...
npm install

echo Building d4sd (submodule)...
cd d4sd
npm install
node_modules\.bin\tsc --module es2022
node_modules\.bin\tsc-alias 2>nul
node_modules\.bin\tsc --module commonjs --outDir cjs
echo {"type": "commonjs"} > cjs\package.json
cd ..

echo.
echo Setup complete! Run with: ultimate-downloader
PAUSE
