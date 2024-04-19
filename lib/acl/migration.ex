defmodule Acl.Migrations do
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    if prefix, do: execute("CREATE SCHEMA IF NOT EXISTS #{prefix}")

    create_if_not_exists table(:acl_roles, primary_key: false, prefix: prefix) do
      add(:role, :string, null: false, primary_key: true)
      add(:parent, :string, default: nil)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:acl_roles, [:role], prefix: prefix))

    create_if_not_exists table(:acl_resources, prefix: prefix) do
      add(:resource, :string, null: true)
      add(:parent, :string, default: nil)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:acl_resources, [:resource], prefix: prefix))

    create_if_not_exists table(:acl_rules, prefix: prefix) do
      add(
        :role,
        references(:acl_roles,
          column: :role,
          type: :string,
          on_delete: :delete_all,
          primary_key: true,
          prefix: prefix
        )
      )

      add(
        :resource_id,
        references(:acl_resources,
          column: :id,
          type: :id,
          on_delete: :delete_all,
          primary_key: true,
          prefix: prefix
        )
      )

      add(:action, :string)
      add(:allowed, :string)

      timestamps(type: :utc_datetime)
    end

    create(index(:acl_rules, [:role], prefix: prefix))
    create(index(:acl_rules, [:resource_id], prefix: prefix))
    create(index(:acl_rules, [:role, :resource_id], prefix: prefix))
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    drop_if_exists(table(:acl_rules, prefix: prefix))
    drop_if_exists(table(:acl_resources, prefix: prefix))
    drop_if_exists(table(:acl_roles, prefix: prefix))
  end
end
