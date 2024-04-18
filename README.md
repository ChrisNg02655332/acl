# Acme

**TODO: Add description**

## Installation

The package can be installed by adding `acl` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:acl, git: "https://github.com/ChrisNg02655332/acl.git", branch: "main" }
  ]
end
```

## Setup

Modify your config/config.ex file

```elixir
config :acl, repo: MyApp.Repo 
```

After the packages are installed you must create a database migration to add the oban_jobs table to your database:

```elixir
mix ecto.gen.migration add_acl_table
```

Open the generated migration in your editor and call the up and down functions on Acme.Migration:

```elixir
defmodule MyApp.Repo.Migrations.AddAclTable do
  use Ecto.Migration

  def up do
    Acl.Migrations.up()
  end

  def down do
    Acl.Migrations.down()
  end
end
```
