defmodule Reactor.Process.Errors.TerminateTimeoutError do
  @moduledoc """
  This exception is returned when a process failed to terminate within the time
  allotted.
  """
  use Reactor.Error, fields: [:process, :step, :timeout], class: :invalid
  import Reactor.Error.Utils

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
