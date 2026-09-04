defmodule Coloco do
  # import DryDoc

  # @moduledoc doc_from_readme()
  @moduledoc Coloco |> DryDoc.from_readme()

  defmacro global_css({:sigil_H, _, [{_, meta, [css]}, _]}) do
    css = remove_surrounding_tags(css, "style", "CSS", "global_css")

    expr =
      """
      <style :type={Coloco.GlobalCSS}>
        #{css}
      </style>
      """
      |> String.trim_leading()

    compile_heex(expr, meta, __CALLER__)

    quote do
      ""
    end
  end

  @doc Coloco |> DryDoc.from_file("README.md", :scope_css)

  defmacro scope_css({:sigil_H, _, [{_, meta, [css]}, _]}) do
    css = remove_surrounding_tags(css, "style", "CSS", "scope_css")

    expr =
      """
      <style :type={Coloco.ScopedCSS}>
        #{css}
      </style>
      """
      |> String.trim_leading()

    compile_heex(expr, meta, __CALLER__)

    quote do
      Coloco.ScopedCSS.scope(__ENV__)
    end
  end

  defmacro descope_css() do
    quote do
      # This must be implemented as a macro instead of a standard function so that
      # __ENV__ contains the caller's module when the line below is evaluated:
      Coloco.ScopedCSS.descope(__ENV__)
    end
  end

  defmacro colocate_js({:sigil_H, _, [{_, meta, [js]}, _]}) do
    js = remove_surrounding_tags(js, "script", "JS", "colocate_js")

    expr =
      """
      <script :type={Phoenix.LiveView.ColocatedJS}>
        #{js}
      </script>
      """
      |> String.trim_leading()

    compile_heex(expr, meta, __CALLER__)
  end

  defmacro colocate_hook({:sigil_H, _, [{_, meta, [js]}, _]}) do
    {name, name_prefixed_with_module} = compute_hook_identifiers(__CALLER__)
    js = remove_surrounding_tags(js, "script", "JS", "colocate_hook")

    expr =
      """
      <script :type={Phoenix.LiveView.ColocatedHook} name=\"#{name}\">
        #{js}
      </script>
      """
      |> String.trim_leading()

    compile_heex(expr, meta, __CALLER__)

    quote do
      unquote(name_prefixed_with_module)
    end
  end

  defmacro colocate_mounted_hook({:sigil_H, _, [{_, meta, [js]}, _]}) do
    {name, name_prefixed_with_module} = compute_hook_identifiers(__CALLER__)
    js = remove_surrounding_tags(js, "script", "JS", "colocate_mounted_hook")

    expr =
      """
      <script :type={Phoenix.LiveView.ColocatedHook} name=\"#{name}\">
        export default {
          mounted() {
            #{js}
          }
        }
      </script>
      """
      |> String.trim_leading()

    compile_heex(expr, meta, __CALLER__)

    quote do
      unquote(name_prefixed_with_module)
    end
  end

  defp compute_hook_identifiers(caller) do
    name = ".hook-#{hash("#{caller.module}-#{caller.line}")}"
    module = caller.module |> to_string() |> String.replace_prefix("Elixir.", "")
    name_prefixed_with_module = module <> name
    {name, name_prefixed_with_module}
  end

  defp remove_surrounding_tags(
         "" <> code,
         "" <> expected_tag_name,
         "" <> type,
         "" <> macro
       ) do
    code = String.trim(code)

    if String.starts_with?(code, "<") do
      if String.starts_with?(code, "<#{expected_tag_name} ") or
           String.starts_with?(code, "<#{expected_tag_name}\n") do
        raise(
          ArgumentError,
          "Colocated #{type} code snippet passed to #{macro} is surrounded by a" <>
            " <#{expected_tag_name}> tag with attributes that should be removed." <>
            " Only use bare tags with #{macro}. Code snippet starts with:\n" <>
            "#{code |> String.split("\n") |> Enum.at(0)}"
        )
      end

      if not (String.starts_with?(code, "<#{expected_tag_name}>") and
                String.ends_with?(code, "</#{expected_tag_name}>")) do
        raise(
          ArgumentError,
          "Colocated #{type} code snippet passed to #{macro} must be surrounded" <>
            " by <#{expected_tag_name}>...</#{expected_tag_name}> tags," <>
            " or tags may be omitted entirely. Code snippet starts with:\n" <>
            "#{code |> String.split("\n") |> Enum.at(0)}"
        )
      end
    end

    code
    |> String.trim_leading("<#{expected_tag_name}>")
    |> String.trim_trailing("</#{expected_tag_name}>")
    |> String.trim()
  end

  defp compile_heex(expr, meta, caller) do
    # The following is essentially the full implementation of ~H (HEEx) sigil.
    # https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_component.ex#L923
    # The one difference is that we don't need to require an `assigns` variable in
    # scope here (since macro components can't do interpolation, they can never access
    # assigns within their HEEx code anyway).
    Phoenix.LiveView.TagEngine.compile(expr,
      file: caller.file,
      line: caller.line + 1,
      caller: caller,
      indentation: meta[:indentation] || 0,
      tag_handler: Phoenix.LiveView.HTMLEngine
    )
  end

  defp hash(string) do
    # It is important that we do not pad
    # the Base32 encoded value as we use it in
    # an HTML attribute name and = (the padding character)
    # is not valid.
    string
    |> then(&:crypto.hash(:md5, &1))
    |> Base.encode32(case: :lower, padding: false)
  end
end
