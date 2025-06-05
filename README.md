<img src="https://github.com/ash-project/reactor/blob/main/logos/reactor-logo-light-small.png?raw=true#gh-light-mode-only" alt="Logo Light" width="250">
<img src="https://github.com/ash-project/reactor/blob/main/logos/reactor-logo-dark-small.png?raw=true#gh-dark-mode-only" alt="Logo Dark" width="250">

# Reactor.Process

[![Build Status](https://github.com/ash-project/reactor_process/actions/workflows/elixir.yml/badge.svg)](https://github.com/ash-project/reactor/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hex version badge](https://img.shields.io/hexpm/v/reactor_process.svg)](https://hex.pm/packages/reactor_process)

A [Reactor](https://github.com/ash-project/reactor) extension that provides steps for working with supervisors and processes.

## Example

The following example uses Reactor to start a supervisor and add children to it.

```elixir
defmodule StartAllReposReactor do
  use Reactor, extensions: [Reactor.Process]

  start_supervisor :supervisor

  step :all_repos do
    run fn _ ->
      Application.get_env(:my_app, :ecto_repos)
    end
  end

  map :migrate_all_repos do
    source result(:all_repos)

    step :migrate do
      argument :repo, element(:migrate_all_repos)
      run &migrate_repo/2
    end

    start_child :start_child do
      supervisor result(:supervisor)
      child_spec element(:migrate_all_repos)
    end
  end

  return :supervisor

  defp migrate_repo(args, _context) do
    Ecto.Migrator.with_repo(args.repo, fn repo ->
      with :ok <- repo_create(repo) do
        Ecto.Migrator.run(repo, :up, all: true)
        {:ok, repo}
      end
    end)
  end

  defp repo_create(repo) do
    case repo.__adapter__().storage_up(repo.config()) do
      :ok -> :ok
      {:error, :already_up} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end

Reactor.run!(StartAllReposReactor, %{directory: "./to_reverse"})
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `reactor_process` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:reactor_process, "~> 0.18.0"}
  ]
end
```

Documentation for the latest release is available on [HexDocs](https://hexdocs.pm/reactor_process).

## Licence

This software is licensed under the terms of the MIT License.
See the `LICENSE` file included with this package for the terms.
