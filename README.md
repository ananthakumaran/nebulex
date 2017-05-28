<img src="http://cdn.wallpapersafari.com/44/53/JeEQGM.jpg" height="170" width="100%" />

# Nebulex

[![Build Status](https://travis-ci.org/cabol/nebulex.svg?branch=master)](https://travis-ci.org/cabol/nebulex)
[![Inline docs](http://inch-ci.org/github/cabol/nebulex.svg)](http://inch-ci.org/github/cabol/nebulex)
[![Coverage Status](https://coveralls.io/repos/github/cabol/nebulex/badge.svg?branch=master)](https://coveralls.io/github/cabol/nebulex?branch=master)

> **Local and Distributed Caching Tool for Elixir**

See the [getting started](https://hexdocs.pm/nebulex/getting-started.html) guide
and the [online documentation](https://hexdocs.pm/nebulex/Nebulex.html).

## Installation

Add `nebulex` to your list dependencies in `mix.exs`:

```elixir
def deps do
  [{:nebulex, github: "cabol/nebulex"}]
end
```

## Example

```elixir
# In your config/config.exs file
config :my_app, MyApp.Cache,
  adapter: Nebulex.Adapters.Local,
  n_shards: 2,
  gc_interval: 3600

# In your application code
defmodule MyApp.Cache do
  use Nebulex.Cache, otp_app: :my_app
end

defmodule MyApp do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(MyApp.Cache, [])
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Now it is ready to be used from any other module. Here is an example:
defmodule MyApp.Test do
  alias MyApp.Cache
  alias Nebulex.Object

  def test do
    Cache.set "foo", "bar", ttl: 2

    "bar" = Cache.get "foo"

    true = Cache.has_key? "foo"

    %Object{key: "foo", value: "bar"} = Cache.get "foo", return: :object

    :timer.sleep(2000)

    nil = Cache.get "foo"

    nil =
      "foo"
      |> Cache.set("bar", return: :key)
      |> Cache.delete(return: :key)
      |> Cache.get
  end
end
```

## Important links

 * [Documentation](https://hexdocs.pm/nebulex/Nebulex.html)
 * [Examples](https://github.com/cabol/nebulex_examples)
 * [Ecto Integration](https://github.com/cabol/nebulex_ecto)

## Testing

Testing by default spawns nodes internally for distributed tests.
To run tests that do not require clustering, exclude  the `clustered` tag:

```shell
$ mix test --exclude clustered
```

If you have issues running the clustered tests try running:

```shell
$ epmd -daemon
```

before running the tests.