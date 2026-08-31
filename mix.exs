defmodule Coloco.MixProject do
  use Mix.Project

  @name "Coloco"
  @version "0.1.1"
  @repository "https://github.com/e2enterprises/coloco"

  defp description() do
    "Colocated, Scoped, Formatted, Ergonomic. Intermix JS, CSS & Phoenix components without limits."
  end

  def project do
    [
      app: :coloco,
      description: description(),
      version: @version,
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: docs(),
      deps: deps(),

      # Docs (see https://github.com/elixir-lang/ex_doc)
      name: @name,
      source_url: @repository,
      homepage_url: @repository
    ]
  end

  defp package() do
    [
      maintainers: ["Evan Campbell Purcer"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repository}
    ]
  end

  defp docs() do
    [
      # TODO
      logo: nil
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8.9"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.2.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:makeup_js, "~> 0.1.0"},
      {:makeup_diff, "~> 0.1.0"}
    ]
  end

  def application do
    []
  end
end
