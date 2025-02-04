defmodule Reactor.Process.Errors.MissingMiddlewareError do
  @moduledoc """
  This exception is returned when a step wishes to access the owning PID but the
  `Reactor.Process.Middleware` middleware has not been added to the reactor.
  """
  use Reactor.Error, fields: [:step, :message], class: :invalid
  import Reactor.Error.Utils

  @doc false
  @impl true
  def message(error) do
    """
    # Missing Middleware Error

    #{@moduledoc}

    ## `message`

    #{describe_error(error.message)}

    ## `step`

    #{describe_error(error.step)}
    """
  end
end
