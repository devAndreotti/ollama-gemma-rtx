@echo off
title Gemma 4 E2B QAT - Chat Local (Ollama)
color 0A
echo ============================================================
echo    Gemma 4 E2B (QAT Q4_0) - Chat Local via Ollama
echo    GPU: RTX 2050 - CUDA full offload  ^|  Modelo: gemma4-cuda
echo    Speed: ~49 tok/s  ^|  Context: 128K
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

echo Server ready. Loading model...
echo.
echo --------------------------------------------------------
echo  Tip: type  /bye  and ENTER to quit the chat.
echo --------------------------------------------------------
echo.
"%LOCALAPPDATA%\Programs\Ollama\ollama.exe" run gemma4-cuda

echo.
echo Chat closed. Press any key to close this window.
pause >nul
