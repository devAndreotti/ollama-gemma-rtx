@echo off
title Gemma 4 E4B (QAT) - Chat Local (Ollama / CUDA)
color 0E
echo ============================================================
echo    Gemma 4 E4B (QAT) - Chat Local via Ollama
echo    GPU: RTX 2050 - CUDA, 43/43 layers (full GPU), ~29 tok/s
echo    Model: gemma4e4b-cuda  ^|  Context: 32K
echo    Smarter than the 2B; a bit slower (still fast).
echo ============================================================
echo.

echo Starting Ollama server (if needed)...
start "" "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe"

echo Waiting for server...
:wait_server
"%LOCALAPPDATA%\Programs\Ollama\ollama.exe" list >nul 2>&1
if errorlevel 1 (
  ping -n 2 127.0.0.1 >nul
  goto wait_server
)

echo Server ready. Loading model (first time: ~10-15s)...
echo.
echo --------------------------------------------------------
echo  Tip: type  /bye  and ENTER to quit the chat.
echo --------------------------------------------------------
echo.
"%LOCALAPPDATA%\Programs\Ollama\ollama.exe" run gemma4e4b-cuda

echo.
echo Chat closed. Press any key to close this window.
pause >nul
