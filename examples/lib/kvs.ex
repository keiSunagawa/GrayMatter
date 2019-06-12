defmodule KVS do
  import Graymatter.Command
  alias Algae.Maybe
  alias Algae.Free

  defcommand Put do
    key :: String.t()
    value :: non_neg_integer()
    next :: any()
  end
  defcommand Get do
    key :: String.t()
    next :: (Maybe.t() -> any())
  end

  def pure(a), do: Free.new(a)

  import Witchcraft.Chain

  def safe_modify(key, value) do
    chain do
      v <- get(key)
      let p = (case v do
             %Maybe.Just{just: _} -> false
             %Maybe.Nothing{} -> true
           end)
      if p, do: put(key, value), else: pure(nil)
      pure(p)
    end
  end
end

defmodule KVS.Inmemory do
  alias Algae.State
  alias Algae.Maybe
  import Graymatter.Command

  # Free ~> State
  defhandler fn v -> State.state(&({v, &1})) end do
    %KVS.Put{key: k, value: v, next: n} ->
      State.state(fn st ->  {n, Map.put(st, k, v)} end)
    %KVS.Get{key: k, next: nf} ->
      State.state(fn st ->
        v = case Map.fetch(st, k) do
              {:ok, v} -> Maybe.new(v)
              _ -> Maybe.new()
            end
        {nf.(v), st}
      end)
  end
end

defmodule KVS.Agent do
  alias Algae.Reader
  alias Algae.Maybe
  import Graymatter.Command

  # Free ~> Reader
  defhandler fn a -> Reader.new(fn _ -> a end) end do
    %KVS.Put{key: k, value: v, next: n} ->
      Reader.new(fn pid ->
        Agent.update(pid, fn st ->  Map.put(st, k, v) end)
        n
      end)
    %KVS.Get{key: k, next: nf} ->
      Reader.new(fn pid ->
        v = case Agent.get(pid, fn st ->  Map.fetch(st, k) end) do
              {:ok, v} -> Maybe.new(v)
              _ -> Maybe.new()
            end
        nf.(v)
      end)
  end
end

defmodule KVS.Examples do
  import KVS
  import Witchcraft.Chain

  def program do
    chain do
      put("a", 1)
      o <- get("a")
      is_update <- safe_modify("a", 2)
      if is_update, do: put("b", 3), else: put("b", o.just+1)
      get("b")
    end
  end

  def run do
    KVS.Inmemory.interpreter(program()).runner.(%{})
  end

  def run2 do
    {:ok, pid} = Agent.start(fn -> %{} end)
    KVS.Agent.interpreter(program()).reader.(pid)
  end
end
