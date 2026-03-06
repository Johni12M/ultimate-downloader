@echo off
set PUPPETEER_CACHE_DIR=%~dp0..\browser-cache
"%~dp0..\node\node.exe" "%~dp0..\src\EbookDownloader.js" %*
