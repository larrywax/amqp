defmodule AMQP.Mixfile do
  use Mix.Project

  @version "1.3.2"

  def project do
    [
      app: :amqp,
      version: @version,
      elixir: "~> 1.3",
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      package: package(),
      source_url: "https://github.com/pma/amqp",
      deps: deps(),
      dialyzer: [
        ignore_warnings: "dialyzer.ignore-warnings",
        plt_add_deps: :transitive,
        flags: [:error_handling, :race_conditions, :no_opaque, :underspecs]
      ],
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/pma/amqp"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      applications: [:lager, :amqp_client, :logger]
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted mix.exs \"lib/**/*.{ex,exs}\" \"test/**/*.{ex,exs}\" \"priv/**/*.{ex,exs}\" \"config/**/*.{ex,exs}\"",
        "credo",
        "dialyzer --halt-exit-status"
      ],
      "format.all": [
        "format mix.exs \"lib/**/*.{ex,exs}\" \"test/**/*.{ex,exs}\" \"priv/**/*.{ex,exs}\" \"config/**/*.{ex,exs}\""
      ]
    ]
  end

  defp deps do
    [
      {:amqp_client, "~> 3.7.20-rc"},
      {:rabbit_common, "~> 3.7.20-rc"},
      {:elixir_uuid, "~> 1.1"},

      # # We have an issue on rebar3 dependencies.
      # # https://github.com/pma/amqp/issues/78
      # {:goldrush, "~> 0.1.0"},
      # {:jsx, "~> 2.9"},
      # {:lager, "~> 3.6.5"},
      # {:ranch, "~> 1.7"},
      # {:recon, "~> 2.3"},

      {:earmark, "~> 1.0", only: :docs},
      {:ex_doc, "~> 0.15", only: :docs},
      {:inch_ex, "~> 0.5", only: :docs},
      {:dialyxir, "~> 1.0.0-rc", only: :dev, runtime: false},
      {:credo, "~> 1.1.4", only: [:dev, :test]},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end

  defp description do
    """
    Idiomatic Elixir client for RabbitMQ.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Paulo Almeida", "Eduardo Gurgel"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pma/amqp"}
    ]
  end
end
