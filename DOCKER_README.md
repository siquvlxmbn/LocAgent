# LocAgent 容器化穿刺工具

LocAgent代码穿刺工具的容器化部署和运行方案。

## 项目结构

```
LocAgent/
├── docker/
│   ├── Dockerfile              # Docker镜像构建配置
│   ├── docker-compose.yml      # Docker Compose编排文件
│   └── .dockerignore           # Docker忽略文件列表
├── scripts/run/
│   ├── locagent_piercer.sh     # 穿刺工具主脚本（Shell）
│   └── locagent_piercer.py     # 穿刺工具实现（Python）
├── configs/
│   ├── libcare_piercing.json   # libcare项目配置示例
│   └── uxarray_piercing.json   # uxarray项目配置示例
├── results/                     # 穿刺结果输出目录
└── logs/                        # 日志输出目录
```

## 快速开始

### 方式1: 使用Shell脚本（推荐）

#### 前置要求
- Bash
- Python 3.12+
- Docker（可选，有Docker时自动使用）
- Git

#### 配置环境变量

```bash
export LITELLM_BASE_URL=https://llm-proxy.app.all-hands.dev
export LITELLM_API_KEY=sk-your-api-key
```

#### 运行穿刺

```bash
# 基本用法
./scripts/run/locagent_piercer.sh <repo_url> <config.json> [output_dir]

# 示例1: 对libcare项目进行穿刺
./scripts/run/locagent_piercer.sh \
  https://github.com/cloudlinux/libcare \
  ./configs/libcare_piercing.json \
  ./results

# 示例2: 对UXARRAY项目进行穿刺
./scripts/run/locagent_piercer.sh \
  https://github.com/UXARRAY/uxarray \
  ./configs/uxarray_piercing.json \
  ./results/uxarray
```

### 方式2: 使用Docker Compose

```bash
# 设置环境变量
export LITELLM_API_KEY=sk-your-api-key
export REPO_URL=https://github.com/cloudlinux/libcare
export CONFIG_FILE=libcare_piercing.json

# 启动服务
cd docker
docker-compose up

# 查看结果
ls -la ../results/
```

### 方式3: 直接使用Python脚本

```bash
export LITELLM_BASE_URL=https://llm-proxy.app.all-hands.dev
export LITELLM_API_KEY=sk-your-api-key
export PYTHONPATH=/workspaces/LocAgent:$PYTHONPATH

python scripts/run/locagent_piercer.py \
  --repo_url https://github.com/cloudlinux/libcare \
  --config_file ./configs/libcare_piercing.json \
  --output_dir ./results
```

## 配置文件格式

JSON配置文件用于定义穿刺任务。示例：

```json
{
  "repo_url": "https://github.com/cloudlinux/libcare",
  "repo_name": "libcare",
  "dataset_name": "libcare_custom",
  "model": "litellm_proxy/claude-sonnet-4-20250514",
  "eval_n_limit": 1,
  "num_processes": 1,
  "use_function_calling": true,
  "simple_desc": true,
  "queries": [
    {
      "query": "How does libcare apply patches to a running process?",
      "category": "patch_application"
    }
  ]
}
```

### 配置参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `repo_url` | 字符串 | GitHub仓库URL（必需） |
| `repo_name` | 字符串 | 仓库名称 |
| `dataset_name` | 字符串 | 数据集名称 |
| `model` | 字符串 | LLM模型ID（默认：claude-sonnet-4-20250514） |
| `eval_n_limit` | 整数 | 评估的任务数量限制 |
| `num_processes` | 整数 | 并行进程数 |
| `use_function_calling` | 布尔 | 是否使用函数调用 |
| `simple_desc` | 布尔 | 使用简化的函数描述 |
| `queries` | 数组 | 穿刺查询列表 |

## 输出结果

穿刺完成后，结果保存在JSON文件中：

```json
{
  "timestamp": "2025-12-06T17:53:16.123456",
  "repo_url": "https://github.com/cloudlinux/libcare",
  "model": "litellm_proxy/claude-sonnet-4-20250514",
  "queries": [
    {
      "query": "How does libcare apply patches?",
      "retrieved_codes": [...],
      "analysis": "Based on the code analysis...",
      "status": "success"
    }
  ]
}
```

## 支持的语言

- Python
- Java  
- C/C++ ✨ (新增)

## Docker镜像

### 构建镜像

```bash
docker build -f docker/Dockerfile -t locagent:latest .
```

### 运行容器

```bash
docker run --rm \
  -v $(pwd)/configs:/app/configs \
  -v $(pwd)/results:/app/results \
  -e LITELLM_BASE_URL=https://llm-proxy.app.all-hands.dev \
  -e LITELLM_API_KEY=sk-your-api-key \
  locagent:latest \
  scripts/run/locagent_piercer.py \
  --repo_url https://github.com/cloudlinux/libcare \
  --config_file /app/configs/libcare_piercing.json \
  --output_dir /app/results
```

## 故障排查

### 问题1: 找不到配置文件

```
错误：配置文件不存在
```

解决方案：确保配置文件路径正确，使用绝对路径或相对路径

### 问题2: API密钥无效

```
LiteLLM API调用失败
```

解决方案：检查环境变量设置

```bash
echo $LITELLM_BASE_URL
echo $LITELLM_API_KEY
```

### 问题3: 仓库克隆失败

```
git clone 出错
```

解决方案：
- 检查网络连接
- 检查仓库URL是否正确
- 确认对仓库的访问权限

## 扩展配置

### 创建自定义配置

```bash
cat > configs/my_project.json << 'EOF'
{
  "repo_url": "https://github.com/your-org/your-repo",
  "model": "litellm_proxy/claude-sonnet-4-20250514",
  "queries": [
    {"query": "What is the main entry point?"},
    {"query": "How does authentication work?"},
    {"query": "What are the key data structures?"}
  ]
}
EOF
```

### 使用自定义配置运行

```bash
./scripts/run/locagent_piercer.sh \
  https://github.com/your-org/your-repo \
  ./configs/my_project.json
```

## 性能优化

### 调整并行进程数

在JSON配置中修改：

```json
{
  "num_processes": 4
}
```

### 限制评估任务数

```json
{
  "eval_n_limit": 5
}
```

## 许可证

MIT

## 相关文档

- [LocAgent主项目](https://github.com/gersteinlab/LocAgent)
- [配置示例](./configs/)
