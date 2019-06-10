defmodule Coyoneda do
  import Algae
  import Quark.Compose
  import TypeClass

  defdata do
    f :: (any() -> any())
    m :: any()
  end

  def new(f, m) do
    %Coyoneda{f: f, m: m}
  end

  def lift(a) do
    new(&Quark.id/1, a)
  end

  defimpl TypeClass.Property.Generator, for: Coyoneda do
    def generate(_), do: %Coyoneda{f: &Quark.id/1, m: nil}
  end

  definst Witchcraft.Functor, for: Coyoneda do
    @force_type_instance true
    def map(%{f: f, m: m}, fun), do: %Coyoneda{f: fun <|> f, m: m}
  end
end

defmodule Op do
  import Algae
  alias Algae.Free

  defsum do
    defdata PutStrLn do
      a :: any() # next op
      c :: String.t()
    end
    defdata GetStrLn :: (String.t() -> any()) # return value is next op
  end

  def put_str(s) do
    PutStrLn.new(%Witchcraft.Unit{}, s)
    |> Coyoneda.lift()
    |> Free.free()
  end

  def get_str do
    GetStrLn.new(&Quark.id/1)
    |> Coyoneda.lift()
    |> Free.free()
  end

  alias Algae.Free.{Roll, Pure}
  alias Algae.Id
  import Witchcraft.Chain
  import Quark.Compose

  def interpreter(%Roll{roll: %Coyoneda{f: f, m: m}}) do
    case m do
      %PutStrLn{a: a, c: c} ->
        IO.puts(c)
        Id.new(a) >>> ((&interpreter/1) <|> f)
      %GetStrLn{getstrln: g} ->
        res = g.("test.")
        Id.new(res) >>> ((&interpreter/1) <|> f)
    end
  end
  def interpreter(%Pure{pure: a}) do
    a
  end
end
defmodule Ex do
  import Witchcraft.Chain

  def run do
    a = chain do
      Op.put_str("hello.")
      str <- Op.get_str()
      Op.put_str(str)
    end
    Op.interpreter(a)
  end
end
