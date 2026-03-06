@echo off
set PUPPETEER_CACHE_DIR=%~dp0..\browser-cache
echo Installing Chrome browser for Puppeteer (this may take a few minutes)...
"%~dp0..\node\node.exe" "%~dp0..\d4sd\node_modules\puppeteer\install.mjs"
