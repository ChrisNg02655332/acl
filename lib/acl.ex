defmodule Acl do
  @moduledoc """
  Documentation for `Acl`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Acl.hello()
      :world

  """

  alias Acl.{AclRole, AclResource, AclRule}

  def has_access() do
  end

  def add_rule(params, opts), do: AclRule.create(params, opts)
  def add_role(params, opts \\ []), do: AclRole.create(params, opts)
  def add_resource(params, opts \\ []), do: AclResource.create(params, opts)
end
