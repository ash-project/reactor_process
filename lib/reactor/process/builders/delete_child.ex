defimpl Reactor.Dsl.Build, for: Reactor.Process.Dsl.DeleteChild do
  @moduledoc false
  alias Reactor.{Argument, Builder, Template}
  require Template

  @doc false
  @impl true
  def build(step, reactor) do
    arguments =
      case step.supervisor do
        template when Template.is_template(template) ->
          [
            Argument.from_template(:supervisor, template),
            Argument.from_template(:child_id, step.child_id) | step.arguments
          ]

        supervisor ->
          [
            Argument.from_value(:supervisor, supervisor),
            Argument.from_template(:child_id, step.child_id) | step.arguments
          ]
      end

    Builder.add_step(
      reactor,
      step.name,
      {Reactor.Process.Step.DeleteChild, module: step.module},
      arguments,
      guards: step.guards,
      ref: :step_name
    )
  end

  @doc false
  @impl true
  def verify(_, _), do: :ok
end
