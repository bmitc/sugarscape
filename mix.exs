defmodule Sugarscape.MixProject do
  use Mix.Project

  def project do
    [
      app: :sugarscape,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:kino_vega_lite, "~> 0.1.7"},
      {:nx, "~> 0.2"},
      {:vega_lite, "~> 0.1.6"}
    ]
  end

  defp aliases do
    [
      sugarscape_livebook: "cmd iex --sname sugarscape --cookie sugarscape -S mix"
    ]
  end
end
