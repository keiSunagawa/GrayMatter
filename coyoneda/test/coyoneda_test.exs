defmodule CoyonedaTest do
  use ExUnit.Case
  doctest Coyoneda

  test "greets the world" do
    assert Coyoneda.hello() == :world
  end
end
