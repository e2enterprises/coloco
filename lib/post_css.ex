defmodule Coloco.PostCSS do
  @default_postcss_install_path "assets"

  @doc """
  Mix-alias-compatible function which can be used during assets.build to
  post-process CSS for auto-prefixing, nesting, imports, etc.

  In mix.exs, add to assets.build alias, eg.

    defp aliases do
      [
        ...,
        "assets.build":
          ["compile", &Coloco.PostCSS.build/1, "esbuild example_application"],
        ...,
      ]
    end

  If PostCSS is installed in a directory other than 'assets', specify install
  directory (relative to project root directory) in your config/dev.exs:

    config :coloco, postcss_install_path: "path/to/postcss/dir"
  """
  def build(_) do
    postcss_install_path =
      Application.get_env(
        :coloco,
        :postcss_install_path,
        @default_postcss_install_path
      )

    run_postcss(postcss_install_path, false)
  end

  @doc """
  Watcher that can be installed in config/dev.exs to run PostCSS in watch
  mode and re-process CSS whenever styles change.

  In config/dev.exs, add the following to :watchers list under Endpoint config:

    config :example_application, ExampleApplication.Endpoint
      ...,
      watchers: [
        ...,
        postcss: {Coloco.PostCSS, :watcher, []},
        ...,
      ]
  """
  def watcher() do
    postcss_install_path =
      Application.get_env(
        :coloco,
        :postcss_install_path,
        @default_postcss_install_path
      )

    run_postcss(postcss_install_path, true)
  end

  @doc """
  If PostCSS install directory needs to be specified separately from build,
  a different path (relative to project root directory) can be passed here:

    postcss: {Coloco.PostCSS, :watcher, [postcss_install_path: "path/to/postcss/dir"]}
  """
  def watcher({:postcss_install_path, postcss_install_path}) do
    run_postcss(postcss_install_path, true)
  end

  defp run_postcss(postcss_install_path, watch) do
    executable = postcss_install_path |> Path.join("node_modules/.bin/postcss")
    config = postcss_install_path |> Path.join("postcss.config.cjs")

    input_css = "assets/css/app.css"
    output_css = "priv/static/assets/css/app.css"

    args = ["--verbose", "--config", config, input_css, "--output", output_css]

    {output, exit_code} =
      System.cmd(
        "node",
        [
          executable
          | case watch do
              true -> ["--watch" | args]
              false -> args
            end
        ],
        env: %{"NODE_PATH" => Mix.Project.build_path()},
        cd: File.cwd!()
        # ^ project root dir of caller (dir containing mix.exs)
      )

    case exit_code do
      0 when is_binary(output) ->
        IO.puts("[PostCSS] Success ✔")

        if output |> String.trim() |> String.length() do
          IO.puts("[PostCSS] Output: #{output}")
        end

      0 ->
        IO.puts("[PostCSS] Success ✔")

        if output != nil do
          IO.puts("[PostCSS] Output: #{inspect(output)}")
        end

      _ ->
        IO.puts("[PostCSS] Error: `node #{executable}` returned non-zero exit code #{exit_code}")
    end
  end
end
