defmodule Reactor.Process.Dsl.ChildSpec do
  @moduledoc """
  The `child_spec` DSL entity for the `Reactor.Process` DSL extension.
  """

  alias Reactor.{Dsl.Argument, Template}

  defstruct __identifier__: nil,
            description: nil,
            source: nil,
            transform: nil

  @type t :: %__MODULE__{
          __identifier__: any,
          description: nil | String.t(),
          source: Template.t() | Supervisor.module_spec(),
          transform: nil | (any -> Supervisor.module_spec()) | {module, keyword} | mfa
        }

  @doc false
  def __entity__,
    do: %Spark.Dsl.Entity{
      name: :child_spec,
      describe: """
      Specifies a child spec as used by a supervisor.
      """,
      examples: [
        """
        child_spec {Supervisor, name: __MODULE__.Supervisor}
        """,
        """
        child_spec input(:initial_value) do
          transform fn initial_value ->
            fn -> initial_value end
          end
        end
        """
      ],
      args: [:source],
      target: __MODULE__,
      identifier: {:auto, :unique_integer},
      imports: [Argument],
      schema: [
        source: [
          type: {:or, [Template.type(), {:tuple, [:module, :keyword_list]}, :module]},
          required: true,
          doc: "The child spec"
        ],
        description: [
          type: :string,
          required: false,
          doc: "An optional description for the child spec"
        ],
        transform: [
          type: {:or, [{:spark_function_behaviour, Step, {Step.Transform, 1}}, nil]},
          required: false,
          default: nil,
          doc: """
          An optional transformation function which can be used to modify the child spec before it is passed to the step.
          """
        ]
      ]
    }
end
