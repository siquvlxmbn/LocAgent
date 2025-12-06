#!/bin/bash

# LocAgent 快速开始指南
# 该脚本展示如何快速使用LocAgent穿刺工具

set -e

echo "========================================="
echo "LocAgent 穿刺工具 - 快速开始"
echo "========================================="
echo ""

# 检查环境
echo "📋 检查环境..."

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3未安装"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "❌ Git未安装"
    exit 1
fi

echo "✅ 环境检查通过"
echo ""

# 设置工作目录
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$WORK_DIR"

echo "📍 工作目录: $WORK_DIR"
echo ""

# 配置API
echo "🔑 配置LiteLLM API..."
if [ -z "$LITELLM_API_KEY" ]; then
    echo "⚠️  LITELLM_API_KEY未设置"
    echo "请运行："
    echo "  export LITELLM_BASE_URL=https://llm-proxy.app.all-hands.dev"
    echo "  export LITELLM_API_KEY=sk-your-api-key"
else
    echo "✅ API已配置"
fi
echo ""

# 显示可用配置
echo "📄 可用的穿刺配置:"
echo ""
ls -1 configs/*.json | while read config; do
    NAME=$(basename "$config" .json)
    REPO=$(grep -o '"repo_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$config" | cut -d'"' -f4)
    echo "  • $NAME"
    echo "    仓库: $REPO"
    echo ""
done

echo "🚀 使用示例:"
echo ""
echo "1. 对libcare项目进行穿刺:"
echo "   ./scripts/run/locagent_piercer.sh \\"
echo "     https://github.com/cloudlinux/libcare \\"
echo "     ./configs/libcare_piercing.json \\"
echo "     ./results"
echo ""
echo "2. 对UXARRAY项目进行穿刺:"
echo "   ./scripts/run/locagent_piercer.sh \\"
echo "     https://github.com/UXARRAY/uxarray \\"
echo "     ./configs/uxarray_piercing.json \\"
echo "     ./results/uxarray"
echo ""
echo "3. 使用Docker运行:"
echo "   export LITELLM_API_KEY=sk-your-api-key"
echo "   docker build -f docker/Dockerfile -t locagent:latest ."
echo "   docker run --rm -e LITELLM_API_KEY=$LITELLM_API_KEY \\"
echo "     -v \$(pwd)/results:/app/results \\"
echo "     -v \$(pwd)/configs:/app/configs \\"
echo "     locagent:latest scripts/run/locagent_piercer.py \\"
echo "     --repo_url https://github.com/cloudlinux/libcare \\"
echo "     --config_file /app/configs/libcare_piercing.json"
echo ""
echo "📖 更多信息请查看 DOCKER_README.md"
echo ""
