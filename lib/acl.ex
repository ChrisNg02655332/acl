defmodule Acl do
  @moduledoc """
  # Acl

  ACL or access control list is a list of permissions attached to a specific object for certain users.

  ## ACL guide

  it has three essential Components Roles,Resources (handles as resource), and Rules.

  ### Roles

  Roles (users/user groups) are entities you want to give or deny access to.
  you can add a new role by



      iex> Acl.add_role(%{"role" => "role", "parent" => "parent"}, opts)



  in roles parent is optional and you may choose to provide it or not.

  ### Resource

  Resource are entities you want to give or deny access for. they can be anything real or arbitrary.

  you can add a new res by



     iex> Acl.add_resource(%{"resource" => "res", "parent" => "parent"}, opts)



  in resource parent is optional and you may choose to provide it or not.

  ### Rules

  Rules are definition for your set of permissions. you can add rule by



      iex> upsert_rule(%{"role" => role, "resource" => resource, "action" => "read"}, opts)
      iex> upsert_rule(%{"role" => role, "resource" => resource, "action" => "read", "allowed" => :self}, opts)


  and you can check if a role or permission exists by



      iex> has_access(%{"role" => role, "resource" => resource, "action" => "read"}, opts)
      iex> has_access(%{"role" => role, "resource" => resource, "action" => "read", "allowed" => :self}, opts)


      action valid : "none" < "read" < "write"   < "edit" < "delete"
      allowed valid: "none" < "self" < "related" < "all"


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
        true -> {:ok, %{role: rule.role, resource: rule.resource.resource, allowed: rule.allowed, action: rule.action}}
        _ -> {:error, :permission_denied}
      end
    end
  end

  def upsert_rule(params, opts \\ []) do
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

    AclRule
    |> where([r], r.role == ^params["role"])
    |> put_query_prefix(prefix)
    |> preload([:resource])
    |> resolve(:repo).all()
    |> Enum.map(fn rule ->
      %{role: rule.role, resource: rule.resource.resource, allowed: rule.allowed, action: rule.action}
    end)
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
    |> preload([:resource])
    |> resolve(:repo).get_by(opts)
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
      :edit -> 3
      :delete -> 4
      _ -> 0
    end
  end
end
