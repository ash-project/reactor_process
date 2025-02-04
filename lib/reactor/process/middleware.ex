defmodule Reactor.Process.Middleware do
  @moduledoc """
  A Reactor middleware which records the pid of the original starting process.
  """
  use Reactor.Middleware

  @doc false
  @impl true
  def init(context) do
    {:ok, Map.put(context, __MODULE__, %{pid: self()})}
  end
end
