# SPDX-FileCopyrightText: 2025 reactor_process contributors <https://github.com/ash-project/reactor_process/graphs/contributors>
#
# SPDX-License-Identifier: MIT

import Config

config :spark, formatter: [remove_parens?: true]

config :git_ops,
  mix_project: Reactor.Process.MixProject,
  github_handle_lookup?: true,
  changelog_file: "CHANGELOG.md",
  repository_url: "https://github.com/ash-project/reactor_process",
  manage_mix_version?: true,
  manage_readme_version: true,
  version_tag_prefix: "v"
