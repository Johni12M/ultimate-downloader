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

echo Registering global command...
npm link
if %errorlevel% neq 0 (
    echo [Warning] npm link failed. Try running init.bat as Administrator.
)

echo.
echo ============================================
echo  Setup complete!
echo  You can now run the tool with:
echo.
echo    ultimate-downloader
echo.
echo  (You may need to restart your terminal first)
echo ============================================
echo.
PAUSE
