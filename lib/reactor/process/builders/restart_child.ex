# SPDX-FileCopyrightText: 2025 James Harton
#
# SPDX-License-Identifier: MIT

defimpl Reactor.Dsl.Build, for: Reactor.Process.Dsl.RestartChild do
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

    child_id = Argument.from_template(:child_id, step.child_id)

    arguments = [supervisor, child_id | step.arguments]

    Builder.add_step(
      reactor,
      step.name,
      {Reactor.Process.Step.RestartChild, module: step.module},
      arguments,
      guards: step.guards,
      ref: :step_name
    )
  end

  @doc false
  @impl true
  def verify(step, dsl_state) do
    if function_exported?(step.module, :restart_child, 2) do
      :ok
    else
      {:error,
       Spark.Error.DslError.exception(
         module: Spark.Dsl.Verifier.get_persisted(dsl_state, :module),
         path: [:reactor, :restart_child, step.name],
         message: """
         # Supervisor Cannot Restart

         The module `#{inspect(step.module)}` does not export the
         `restart_child/2` function, therefore the `restart_child` cannot be
         used.
         """
       )}
    end
  end
end
