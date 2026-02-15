# SPDX-FileCopyrightText: 2025 reactor_process contributors <https://github.com/ash-project/reactor_process/graphs/contributors>
#
# SPDX-License-Identifier: MIT

# Used by "mix format"
spark_locals_without_parens = [
  child_id: 1,
  child_spec: 1,
  child_spec: 2,
  count_children: 1,
  count_children: 2,
  delete_child: 1,
  delete_child: 2,
  description: 1,
  fail_on_already_present?: 1,
  fail_on_already_started?: 1,
  fail_on_ignore?: 1,
  fail_on_not_found?: 1,
  guard: 1,
  guard: 2,
  module: 1,
  process: 1,
  process_exit: 1,
  process_exit: 2,
  reason: 1,
  restart_child: 1,
  restart_child: 2,
  restart_on_undo?: 1,
  start_child: 1,
  start_child: 2,
  start_link: 1,
  start_link: 2,
  supervisor: 1,
  terminate_child: 1,
  terminate_child: 2,
  terminate_on_undo?: 1,
  termination_reason: 1,
  termination_timeout: 1,
  timeout: 1,
  transform: 1,
  wait_for: 1,
  wait_for: 2,
  wait_for_exit?: 1,
  where: 1,
  where: 2
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
