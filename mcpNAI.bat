@echo off
chcp 65001 >nul
REM ===== НАСТРОЙКИ =====
set PORT=8000
set MCP_CMD=%LOCALAPPDATA%\Roblox\mcp.bat
set CFLOG=%TEMP%\cf_mcp.log
REM =====================
​
echo Закрываю старые MCP-процессы...
taskkill /F /IM StudioMCP.exe >nul 2>&1
taskkill /F /IM rbx-studio-mcp.exe >nul 2>&1
taskkill /F /IM cloudflared.exe >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%PORT% " ^| findstr LISTENING') do taskkill /F /PID %%p >nul 2>&1
del "%CFLOG%" >nul 2>&1
​
echo Запускаю MCP-сервер...
start "MCP Server" /d "%LOCALAPPDATA%\Roblox" cmd /k npx -y supergateway --stdio "mcp.bat" --outputTransport streamableHttp --port %PORT% --stateful --sessionTimeout 300000
​
timeout /t 4 /nobreak >nul
​
echo Запускаю туннель Cloudflare...
start "MCP Tunnel" cmd /k cloudflared tunnel --url http://localhost:%PORT% --logfile "%CFLOG%"
​
echo Жду адрес туннеля...
set URL=
for /l %%i in (1,1,30) do (
  if not defined URL (
    timeout /t 1 /nobreak >nul
    for /f "tokens=*" %%a in ('findstr /r /c:"https://[a-z0-9-]*\.trycloudflare\.com" "%CFLOG%" 2^>nul') do (
      for %%w in (%%a) do (
        echo %%w | findstr /r /c:"^https://.*trycloudflare\.com" >nul && set URL=%%w
      )
    )
  )
)
​
echo.
if defined URL (
  echo %URL%/mcp| clip
  echo =============================================
  echo  Адрес для Notion ^(уже скопирован^):
  echo  %URL%/mcp
  echo =============================================
  echo Вставь его в ТО ЖЕ подключение в Notion через Edit.
) else (
  echo Не нашел адрес. Посмотри его в окне "MCP Tunnel" и добавь /mcp в конце.
)
echo Окна "MCP Server" и "MCP Tunnel" не закрывай.
pause
​