#!/bin/bash

# LocAgent 穿刺工具 - 容器化运行脚本
# 用法: ./locagent_piercer.sh <repo_url> <config.json> [output_dir]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -lt 2 ]; then
    echo -e "${RED}错误：参数不足${NC}"
    echo "用法: $0 <repo_url> <config.json> [output_dir]"
    echo ""
    echo "参数说明:"
    echo "  repo_url      - GitHub项目URL，例如: https://github.com/cloudlinux/libcare"
    echo "  config.json   - 穿刺配置文件，包含LLM参数和查询任务"
    echo "  output_dir    - 输出目录（可选，默认为./results）"
    exit 1
fi

REPO_URL=$1
CONFIG_FILE=$2
OUTPUT_DIR=${3:-./results}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}LocAgent 代码穿刺工具${NC}"
echo -e "${GREEN}========================================${NC}"

# 验证配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}错误：配置文件不存在: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 配置信息:${NC}"
echo "  仓库URL: $REPO_URL"
echo "  配置文件: $CONFIG_FILE"
echo "  输出目录: $OUTPUT_DIR"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 提取配置参数
MODEL=$(grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
DATASET_NAME=$(grep -o '"dataset_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
EVAL_LIMIT=$(grep -o '"eval_n_limit"[[:space:]]*:[[:space:]]*[0-9]*' "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ')
NUM_PROCESSES=$(grep -o '"num_processes"[[:space:]]*:[[:space:]]*[0-9]*' "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' ')

# 设置默认值
MODEL=${MODEL:-litellm_proxy/claude-sonnet-4-20250514}
EVAL_LIMIT=${EVAL_LIMIT:-1}
NUM_PROCESSES=${NUM_PROCESSES:-1}

echo -e "${YELLOW}⚙️  执行参数:${NC}"
echo "  模型: $MODEL"
echo "  数据集名: $DATASET_NAME"
echo "  评估限制: $EVAL_LIMIT"
echo "  进程数: $NUM_PROCESSES"

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker未安装，使用本地Python环境执行${NC}"
    USE_DOCKER=false
else
    USE_DOCKER=true
fi

# 准备Python脚本参数
PYTHON_SCRIPT="$PROJECT_ROOT/scripts/run/locagent_piercer.py"

if [ "$USE_DOCKER" = true ]; then
    echo -e "${GREEN}🐳 使用Docker容器执行${NC}"
    
    # 构建Docker镜像
    echo -e "${YELLOW}📦 构建Docker镜像...${NC}"
    docker build -f "$PROJECT_ROOT/docker/Dockerfile" -t locagent:latest "$PROJECT_ROOT"
    
    # 运行容器
    echo -e "${YELLOW}🚀 启动容器进行穿刺...${NC}"
    docker run --rm \
        -v "$(cd "$CONFIG_FILE" && pwd)":/app/configs \
        -v "$OUTPUT_DIR":/app/results \
        -e LITELLM_BASE_URL="${LITELLM_BASE_URL}" \
        -e LITELLM_API_KEY="${LITELLM_API_KEY}" \
        locagent:latest \
        "$PYTHON_SCRIPT" \
        --repo_url "$REPO_URL" \
        --config_file "/app/configs/$(basename "$CONFIG_FILE")" \
        --output_dir /app/results
else
    echo -e "${YELLOW}🐍 使用本地Python执行${NC}"
    
    cd "$PROJECT_ROOT"
    python "$PYTHON_SCRIPT" \
        --repo_url "$REPO_URL" \
        --config_file "$CONFIG_FILE" \
        --output_dir "$OUTPUT_DIR"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 穿刺完成！${NC}"
    echo -e "${GREEN}📁 结果保存在: $OUTPUT_DIR${NC}"
    ls -la "$OUTPUT_DIR"
else
    echo -e "${RED}❌ 穿刺失败${NC}"
    exit 1
fi
