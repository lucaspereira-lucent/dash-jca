@echo off
setlocal

rem Publica o site no Cloudflare Pages (projeto jca-dashboard).
rem O token vem do .env desta pasta. Como o wrangler publica tudo que esta na
rem pasta do site, o .env e tirado daqui durante o deploy e devolvido no final.

set "CLOUDFLARE_ACCOUNT_ID=65a3f81ff544c27fdbffd91ee18559af"

rem Sobe para a pasta de cima; esta pasta sera publicada pelo nome.
for %%I in ("%~dp0.") do set "SITE_DIR=%%~nxI"
cd /d "%~dp0.."

set "ENV_FILE=%SITE_DIR%\.env"
set "ENV_TMP=%SITE_DIR%.env.tmp"

rem Se um deploy anterior foi interrompido, o .env ficou na pasta de cima: devolve.
if exist "%ENV_TMP%" if not exist "%ENV_FILE%" move /y "%ENV_TMP%" "%ENV_FILE%" >nul

if not defined CLOUDFLARE_API_TOKEN if exist "%ENV_FILE%" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        if /i "%%A"=="CLOUDFLARE_API_TOKEN" set "CLOUDFLARE_API_TOKEN=%%B"
    )
)
if defined CLOUDFLARE_API_TOKEN set "CLOUDFLARE_API_TOKEN=%CLOUDFLARE_API_TOKEN:"=%"
if not defined CLOUDFLARE_API_TOKEN (
    echo ERRO: CLOUDFLARE_API_TOKEN nao encontrado em "%CD%\%ENV_FILE%".
    pause
    exit /b 1
)

rem Tira o .env da pasta do site antes de publicar.
if exist "%ENV_FILE%" move /y "%ENV_FILE%" "%ENV_TMP%" >nul
if exist "%ENV_FILE%" (
    echo ERRO: nao foi possivel tirar o .env de "%SITE_DIR%". Deploy cancelado.
    pause
    exit /b 1
)

call npx wrangler pages deploy "%SITE_DIR%" --project-name=jca-dashboard
set "RC=%ERRORLEVEL%"

rem Devolve o .env, tenha o deploy funcionado ou nao.
if exist "%ENV_TMP%" move /y "%ENV_TMP%" "%ENV_FILE%" >nul
if exist "%ENV_TMP%" echo AVISO: o .env ficou em "%CD%\%ENV_TMP%". Mova de volta para "%SITE_DIR%\.env".

if not "%RC%"=="0" echo ERRO: o deploy falhou (codigo %RC%).
pause
exit /b %RC%
