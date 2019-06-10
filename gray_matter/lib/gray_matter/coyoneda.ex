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
