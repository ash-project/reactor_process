defimpl Reactor.Dsl.Build, for: Reactor.Process.Dsl.StartChild do
  @moduledoc false
  alias Reactor.{Argument, Builder, Template}
  require Template

  @doc false
  @impl true
  def build(step, reactor) do
    supervisor =
      if Template.is_template(step.supervisor) do
        Argument.from_template(:supervisor, step.supervisor)
      else
        Argument.from_value(:supervisor, step.supervisor)
      end

    child_spec =
      if Template.is_template(step.child_spec.source) do
        Argument.from_template(:child_spec, step.child_spec.source, step.child_spec.transform)
      else
        Argument.from_value(:child_spec, step.child_spec.source, step.child_spec.transform)
      end

    arguments = [supervisor, child_spec | step.arguments]

    opts =
      if step.terminate_on_undo? do
        [
          terminate_on_undo?: true,
          termination_reason: step.termination_reason,
          termination_timeout: step.termination_timeout
        ]
      else
        [terminate_on_undo?: false]
      end
      |> Enum.concat(
        fail_on_already_present?: step.fail_on_already_present?,
        fail_on_already_started?: step.fail_on_already_started?
      )

    Builder.add_step(
      reactor,
      step.name,
      {Reactor.Process.Step.StartChild, opts},
      arguments,
      guards: step.guards,
      ref: :step_name
    )
  end

  @doc false
  @impl true
  def verify(_, _), do: :ok
end
