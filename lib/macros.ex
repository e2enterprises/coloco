defmodule Coloco.Macros do
  defmacro scope_css({:sigil_H, _context, [{_, meta, [styles]}, _mod]}) do
    styles =
      styles
      |> String.trim()
      |> validate_surrounding_tags("style", "CSS", "scope_css")
      |> String.trim_leading("<style>")
      |> String.trim_trailing("</style>")
      |> String.trim()

    # Formatting of `expr` is aligned precisely to match whitespace
    # when styles are defined normally within a HEEx sigil:
    expr = "<style :type={ScopedCSS}>  #{styles}
            </style>
            "

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

  defmacro colocate_js({:sigil_H, _context, [{_, meta, [script]}, _mod]}) do
    script =
      script
      |> String.trim()
      |> validate_surrounding_tags("script", "JS", "colocate_js")
      |> String.trim_leading("<script>")
      |> String.trim_trailing("</script>")
      |> String.trim()

    # Formatting of `expr` is aligned precisely to match whitespace
    # when scripts are defined normally within a HEEx sigil:
    expr = "<script :type={ColocatedJS}>  #{script}
           </script>
           "

    compile_heex(expr, meta, __CALLER__)
  end

  defmacro colocate_hook({:sigil_H, _context, [{_, meta, [script]}, _mod]}) do
    name = "hook-#{hash("#{__CALLER__.module}-#{__CALLER__.line}")}"

    script =
      script
      |> String.trim()
      |> validate_surrounding_tags("script", "JS", "colocate_hook")
      |> String.trim_leading("<script>")
      |> String.trim_trailing("</script>")
      |> String.trim()

    # Formatting of `expr` is aligned precisely to match whitespace
    # when scripts are defined normally within a HEEx sigil:
    expr = "<script :type={ColocatedHook} name=\".#{name}\">  #{script}
           </script>
           "

    compile_heex(expr, meta, __CALLER__)

    quote do
      "#{__MODULE__ |> to_string() |> String.replace_prefix("Elixir.", "")}.#{unquote(name)}"
    end
  end

  defp validate_surrounding_tags("" <> str, "" <> expected_tag_name, "" <> type, "" <> macro) do
    if (String.starts_with?(str, "<#{expected_tag_name}>") and
          String.ends_with?(str, "</#{expected_tag_name}>")) or
         not String.starts_with?(str, "<") do
      str
    else
      raise(
        ArgumentError,
        "Colocated #{type} passed to #{macro} should be surrounded in" <>
          " <#{expected_tag_name}>...</#{expected_tag_name}> tags (with no attrs)" <>
          " to ensure code formatting works."
      )
    end
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
