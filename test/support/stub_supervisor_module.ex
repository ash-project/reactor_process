# SPDX-FileCopyrightText: 2025 reactor_process contributors <https://github.com/ash-project/reactor_process/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule Support.StubSupervisorModule do
  @moduledoc false

  @doc false
  def start_child(_supervisor, _child_spec), do: {:error, {:refused_by, __MODULE__}}
end
