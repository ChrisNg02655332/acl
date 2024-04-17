defmodule Acl.Migrations do
  use Ecto.Migration

  def up(opts \\ []) do
    create_if_not_exists table(:acl_roles, primary_key: false, prefix: opts[:prefix] || "public") do
      add(:role, :string, null: false, primary_key: true)
      add(:parent, :string, default: nil)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:acl_roles, [:role]))

    create_if_not_exists table(:acl_resources, prefix: opts[:prefix] || "public") do
      add(:resource, :string, null: true)
      add(:path, :string)
      add(:parent, :string, default: nil)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:acl_resources, [:resource]))

    create_if_not_exists table(:acl_rules, prefix: opts[:prefix] || "public") do
      add(
        :role,
        references(:acl_roles,
          column: :role,
          type: :string,
          on_delete: :delete_all,
          primary_key: true
        )
      )

      add(
        :resource_id,
        references(:acl_resources,
          column: :id,
          type: :id,
          on_delete: :delete_all,
          primary_key: true
        )
      )

      add(:action, :string, default: nil)
      add(:allowed, :boolean, default: false)
      add(:permission, :int, default: 1)
      add(:condition, :int, default: 1)
      add(:where_field, :string, default: nil)
      add(:where_value, :string, default: nil)
      add(:where_cond, :string, default: nil)

      timestamps(type: :utc_datetime)
    end

    create(index(:acl_rules, [:role]))
    create(index(:acl_rules, [:resource_id]))
    create(index(:acl_rules, [:role, :resource_id]))
  end

  def down(opts \\ []) do
    drop_if_exists(table(:acl_roles, prefix: opts[:prefix] || "public"))
    drop_if_exists(table(:acl_resources, prefix: opts[:prefix] || "public"))
    drop_if_exists(table(:acl_rules, prefix: opts[:prefix] || "public"))
  end
end
