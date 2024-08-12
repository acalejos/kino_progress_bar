defmodule KinoProgressBar.MixProject do
  use Mix.Project

  def project do
    [
      app: :kino_progress_bar,
      version: "0.2.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:kino, "~> 0.13"}
    ]
  end
end
