defmodule Acl.AclResource do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query, warn: false
  import Acl.Config

  alias Acl.AclResource

  schema "acl_resources" do
    field(:parent, :string)
    field(:resource, :string)

    has_many(:rules, Acl.AclRule, foreign_key: :resource_id)

    timestamps(type: :utc_datetime)
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:resource, :parent])
    |> validate_required([:resource])
    |> unique_constraint(:resource)
  end

  def get(resource, opts \\ []),
    do: AclResource |> resolve(:repo).get(resource, opts)

  def get_by(opts, prefix) do
    AclResource |> put_query_prefix(prefix) |> resolve(:repo).get_by(opts)
  end

  def create(attrs, opts \\ []) do
    %AclResource{} |> changeset(attrs) |> resolve(:repo).insert(opts)
  end
end
