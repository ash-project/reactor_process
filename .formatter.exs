# Used by "mix format"
spark_locals_without_parens = [
  child_id: 1,
  description: 1,
  fail_on_already_present?: 1,
  fail_on_already_started?: 1,
  fail_on_ignore?: 1,
  fail_on_not_found?: 1,
  module: 1,
  process: 1,
  reason: 1,
  restart_on_undo?: 1,
  supervisor: 1,
  terminate_on_undo?: 1,
  termination_reason: 1,
  termination_timeout: 1,
  timeout: 1,
  transform: 1,
  wait_for_exit?: 1
]

[
  import_deps: [:reactor, :spark],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [Spark.Formatter],
  locals_without_parens: spark_locals_without_parens,
  export: [
    locals_without_parens: spark_locals_without_parens
  ]
]
