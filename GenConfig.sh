#!/bin/bash
set -e

WORKSPACE="$(cd "$(dirname "$0")" && pwd)"
LUBAN_CUSTOM_TEMPLATE="$WORKSPACE/Tools/Luban/CustomTemplate"
LUBAN_DLL="$WORKSPACE/Tools/Luban/LubanRelease/Luban/Luban.dll"
CONF_ROOT="$WORKSPACE/Unity/Assets/Config/Excel"
OUT_CODE_CLIENT="$WORKSPACE/Unity/Assets/Scripts/Model/Generate/Client/Config"
OUT_CODE_SERVER="$WORKSPACE/Unity/Assets/Scripts/Model/Generate/Server/Config"
OUT_DATA="$WORKSPACE/Config/Excel"

# Client
echo "===================== GenClient ===================="
dotnet "$LUBAN_DLL" \
    --customTemplateDir "$LUBAN_CUSTOM_TEMPLATE" \
    -t Client \
    -c cs-bin \
    -d bin \
    -d json \
    --conf "$CONF_ROOT/__luban__.conf" \
    -x "outputCodeDir=$OUT_CODE_CLIENT" \
    -x "bin.outputDataDir=$OUT_DATA/c" \
    -x "json.outputDataDir=$WORKSPACE/Config/Json/c" \
    -x "lineEnding=CRLF"

echo "===================== GenClientFinish ===================="

# Server
echo "===================== GenServer ===================="
dotnet "$LUBAN_DLL" \
    --customTemplateDir "$LUBAN_CUSTOM_TEMPLATE" \
    -t Server \
    -c cs-bin \
    -d bin \
    -d json \
    --conf "$CONF_ROOT/__luban__.conf" \
    -x "outputCodeDir=$OUT_CODE_SERVER" \
    -x "bin.outputDataDir=$OUT_DATA/s" \
    -x "json.outputDataDir=$WORKSPACE/Config/Json/s" \
    -x "lineEnding=CRLF"

echo "===================== GenServerFinish ===================="

# StartConfig Release
echo "===================== StartConfig Release ===================="
dotnet "$LUBAN_DLL" \
    --customTemplateDir "$LUBAN_CUSTOM_TEMPLATE" \
    -t Release \
    -c cs-bin \
    -d bin \
    -d json \
    --conf "$CONF_ROOT/StartConfig/__luban__.conf" \
    -x "outputCodeDir=$OUT_CODE_SERVER/StartConfig" \
    -x "bin.outputDataDir=$OUT_DATA/s/StartConfig/Release" \
    -x "json.outputDataDir=$WORKSPACE/Config/Json/s/StartConfig/Release" \
    -x "lineEnding=CRLF"

echo "===================== StartConfig ReleaseFinish ===================="

# StartConfig Benchmark (暂时注释，使用 Release)
# echo "===================== StartConfig Benchmark ===================="
# dotnet "$LUBAN_DLL" \
#     --customTemplateDir "$LUBAN_CUSTOM_TEMPLATE" \
#     -t Benchmark \
#     -c cs-bin \
#     -d bin \
#     -d json \
#     --conf "$CONF_ROOT/StartConfig/__luban__.conf" \
#     -x "outputCodeDir=$OUT_CODE_SERVER/StartConfig" \
#     -x "bin.outputDataDir=$OUT_DATA/s/StartConfig/Benchmark" \
#     -x "json.outputDataDir=$WORKSPACE/Config/Json/s/StartConfig/Benchmark" \
#     -x "lineEnding=CRLF"
#
# echo "===================== StartConfig BenchmarkFinish ===================="

# StartConfig Localhost (暂时注释，使用 Release)
# echo "===================== StartConfig Localhost ===================="
# dotnet "$LUBAN_DLL" \
#     --customTemplateDir "$LUBAN_CUSTOM_TEMPLATE" \
#     -t Localhost \
#     -c cs-bin \
#     -d bin \
#     -d json \
#     --conf "$CONF_ROOT/StartConfig/__luban__.conf" \
#     -x "outputCodeDir=$OUT_CODE_SERVER/StartConfig" \
#     -x "bin.outputDataDir=$OUT_DATA/s/StartConfig/Localhost" \
#     -x "json.outputDataDir=$WORKSPACE/Config/Json/s/StartConfig/Localhost" \
#     -x "lineEnding=CRLF"
#
# echo "===================== StartConfig LocalhostFinish ===================="

# StartConfig RouterTest (暂时注释，使用 Release)
# echo "===================== StartConfig RouterTest ===================="
# dotnet "$LUBAN_DLL" \
#     --customTemplateDir "$LUBAN_CUSTOM_TEMPLATE" \
#     -t RouterTest \
#     -c cs-bin \
#     -d bin \
#     -d json \
#     --conf "$CONF_ROOT/StartConfig/__luban__.conf" \
#     -x "outputCodeDir=$OUT_CODE_SERVER/StartConfig" \
#     -x "bin.outputDataDir=$OUT_DATA/s/StartConfig/RouterTest" \
#     -x "json.outputDataDir=$WORKSPACE/Config/Json/s/StartConfig/RouterTest" \
#     -x "lineEnding=CRLF"
#
# echo "===================== StartConfig RouterTestFinish ===================="
