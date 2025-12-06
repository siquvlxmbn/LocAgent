from tree_sitter_languages import get_language

from repo_index.codeblocks.parser.parser import CodeParser


class CParser(CodeParser):
    def __init__(self, **kwargs):
        language = get_language('c')
        super().__init__(language, **kwargs)
        self.queries = []
        self.queries.extend(self._build_queries('c.scm'))
        self.gpt_queries = []

    @property
    def language(self):
        return 'c'
