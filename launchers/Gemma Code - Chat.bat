@echo off
title Gemma Code - Assistente de Programacao (Ollama / CUDA)
color 0D
echo ============================================================
echo    Gemma Code - codigo primeiro, deterministico (temp 0.2)
echo    Base: E4B (o mais inteligente)  ^|  Modelo: gemma-code
echo ============================================================
echo.
start "" "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe"
:wait_server
"%LOCALAPPDATA%\Programs\Ollama\ollama.exe" list >nul 2>&1
if errorlevel 1 ( ping -n 2 127.0.0.1 >nul & goto wait_server )
echo  Dica: /bye para sair.
echo.
"%LOCALAPPDATA%\Programs\Ollama\ollama.exe" run gemma-code
pause >nul
