defmodule Imagapi.Mixfile do
  use Mix.Project

  def project do
    [app: :imagapi,
     version: "1.1.3",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     # docs
     name: "iMAGApi",
     source_url: "https://github.com/dongmaster/imagapi",
     homepage_url: "https://github.com/dongmaster/imagapi",
     docs: [main: "Volapi", # The main page in the docs
            #logo: "path/to/logo.png",
            extras: ["README.md"]]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :crypto, :ssl],
     mod: {Imagapi, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:websocket_client, "~> 1.2"},
      {:poison, "~> 3.0"},
      {:httpoison, "~> 0.10.0"},
      {:ex_doc, "~> 0.14.5", only: :dev}
    ]
  end
end
