locals_without_parens = [factory: 1, factory: 2]

[
  import_deps: [:ecto, :ecto_sql],
  hocals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  subdirectories: ["priv/*/migrations"],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}", "priv/*/seeds.exs"]
]
