(translation_unit . (_) @child.first @definition.module) @root

(function_definition
  declarator: (function_declarator
    declarator: (identifier) @identifier
  )
  body: (compound_statement
    "{" @child.first
  )
) @root @definition.function

(struct_specifier
  name: (type_identifier) @identifier
  body: (field_declaration_list
    "{" @child.first
  )
) @root @definition.class

(struct_specifier
  body: (field_declaration_list
    "{" @child.first
  )
) @root @definition.class

(preproc_include) @root @definition.import

(comment) @root @definition.comment

(compound_statement
  "{" @child.first
) @root @definition.statement
