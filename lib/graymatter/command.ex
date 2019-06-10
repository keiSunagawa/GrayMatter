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

defmodule Graymatter.Command do
  import Algae
  import Graymatter.Command.Internal

  defmacro defcommand(name, do: define) do
    #IO.inspect(name)
    #IO.inspect(define)

    {:__aliases__, _, atmname} = name
    fname = Algae.Internal.module_to_field(atmname)

    nextv = define |> get_next_type() |> next_to_value()
    {_, _, _, args, _} = case define do
                           {:__block__, _, lines} ->  Algae.Internal.module_elements(lines, __CALLER__)
                           line ->  Algae.Internal.module_elements([line], __CALLER__)
                         end
    fargs = Enum.take(args, length(args) - 1)
    fparams = Enum.map(fargs, fn {_, _, [var|_]} -> var end)
    #IO.inspect(args)
    #IO.inspect(fargs)
    quote do
      defdata unquote(name), do: unquote(define)

      def unquote(fname)(unquote_splicing(fargs)) do
        unquote(name).new(unquote_splicing(fparams), unquote(nextv))
        |> Graymatter.Coyoneda.lift()
        |> Algae.Free.free()
      end
    end
  end

  defmacro __using__(_opts) do
    # import coyoneda and free
  end
end
