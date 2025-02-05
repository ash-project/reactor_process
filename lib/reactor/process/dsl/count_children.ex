defmodule Reactor.Process.Dsl.CountChildren do
  @moduledoc """
  A `count_children` DSL entity for the `Reactor.Process` DSL extension.
  """
  alias Reactor.{Dsl.Argument, Dsl.Guard, Dsl.WaitFor, Dsl.Where, Template}

  defstruct __identifier__: nil,
            arguments: [],
            description: nil,
            guards: [],
            name: nil,
            supervisor: nil,
            module: Supervisor

  @type t :: %__MODULE__{
          __identifier__: any,
          arguments: [Argument.t()],
          description: nil | String.t(),
          guards: [Reactor.Guard.Build.t()],
          module: module,
          name: any,
          supervisor: Template.t() | Supervisor.supervisor()
        }

  @doc false
  def __entity__,
    do: %Spark.Dsl.Entity{
      name: :count_children,
      describe: """
      Returns information about a Supervisor's children.

      See the documentation for `Supervisor.count_children/1` for more information.
      """,
      examples: [
        """
        start_link :supervisor do
          child_spec value({Supervisor, strategy: :one_for_one}
        end

        count_children :children do
          supervisor result(:supervisor)
        end
        """
      ],
      target: __MODULE__,
      identifier: :name,
      args: [:name],
      recursive_as: :steps,
      entities: [
        arguments: [WaitFor.__entity__()],
        guards: [Guard.__entity__(), Where.__entity__()]
      ],
      imports: [Argument],
      schema: [
        name: [
          type: :atom,
          required: true,
          doc:
            "A unique name for the step. Used when choosing the return value of the Reactor and for arguments into other steps"
        ],
        description: [
          type: :string,
          required: false,
          doc: "An optional description for the step"
        ],
        supervisor: [
          type:
            {:or,
             [
               Template.type(),
               :pid,
               :atom,
               {:tuple, [{:literal, :global}, :any]},
               {:tuple, [{:literal, :via}, :module, :any]},
               {:tuple, [:atom, :atom]}
             ]},
          required: true,
          doc: "The supervisor to query"
        ],
        module: [
          type: :module,
          required: false,
          default: Supervisor,
          doc: "The module to use. Must export `count_children/1`"
        ]
      ]
    }
end
