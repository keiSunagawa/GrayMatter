defmodule KVS do
  import Graymatter.Command
  defcommand Put do
    key :: String.t()
    value :: non_neg_integer()
    next :: any()
  end
  defcommand Get do
    key :: String.t()
    next :: (non_neg_integer() -> any())
  end
  defcommand SafeModify do
    key :: String.t()
    value :: non_neg_integer()
    next ::  (boolean() -> any())
  end
end

defmodule KVS.Inmemory do
  alias Algae.Free.{Roll, Pure}
  alias Algae.State
  import Witchcraft.Chain
  import Quark.Compose

  def interpreter(%Roll{roll: %Graymatter.Coyoneda{f: f, m: m}}) do
    case m do
      %KVS.Put{key: k, value: v, next: n} ->
        State.state(fn st ->  {n, Map.put(st, k, v)} end)
        >>> ((&interpreter/1) <|> f)
      %KVS.Get{key: k, next: nf} ->
        State.state(fn st ->
          {_, v} = Map.fetch(st, k)
          {nf.(v), st}
        end) >>> ((&interpreter/1) <|> f)
      %KVS.SafeModify{key: k, value: v, next: nf} ->
        State.state(fn st ->
          case  Map.fetch(st, k) do
            {:ok, _} -> {nf.(false), st}
            _ -> {nf.(true), Map.put(st, k, v)}
          end
        end) >>> ((&interpreter/1) <|> f)
    end
  end
  def interpreter(%Pure{pure: a}) do
    IO.inspect(a)
    State.state(fn st ->  {a, st} end)
  end
end

defmodule Examples do
  import KVS
  import Witchcraft.Chain
  def run do
    m = chain do
      put("a", 1)
      o <- get("a")
      a <- safemodify("a", 2)
      let _ = log([o, a])
      get("a")
    end

    KVS.Inmemory.interpreter(m).runner.(%{})
  end

  def log(xs), do: IO.inspect(xs)
end
