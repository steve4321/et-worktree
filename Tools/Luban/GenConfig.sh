#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"
LUBAN_DLL="$WORKSPACE/Tools/Luban/LubanRelease/Luban/Luban.dll"
CUSTOM_TEMPLATE="$SCRIPT_DIR/CustomTemplate"
CONF_ROOT="$WORKSPACE/Unity/Assets/Config/Excel"
OUT_CODE_CLIENT="$WORKSPACE/Unity/Assets/Scripts/Model/Generate/Client/Config"
OUT_CODE_SERVER="$WORKSPACE/Unity/Assets/Scripts/Model/Generate/Server/Config"
OUT_DATA="$WORKSPACE/Config/Excel"

# Client
echo "===================== GenClient ===================="
dotnet "$LUBAN_DLL" \
    --customTemplateDir "$CUSTOM_TEMPLATE" \
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
    --customTemplateDir "$CUSTOM_TEMPLATE" \
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

# StartConfig Release - 生成代码和数据
echo "===================== StartConfig Release ===================="
dotnet "$LUBAN_DLL" \
    --customTemplateDir "$CUSTOM_TEMPLATE" \
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

# StartConfig Benchmark - 只生成数据（代码生成到临时目录后清理）
echo "===================== StartConfig Benchmark ===================="
dotnet "$LUBAN_DLL" \
    --customTemplateDir "$CUSTOM_TEMPLATE" \
    -t Benchmark \
    -c cs-bin \
    -d bin \
    -d json \
    --conf "$CONF_ROOT/StartConfig/__luban__.conf" \
    -x "outputCodeDir=/tmp/luban_benchmark_code" \
    -x "bin.outputDataDir=$OUT_DATA/s/StartConfig/Benchmark" \
    -x "json.outputDataDir=$WORKSPACE/Config/Json/s/StartConfig/Benchmark" \
    -x "lineEnding=CRLF"

# 清理临时目录
rm -rf /tmp/luban_benchmark_code

echo "===================== StartConfig BenchmarkFinish ===================="

# 重新生成扩展方法文件
bash "$SCRIPT_DIR/GenExts.sh"
