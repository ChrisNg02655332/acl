defmodule Acl.AclRule do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  import Acl.Config
  alias Acl.{AclRule, AclResource}

  @primary_key false
  schema "acl_rules" do
    field(:allowed, Ecto.Enum, values: [:none, :self, :related, :all], default: :self)
    field(:action, Ecto.Enum, values: [:none, :read, :write, :edit, :delete], default: :read)
    field(:role, :string, primary_key: true)
    belongs_to(:resource, AclResource, references: :id, primary_key: true)

    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:action, :role, :allowed, :resource_id])
    |> validate_required([:resource, :role])
  end

  def changeset(rule, attrs, resource) do
    rule
    |> cast(attrs, [:action, :allowed, :role])
    |> put_assoc(:resource, resource)
    |> validate_required([:resource, :role])
  end

  def create(params, opts) do
    prefix = opts[:prefix] || "public"

    case AclResource.get_by([resource: params["resource"]], prefix) do
      nil ->
        {:error, :unknow_resource}

      resource ->
        opts = [role: params["role"], resource_id: resource.id]

        get_by(opts, prefix)
        |> case do
          nil ->
            create_rule(
              %{
                "role" => params["role"],
                "resource" => resource,
                "action" => params["action"] || :read,
                "allowed" => params["allowed"] || :self
              },
              prefix
            )

          rule ->
            update_rule(rule, params, prefix)
        end
    end
  end

  defp create_rule(attrs, prefix) do
    %AclRule{}
    |> changeset(attrs, attrs["resource"])
    |> resolve(:repo).insert(prefix: prefix)
  end

  defp update_rule(rule, attrs, prefix) do
    rule |> changeset(attrs) |> resolve(:repo).update(prefix: prefix)
  end

  defp get_by(opts, prefix) do
    AclRule
    |> put_query_prefix(prefix)
    |> resolve(:repo).get_by(opts)
  end
end
