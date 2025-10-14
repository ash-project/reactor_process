# SPDX-FileCopyrightText: 2025 reactor_process contributors <https://github.com/ash-project/reactor_process/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Support.StubServer do
  @moduledoc false
  use GenServer, restart: :transient

  def start_link(args), do: GenServer.start_link(__MODULE__, args)
  @doc false
  @impl true
  def init(options) do
    case options[:on_init] do
      fun when is_function(fun, 0) -> fun.()
      result -> result
    end
  end
end
