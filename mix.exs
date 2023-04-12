defmodule Bluex.MixProject do
  use Mix.Project

  def project do
    [
      app: :bluex,
      version: "0.1.0",
      elixir: "~> 1.14",
      escript: escript(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def escript do
    [main_module: Bluex]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:timex, "~> 3.7"},
      # need to do this to make timex work in escript
      # https://github.com/bitwalker/timex/issues/86
      {:tzdata, "~> 0.1.8", override: true},
      {:nimble_csv, "~> 1.1"}
    ]
  end
end
