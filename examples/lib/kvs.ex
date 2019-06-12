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
  alias Algae.State
  import Graymatter.Command

  # Free ~> State
  defhandler fn v -> State.state(&({v, &1})) end do
    %KVS.Put{key: k, value: v, next: n} ->
      State.state(fn st ->  {n, Map.put(st, k, v)} end)
    %KVS.Get{key: k, next: nf} ->
      State.state(fn st ->
        {_, v} = Map.fetch(st, k)
        {nf.(v), st}
      end)
    %KVS.SafeModify{key: k, value: v, next: nf} ->
      State.state(fn st ->
        case  Map.fetch(st, k) do
          {:ok, _} -> {nf.(false), st}
          _ -> {nf.(true), Map.put(st, k, v)}
        end
      end)
  end
end

defmodule KVS.Agent do
  alias Algae.Reader
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
        {:ok, res} = Agent.get(pid, fn st ->  Map.fetch(st, k) end)
        nf.(res)
      end)
    %KVS.SafeModify{key: k, value: v, next: nf} ->
      Reader.new(fn pid ->
        case Agent.get(pid, fn st ->  Map.fetch(st, k) end) do
          {:ok, _} -> nf.(false)
          _ ->
            Agent.update(pid, fn st ->  Map.put(st, k, v) end)
            nf.(true)
        end
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
      is_update <- safemodify("a", 2)
      if is_update, do: put("b", 3), else: put("b", o+1)
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
