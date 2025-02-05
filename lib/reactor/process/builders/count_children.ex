defimpl Reactor.Dsl.Build, for: Reactor.Process.Dsl.CountChildren do
  @moduledoc false
  alias Reactor.{Argument, Builder, Template}
  require Template

  @doc false
  @impl true
  def build(step, reactor) do
    arguments =
      case step.supervisor do
        template when Template.is_template(template) ->
          [Argument.from_template(:supervisor, template) | step.arguments]

        supervisor ->
          [Argument.from_value(:supervisor, supervisor) | step.arguments]
      end

    Builder.add_step(
      reactor,
      step.name,
      {Reactor.Process.Step.CountChildren, module: step.module},
      arguments,
      guards: step.guards,
      ref: :step_name
    )
  end

  @doc false
  @impl true
  def verify(_, _), do: :ok
end
