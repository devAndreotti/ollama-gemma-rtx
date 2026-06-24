@echo off
title Gemma 2 9B (q3_K_S) - Chat Local (Ollama / CUDA)
color 0B
echo ============================================================
echo    Gemma 2 9B (q3_K_S) - Chat Local via Ollama
echo    GPU: RTX 2050 - CUDA, 33/43 layers (~7-8 tok/s)
echo    Model: gemma9-cuda  ^|  Context: 8K
echo    NOTE: slower than the 2B (partial CPU offload)
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

echo Server ready. Loading model (first time: ~10-20s)...
echo.
echo --------------------------------------------------------
echo  Tip: type  /bye  and ENTER to quit the chat.
echo --------------------------------------------------------
echo.
"%LOCALAPPDATA%\Programs\Ollama\ollama.exe" run gemma9-cuda

echo.
echo Chat closed. Press any key to close this window.
pause >nul
