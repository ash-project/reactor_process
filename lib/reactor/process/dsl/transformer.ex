defmodule Reactor.Process.Dsl.Transformer do
  @moduledoc false
  alias Spark.Dsl.Transformer
  use Transformer

  @doc false
  @impl true
  def before?(Reactor.Dsl.Transformer), do: true
  def before?(_), do: false

  @doc false
  @impl true
  def transform(dsl_state) do
    with {:ok, middleware} <-
           Transformer.build_entity(Reactor.Dsl, [:reactor, :middlewares], :middleware,
             module: Reactor.Process.Middleware
           ) do
      dsl_state =
        dsl_state
        |> Transformer.add_entity([:reactor, :middlewares], middleware)

      {:ok, dsl_state}
    end
  end
end
