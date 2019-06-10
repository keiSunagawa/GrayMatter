defmodule Graymatter.Command.Internal do
  def get_next_type({:__block__, _, args}) do
    next = Enum.find(args, fn ast ->
      case ast do
        {:::, _, [{:next, _, _}|_]} -> true
        _ -> false
      end
    end)
    get_next_type(next)
  end

  def get_next_type(ast) do
    {:::, _, [{:next, _, _}|tail]} = ast
    tail
    |> Enum.reverse()
    |> hd()
  end

  def next_to_value({:any, _, _}) do
    quote do: %Witchcraft.Unit{}
  end
  def next_to_value(_) do
    quote do: &Quark.id/1
  end
end

# TODO error handling
defmodule Graymatter.Command do
  import Algae
  import Graymatter.Command.Internal

  defmacro defcommand(name, do: define) do
    {:__aliases__, _, atmname} = name
    fname = Algae.Internal.module_to_field(atmname)

    nextv = define |> get_next_type() |> next_to_value()
    {_, _, _, args, _} = case define do
                           {:__block__, _, lines} ->  Algae.Internal.module_elements(lines, __CALLER__)
                           line ->  Algae.Internal.module_elements([line], __CALLER__)
                         end
    fargs = Enum.take(args, length(args) - 1)
    fparams = Enum.map(fargs, fn {_, _, [var|_]} -> var end)
    quote do
      defdata unquote(name), do: unquote(define)

      def unquote(fname)(unquote_splicing(fargs)) do
        unquote(name).new(unquote_splicing(fparams), unquote(nextv))
        |> Graymatter.Coyoneda.lift()
        |> Algae.Free.free()
      end
    end
  end

  defmacro defhandler(apply, do: patterns) do
    combinetor = quote do: (Quark.Compose.compose(&interpreter/1, f))
    ast = Enum.map(patterns, fn p ->
      with {:->, l, [left, right]} <- p do
        r2 = {:>>>, [context: Elixir, import: Witchcraft.Chain], [right, combinetor]}
        {:->, l, [left, r2]}
      end
    end)
    quote do
      def interpreter(%Algae.Free.Roll{roll: %Graymatter.Coyoneda{f: f, m: m}}) do
        case m do
          unquote(ast)
        end
      end
      def interpreter(%Algae.Free.Pure{pure: a}), do: unquote(apply).(a)
    end
  end
  # defmacro __using__(_opts) do

  # end
end
