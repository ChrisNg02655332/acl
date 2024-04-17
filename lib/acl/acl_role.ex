defmodule Acl.AclRole do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query, warn: false
  import Acl.Config

  alias Acl.AclRole

  @primary_key {:role, :string, autogenerate: false}
  schema "acl_roles" do
    field(:parent, :string)
    has_many(:rules, Acl.AclRule, foreign_key: :role)

    timestamps(type: :utc_datetime)
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:role, :parent])
    |> validate_required([:role])
    |> unique_constraint(:role)
  end

  def create(attrs, opts \\ []) do
    %AclRole{} |> changeset(attrs) |> resolve(:repo).insert(opts)
  end
end
