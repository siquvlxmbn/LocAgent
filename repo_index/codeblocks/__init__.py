from typing import Optional

from repo_index.codeblocks.parser.java import JavaParser
from repo_index.codeblocks.parser.parser import CodeParser
from repo_index.codeblocks.parser.python import PythonParser
from repo_index.codeblocks.parser.c import CParser


def supports_codeblocks(path: str):
    return any(
        [
            path.endswith('.py'),
            path.endswith('.java'),
            path.endswith('.c'),
            path.endswith('.h'),
        ]
    )


def get_parser_by_path(file_path: str) -> Optional[CodeParser]:
    if file_path.endswith('.py'):
        return PythonParser()
    elif file_path.endswith('.java'):
        return JavaParser()
    elif file_path.endswith('.c') or file_path.endswith('.h'):
        return CParser()
    else:
        return None
