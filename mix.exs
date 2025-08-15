defmodule Monaditto.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/bardoor/monaditto"

  def project do
    [
      app: :monaditto,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "Monaditto",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A pragmatic monad library for Elixir, no PhD required
    """
  end

  defp package do
    [
      name: "monaditto",
      files: ~w(lib .formatter.exs mix.exs README* CHANGELOG* LICENSE*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      maintainers: ["bardoor"]
    ]
  end

  defp docs do
    [
      main: "Monad",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
