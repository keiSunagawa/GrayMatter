defmodule Graymatter.Coyoneda do
  import Algae
  import Quark.Compose
  import TypeClass

  defdata do
    f :: (any() -> any())
    m :: any()
  end

  def new(f, m) do
    %Graymatter.Coyoneda{f: f, m: m}
  end

  def lift(a) do
    new(&Quark.id/1, a)
  end

  defimpl TypeClass.Property.Generator, for: Graymatter.Coyoneda do
    def generate(_), do: %Graymatter.Coyoneda{f: &Quark.id/1, m: nil}
  end

  definst Witchcraft.Functor, for: Graymatter.Coyoneda do
    @force_type_instance true
    def map(%{f: f, m: m}, fun), do: %Graymatter.Coyoneda{f: fun <|> f, m: m}
  end
end
