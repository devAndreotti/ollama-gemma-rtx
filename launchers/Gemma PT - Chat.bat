@echo off
title Gemma PT - Assistente PT-BR rapido (Ollama / CUDA)
color 0A
echo ============================================================
echo    Gemma PT - PT-BR conciso, SEM modo "thinking" (rapido)
echo    Base: E2B (~49 tok/s)  ^|  Modelo: gemma-pt
echo ============================================================
echo.
start "" "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe"
:wait_server
"%LOCALAPPDATA%\Programs\Ollama\ollama.exe" list >nul 2>&1
if errorlevel 1 ( ping -n 2 127.0.0.1 >nul & goto wait_server )
echo  Dica: /bye para sair.
echo.
"%LOCALAPPDATA%\Programs\Ollama\ollama.exe" run gemma-pt --think=false
pause >nul
