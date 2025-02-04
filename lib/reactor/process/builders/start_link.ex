defimpl Reactor.Dsl.Build, for: Reactor.Process.Dsl.StartLink do
  @moduledoc false
  alias Reactor.{Argument, Builder, Template}
  require Template

  @doc false
  @impl true
  def build(step, reactor) do
    arguments =
      if Template.is_template(step.child_spec.source) do
        [
          Argument.from_template(:child_spec, step.child_spec.source, step.child_spec.transform)
          | step.arguments
        ]
      else
        [
          Argument.from_value(:child_spec, step.child_spec.source, step.child_spec.transform)
          | step.arguments
        ]
      end

    impl =
      if step.terminate_on_undo? do
        {Reactor.Process.Step.StartLink,
         fail_on_already_started?: step.fail_on_already_started?,
         fail_on_ignore?: step.fail_on_ignore?,
         terminate_on_undo?: true,
         termination_reason: step.termination_reason,
         termination_timeout: step.termination_timeout}
      else
        {Reactor.Process.Step.StartLink,
         fail_on_already_started?: step.fail_on_already_started?,
         fail_on_ignore?: step.fail_on_ignore?,
         terminate_on_undo?: false}
      end

    Builder.add_step(
      reactor,
      step.name,
      impl,
      arguments,
      guards: step.guards,
      ref: :step_name,
      async?: false
    )
  end

  @doc false
  @impl true
  def verify(_, _), do: :ok
end
