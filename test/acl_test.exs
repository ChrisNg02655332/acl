defmodule AclTest do
  use ExUnit.Case
  doctest Acl

  test "greets the world" do
    assert Acl.hello() == :world
  end
end
