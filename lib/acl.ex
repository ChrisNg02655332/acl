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

  import Ecto.Query, warn: false

  alias Acl.{AclRole, AclResource, AclRule}
  import Acl.Config

  def has_access(%{"role" => _, "resource" => _, "action" => _} = params, opts \\ []) do
    prefix = opts[:prefix] || "public"
    action = String.to_atom(params["action"])

    allowed = if params["allowed"], do: String.to_atom(params["allowed"]), else: nil

    with {:ok, resource} <- get_resource_by([resource: params["resource"]], prefix),
         {:ok, rule} <- get_rule_by([resource_id: resource.id, role: params["role"]], prefix) do
      case condition(rule, action, allowed) do
        true -> {:ok, rule}
        _ -> {:error, :permission_denied}
      end
    end
  end

  def add_rule(params, opts \\ []) do
    prefix = opts[:prefix] || "public"

    with {:ok, resource} <- get_resource_by([resource: params["resource"]], prefix) do
      opts = [role: params["role"], resource_id: resource.id]

      case get_rule_by(opts, prefix) do
        {:error, _} ->
          create_rule(
            %{
              "role" => params["role"],
              "resource" => resource,
              "action" => params["action"] || :read,
              "allowed" => params["allowed"] || :self
            },
            prefix
          )

        {:ok, rule} ->
          update_rule(rule, params, prefix)
      end
    end
  end

  def add_role(attrs, opts \\ []), do: %AclRole{} |> AclRole.changeset(attrs) |> resolve(:repo).insert(opts)

  def add_resource(attrs, opts \\ []), do: %AclResource{} |> AclResource.changeset(attrs) |> resolve(:repo).insert(opts)

  def list_resource(%{"role" => _} = params, opts \\ []) do
    prefix = opts[:prefix] || "public"

    AclRule |> where([r], r.role == ^params["role"]) |> put_query_prefix(prefix) |> resolve(:repo).all()
  end

  ## ACL RESOURCE

  defp get_resource_by(opts, prefix) do
    AclResource
    |> put_query_prefix(prefix)
    |> resolve(:repo).get_by(opts)
    |> case do
      nil -> {:error, :unknow_resource}
      resource -> {:ok, resource}
    end
  end

  ## ACL RULE 

  defp create_rule(attrs, prefix) do
    %AclRule{}
    |> AclRule.changeset(attrs, attrs["resource"])
    |> resolve(:repo).insert(prefix: prefix)
  end

  defp update_rule(rule, attrs, prefix) do
    rule |> AclRule.changeset(attrs) |> resolve(:repo).update(prefix: prefix)
  end

  defp get_rule_by(opts, prefix) do
    AclRule
    |> put_query_prefix(prefix)
    |> resolve(:repo).get_by(opts)
    # |> preload(:resource)
    |> case do
      nil -> {:error, :unknow_rule}
      rule -> {:ok, rule}
    end
  end

  defp condition(rule, action, nil), do: converter(rule.action) >= converter(action)

  defp condition(rule, action, allowed),
    do: converter(rule.action) >= converter(action) and converter(rule.allowed) >= converter(allowed)

  defp converter(params) when is_atom(params) do
    case params do
      :self -> 1
      :related -> 2
      :all -> 3
      :read -> 1
      :write -> 2
      :delete -> 3
      :edit -> 4
      _ -> 0
    end
  end
end
