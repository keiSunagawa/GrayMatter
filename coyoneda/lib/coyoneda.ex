defmodule Coyoneda do
  import Algae

  defdata do
    f :: (any() -> any())
    m :: any()
  end

  def lift(a) do
    Coyoneda.new(Quark.id, a)
  end
end

defmodule Op do
  import Algae

  defsum do
    defdata PutStrLn do
      a :: any() # next op
      c :: String.t()
    end
    defdata GetStrLn :: (String.t() -> any()) # return value is next op
  end
end
defmodule Ex do
  

end
