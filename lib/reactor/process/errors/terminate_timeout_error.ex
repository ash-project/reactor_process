# SPDX-FileCopyrightText: 2025 reactor_process contributors <https://github.com/ash-project/reactor_process/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Reactor.Process.Errors.TerminateTimeoutError do
  @moduledoc """
  This exception is returned when a process failed to terminate within the time
  allotted.
  """
  use Reactor.Error, fields: [:process, :step, :timeout], class: :invalid
  import Reactor.Error.Utils

  @type t :: Exception.t()

  @doc false
  @impl true
  def message(error) do
    """
    # Terminate Timeout Error

    #{@moduledoc}

    ## `process`

    #{describe_error(error.process)}

    ## `timeout`

    #{error.timeout} ms

    ## `step`

    #{describe_error(error.step)}
    """
  end
end
