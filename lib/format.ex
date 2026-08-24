defmodule Coloco.Format do
  defmodule PrettierTagFormatter do
    # Reference Examples:
    # phoenix-live-view.hexdocs.pm/Phoenix.LiveView.HTMLFormatter.TagFormatter.html
    # github.com/phoenixframework/phoenix_live_view/blob/main/lib/prettier.ex

    def render_tag({tag, attrs, content}, _opts) when tag in ["script", "style"] do
      extension =
        case tag do
          "script" -> "js"
          "style" -> "css"
        end

      suffix =
        case attrs do
          # Co-located JS/CSS script or style tag:
          %{":type" => _} -> Map.get(attrs, "manifest", "index.#{extension}")
          # Normal JS/CSS file:
          _ -> "tmp.#{extension}"
        end

      tmp_file =
        Path.join(
          System.tmp_dir!(),
          "prettier_#{System.unique_integer([:positive])}_#{suffix}"
        )

      prettier_executable = Path.expand("assets/node_modules/.bin/prettier")

      try do
        File.write!(tmp_file, content)

        # Note: Avoid setting :stderr_to_stdout here as shown in Phoenix docs/examples.
        #       This leads to error output being prepended directly into the file being
        #       formatted, which is difficult to deal with since the file syntax then
        #       becomes invalid. Instead, simpler setup below will:
        #       - show error output clearly when `mix format` is run manually
        #       - won't do anything (fail gracefully) when formatting runs in-editor
        case System.cmd(prettier_executable, [tmp_file]) do
          {output, 0} -> {:ok, String.trim(output)}
          _ -> :skip
        end
      after
        File.rm(tmp_file)
      end
    end
  end

  defmodule PreHTMLFormatterPlugin do
    @behaviour Mix.Tasks.Format

    def features(_opts) do
      [sigils: [:H], extensions: []]
    end

    def format(contents, opts) do
      cond do
        opts[:modifiers] == ~c'css' and
            not (contents |> String.trim() |> String.starts_with?("<style")) ->
          "<style COLOCO-TEMPORARY-TAG>#{contents}</style>"

        opts[:modifiers] == ~c'js' and
            not (contents |> String.trim() |> String.starts_with?("<script")) ->
          "<script COLOCO-TEMPORARY-TAG>#{contents}</script>"

        true ->
          contents
      end
    end
  end

  defmodule PostHTMLFormatterPlugin do
    @behaviour Mix.Tasks.Format

    def features(_opts) do
      [sigils: [:H], extensions: []]
    end

    def format(contents, opts) do
      cond do
        opts[:modifiers] == ~c'css' and
            contents |> String.trim() |> String.starts_with?("<style COLOCO-TEMPORARY-TAG>") ->
          contents
          |> String.trim()
          |> String.trim_leading("<style COLOCO-TEMPORARY-TAG>")
          |> String.trim_trailing("</style>")
          |> String.trim_leading("\n")

        opts[:modifiers] == ~c'js' and
            contents |> String.trim() |> String.starts_with?("<script COLOCO-TEMPORARY-TAG>") ->
          contents
          |> String.trim()
          |> String.trim_leading("<script COLOCO-TEMPORARY-TAG>")
          |> String.trim_trailing("</script>")
          |> String.trim_leading("\n")

        true ->
          contents
      end
    end
  end
end
