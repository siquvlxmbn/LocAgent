#!/usr/bin/env python3
"""
LocAgent 代码穿刺工具
用于对任意项目进行代码定位分析
"""

import argparse
import json
import os
import sys
import logging
from pathlib import Path
from datetime import datetime

# 设置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_config(config_file: str) -> dict:
    """加载配置文件"""
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        logger.info(f"✅ 配置文件加载成功: {config_file}")
        return config
    except Exception as e:
        logger.error(f"❌ 配置文件加载失败: {e}")
        sys.exit(1)


def validate_config(config: dict) -> bool:
    """验证配置文件"""
    required_fields = ['repo_url', 'model', 'queries']
    
    for field in required_fields:
        if field not in config:
            logger.error(f"❌ 配置缺少必需字段: {field}")
            return False
    
    logger.info("✅ 配置文件验证通过")
    return True


def clone_and_index_repo(repo_url: str, repo_dir: str, index_dir: str) -> bool:
    """克隆仓库并构建索引"""
    try:
        import subprocess
        
        # 克隆仓库
        if not os.path.exists(repo_dir):
            logger.info(f"📥 克隆仓库: {repo_url}")
            subprocess.run(['git', 'clone', repo_url, repo_dir], check=True)
        else:
            logger.info(f"✅ 仓库已存在: {repo_dir}")
        
        # 构建BM25索引
        from plugins.location_tools.retriever.bm25_retriever import build_code_retriever_from_repo
        
        logger.info(f"🔨 构建BM25索引...")
        retriever = build_code_retriever_from_repo(
            repo_dir, 
            persist_path=index_dir,
            show_progress=True
        )
        logger.info(f"✅ 索引构建完成: {index_dir}")
        return True
        
    except Exception as e:
        logger.error(f"❌ 索引构建失败: {e}")
        return False


def run_piercing(config: dict, index_dir: str, output_dir: str) -> dict:
    """执行穿刺分析"""
    try:
        import litellm
        from plugins.location_tools.retriever.bm25_retriever import build_retriever_from_persist_dir
        
        # 配置LiteLLM
        litellm.base_url = os.environ.get('LITELLM_BASE_URL', 'https://llm-proxy.app.all-hands.dev')
        litellm.api_key = os.environ.get('LITELLM_API_KEY', '')
        
        if not litellm.api_key:
            logger.error("❌ 未设置LITELLM_API_KEY环境变量")
            return {}
        
        logger.info(f"🔍 加载索引...")
        retriever = build_retriever_from_persist_dir(index_dir)
        
        results = {
            "timestamp": datetime.now().isoformat(),
            "repo_url": config.get('repo_url'),
            "model": config.get('model'),
            "queries": []
        }
        
        model = config.get('model', 'litellm_proxy/claude-sonnet-4-20250514')
        queries = config.get('queries', [])
        
        for i, query_item in enumerate(queries, 1):
            query = query_item if isinstance(query_item, str) else query_item.get('query', '')
            logger.info(f"\n【查询 {i}/{len(queries)}】{query[:60]}...")
            
            try:
                # 检索相关代码
                docs = retriever.retrieve(query)
                context_texts = []
                for j, doc in enumerate(docs[:5]):
                    text = getattr(doc, 'node_text', None) or getattr(doc, 'text', None) or str(doc)
                    context_texts.append(f"代码片段{j+1}:\n{text}\n")
                
                full_context = '\n'.join(context_texts)
                
                # 调用LLM分析
                prompt = f"""你是一个资深的代码分析师。

用户问题: {query}

以下是从项目中检索到的相关代码片段：

{full_context}

请基于这些代码片段，详细回答用户的问题。"""
                
                logger.info(f"  📤 调用LLM模型: {model}")
                response = litellm.completion(
                    model=model,
                    messages=[
                        {'role': 'system', 'content': '你是一个资深的代码分析专家'},
                        {'role': 'user', 'content': prompt}
                    ],
                    temperature=0.7,
                    max_tokens=1000
                )
                
                answer = response.choices[0].message.content
                
                query_result = {
                    "query": query,
                    "retrieved_codes": context_texts,
                    "analysis": answer,
                    "status": "success"
                }
                
                logger.info(f"  ✅ 分析完成")
                
            except Exception as e:
                logger.warning(f"  ⚠️  LLM调用失败: {e}，仅返回检索结果")
                query_result = {
                    "query": query,
                    "retrieved_codes": context_texts,
                    "analysis": None,
                    "status": "retrieval_only",
                    "error": str(e)
                }
            
            results["queries"].append(query_result)
        
        return results
        
    except Exception as e:
        logger.error(f"❌ 穿刺失败: {e}")
        import traceback
        traceback.print_exc()
        return {}


def save_results(results: dict, output_dir: str) -> str:
    """保存结果"""
    os.makedirs(output_dir, exist_ok=True)
    
    output_file = os.path.join(output_dir, f"piercing_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    logger.info(f"✅ 结果已保存: {output_file}")
    return output_file


def main():
    parser = argparse.ArgumentParser(description='LocAgent 代码穿刺工具')
    parser.add_argument('--repo_url', required=True, help='GitHub仓库URL')
    parser.add_argument('--config_file', required=True, help='配置文件路径')
    parser.add_argument('--output_dir', default='./results', help='输出目录')
    parser.add_argument('--repo_dir', default='/tmp/locagent_repo', help='仓库克隆目录')
    parser.add_argument('--index_dir', default='/tmp/locagent_index', help='索引目录')
    
    args = parser.parse_args()
    
    logger.info("="*60)
    logger.info("LocAgent 代码穿刺工具启动")
    logger.info("="*60)
    
    # 加载配置
    config = load_config(args.config_file)
    
    # 验证配置
    if not validate_config(config):
        sys.exit(1)
    
    # 克隆仓库并构建索引
    if not clone_and_index_repo(args.repo_url, args.repo_dir, args.index_dir):
        sys.exit(1)
    
    # 执行穿刺
    results = run_piercing(config, args.index_dir, args.output_dir)
    
    # 保存结果
    if results:
        save_results(results, args.output_dir)
        logger.info("✅ 穿刺完成")
    else:
        logger.error("❌ 穿刺失败")
        sys.exit(1)


if __name__ == '__main__':
    main()
