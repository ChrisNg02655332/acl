defmodule Acl.AclRole do
  use Ecto.Schema
  import Ecto.Changeset

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
end
