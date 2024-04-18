defmodule Acl.AclRule do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "acl_rules" do
    field(:allowed, Ecto.Enum, values: [:none, :self, :related, :all], default: :self)
    field(:action, Ecto.Enum, values: [:none, :read, :write, :delete, :edit], default: :read)
    field(:role, :string, primary_key: true)
    belongs_to(:resource, Acl.AclResource, references: :id, primary_key: true)

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
end
