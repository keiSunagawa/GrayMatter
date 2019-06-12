defmodule Console do
  import Graymatter.Command

  defcommand PutStrLn do
    value :: String.t()
    next :: any()
  end
  defcommand GetStr do
    next :: (String.t() -> any())
  end
end

defmodule Console.IO do
  import Graymatter.Command
  alias Algae.Id

  # Free ~> Id
  defhandler &Id.new/1 do
    %Console.PutStrLn{value: v, next: n} ->
      IO.inspect(v)
      Id.new(n)
    %Console.GetStr{next: nf} ->
      input = IO.gets(">> ")
      Id.new(nf.(input))
  end
end

defmodule Console.Examples do
  import Witchcraft.Chain
  import Console

  def program1 do
    chain do
      putstrln("Hello.")
      input <- getstr()
      putstrln(input)
    end
  end

  def program2 do
    chain do
      name <- request_name()
      put_for_n(name, 10)
    end
  end

  defp request_name do
    chain do
      putstrln("please your name.")
      getstr()
    end
  end

  defp put_for_n(str, n) do
    chain do
      putstrln(str)
      if (n == 0), do: putstrln("done."), else: put_for_n(str, n-1)
    end
  end

  def run do
    Console.IO.interpreter(program1())
    Console.IO.interpreter(program2())
  end

end
