@echo off
set WORKSPACE=..\..

set LUBAN_DLL=%WORKSPACE%\Tools\Luban\LubanRelease\Luban\Luban.dll
set CONF_ROOT=%WORKSPACE%\Unity\Assets\Config\Excel
set OUT_CODE_CLIENT=%WORKSPACE%\Unity\Assets\Scripts\Model\Generate\Client\Config
set OUT_CODE_SERVER=%WORKSPACE%\Unity\Assets\Scripts\Model\Generate\Server\Config
set OUT_DATA=%WORKSPACE%\Config\Excel

::Client
echo ===================== GenClient ====================
dotnet %LUBAN_DLL% ^
    --customTemplateDir CustomTemplate ^
    -t Client ^
    -c cs-bin ^
    -d bin ^
    -d json ^
    --conf %CONF_ROOT%\__luban__.conf ^
    -x outputCodeDir=%OUT_CODE_CLIENT% ^
    -x bin.outputDataDir=%OUT_DATA%\c ^
    -x json.outputDataDir=%WORKSPACE%\Config\Json\c ^
    -x lineEnding=CRLF ^

echo ===================== GenClientFinish ====================
pause
