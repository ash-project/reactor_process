defimpl Reactor.Dsl.Build, for: Reactor.Process.Dsl.ProcessExit do
  @moduledoc false
  alias Reactor.{Argument, Builder, Template}
  require Template

  @doc false
  @impl true
  def build(step, reactor) do
    timeout =
      case step.timeout do
        timeout when Template.is_template(timeout) ->
          Argument.from_template(:timeout, timeout)

        :infinity ->
          Argument.from_value(:timeout, :infinity)

        timeout when is_integer(timeout) and timeout >= 0 ->
          Argument.from_value(:timeout, timeout)
      end

    arguments = [
      Argument.from_template(:process, step.process),
      Argument.from_template(:reason, step.reason),
      timeout | step.arguments
    ]

    Builder.add_step(
      reactor,
      step.name,
      {Reactor.Process.Step.ProcessExit, wait_for_exit?: step.wait_for_exit?},
      arguments,
      guards: step.guards,
      ref: :step_name
    )
  end

  @doc false
  @impl true
  def verify(_, _), do: :ok
end
