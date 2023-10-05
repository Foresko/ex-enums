defmodule Enums do
  @moduledoc false

  defmodule UndefinedEnumValueError do
    @moduledoc false

    defexception [:enum, :value]

    @type t() :: %__MODULE__{enum: module(), value: String.t()}

    @impl Exception
    def message(%__MODULE__{} = error) do
      "value `#{error.value}` is not defined in enum #{error.enum |> Atom.to_string() |> String.replace_prefix("Elixir.", "")}"
    end
  end

  defmacro __using__(params) do
    quote location: :keep, generated: true, bind_quoted: [params: params], unquote: false do
      values = Keyword.fetch!(params, :values)

      unless Enum.count(values) > 0 do
        raise ArgumentError, "values can not be empty"
      end

      unless Enum.all?(values, &is_atom/1) do
        raise ArgumentError, "values should be atoms"
      end

      unless values |> Enum.uniq() |> Enum.count() == Enum.count(values) do
        raise ArgumentError, "values must not be repeated"
      end

      @type t() :: unquote(values |> Enum.reverse() |> Enum.reduce(&{:|, [], [&1, &2]}))

      Enum.map(
        values,
        fn value ->
          defmacro unquote(value)(), do: unquote(value)
        end
      )

      @spec parse(String.t()) :: {:ok, t()} | {:error, Enums.UndefinedEnumValueError.t()}
      def parse(value)

      Enum.map(
        values,
        fn value ->
          def parse(unquote(Atom.to_string(value))), do: {:ok, unquote(value)}
        end
      )

      def parse(value),
        do: {:error, %Enums.UndefinedEnumValueError{enum: __MODULE__, value: value}}

      @spec parse!(String.t()) :: t()
      def parse!(value)

      Enum.map(
        values,
        fn value ->
          def parse!(unquote(Atom.to_string(value))), do: unquote(value)
        end
      )

      def parse!(value) do
        raise UndefinedEnumValueError, enum: __MODULE__, value: value
      end

      @spec to_string(t()) :: String.t()
      def to_string(value)

      Enum.map(
        values,
        fn value ->
          def to_string(unquote(value)), do: unquote(Atom.to_string(value))
        end
      )

      @spec values() :: list(t())
      def values(), do: unquote(values)
    end
  end
end
