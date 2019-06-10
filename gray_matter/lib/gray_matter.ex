defmodule GrayMatter do
  import GrayMatter.Command

  defcommand Put do
    a :: String.t()
    next :: any()
  end
  defcommand Get do
    next :: ({non_neg_integer(), String.t()} -> any())
  end
  defcommand Update do
    arg :: String.t()
    next ::  (String.t() -> any())
  end
end

defmodule BB do
  def run do
    GrayMatter.Put.new("aa", nil)
    GrayMatter.put("a")
  end
end
