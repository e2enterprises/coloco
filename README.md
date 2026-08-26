# Coloco

**Colocated, Scoped, Formatted, Ergonomic. Intermix JS, CSS & Phoenix LiveView
components without limits.**

## Why?

Phoenix LiveView's (1.2) implementation of component-colocated CSS and JS is a
fantastic addition, allowing us to finally separate fully by concern rather than
implementation language as frontend codebases have been doing since components
became the UI architecture pattern de jour. However, colocated CSS and JS in LiveView
1.2 has certain limitations, especially when using a template engine other than HEEx
(eg. [Temple](https://github.com/mhanberg/temple)). LiveView also leaves much of the
implementation of colocated CSS/JS to consumer side plugin code. Coloco fills in these
gaps, providing ergonomic tooling out-of-the-box which:
- works well with any template system -- not just HEEx -- because it leverages
  straightforward classes and/or HTML attributes rather than framework-specific
  mechanisms
- allows colocated CSS/JS to be placed anywhere in module, not just within a template
- does not rely on any PostCSS transform for CSS scoping
- wrt. CSS scoping, includes support for legacy browsers, with opt-in `@scope`
  strategy available to minimize CSS asset size when targeting only modern browsers

## Installation

Add `coloco` to your list of dependencies in `mix.exs`, then run `mix deps.get`:

```elixir
def deps do
  [
    {:coloco, "~> 0.1.0"}
  ]
end
```

## Setup

There are two ways Coloco can be used:
1. Through four small macros: `scope_css`, `descope_css`, `colocate_js`, `colocate_hook`
    - **Setup:** Add `import Coloco.Macros` to your module, or add it within
      the `html_helpers` section of your Phoenix app config to make these macros
      available throughout all components (live and otherwise).
2. Directly, by calling the `ScopeCSS` module directly.
    - **Setup:** None; just call `Coloco.ScopedCSS.scope` and other functions wherever
      you need them.

These two methods are functionally equivalent; macros operate during compilation
so runtime behavior will be identical. Here are kitchen-sink examples of each style
for comparison:

```elixir
# Macro style:

defmodule MyApplication.MyComponent do
  use MyApplicationWeb, :live_view

  def render(assigns) do
    temple do
      div class: css_scope() do
        p "phx-hook": p_hook(), id: "hooks-need-ids" do
          "hello world"
        end

        div class: descope_css(), do: slot @inner_block

        colocate_js(~H"""
          alert("hello world from colocated js");
        """js)
      end
    end
  end

  def css_scope() do
    scope_css(~H"""
      p {
        color: green;
      }
    """css)
  end

  def p_hook() do
    colocate_hook(~H"""
      export default {
        mounted() {
          alert("hello world from colocated hook");
        },
      };
    """js)
  end
end
```

```elixir
# Direct-call / Macroless style:

defmodule MyApplication.MyComponent do
  use MyApplicationWeb, :live_view

  def render(assigns) do
    temple do
      div class: css_scope() do
        p "hello world"

        div class: Coloco.ScopedCSS.descope(__ENV__), do: slot @inner_block

        ~H"""
        <script :type={Phoenix.LiveView.ColocatedJS}>
          alert("hello world from colocated js");
        </script>
        """)
      end
    end
  end

  def css_scope() do
    Coloco.ScopedCSS.scope(__ENV__, ~H"""
    <style :type={Coloco.ScopedCSS}>
      p {
        color: green;
      }
    </style>
    """)
  end

  def p_hook() do
    hook_name = ".p_hook"
    module = __MODULE__ |> to_string() |> String.replace_prefix("Elixir.", "")
    hook_name_prefixed_with_module = module <> hook_name
    ~H"""
    <script :type={Phoenix.LiveView.ColocatedHook} name="#{hook_name}">
      export default {
        mounted() {
          alert("hello world from colocated hook");
        },
      };
    </script>
    """)
    hook_name_prefixed_with_module
  end
end
```

## Colocated Code Formatting

In order to automatically format JS and CSS colocated code whenever `mix format` is
run (either via CLI, or editor integration) make these changes to your
`.formatter.exs` config file at project root:

```diff
    [
      import_deps: [:ecto, :ecto_sql, :phoenix, :temple],
      subdirectories: ["priv/*/migrations"],
      plugins: [
+++     Coloco.Format.PreHTMLFormatterPlugin,   # add BEFORE LiveView.HTMLFormatter
        Phoenix.LiveView.HTMLFormatter,
+++     Coloco.Format.PostHTMLFormatterPlugin,  # add AFTER LiveView.HTMLFormatter
      ],
      inputs: [
        "*.{heex,ex,exs}",
        "{config,lib,test}/**/*.{heex,ex,exs}",
        "priv/*/seeds.exs",
      ],
+++   tag_formatters: %{
+++     script: Coloco.Format.PrettierTagFormatter,
+++     style: Coloco.Format.PrettierTagFormatter,
+++   },
      ...
```

The sole purpose of Coloco's `PreHTMLFormatterPlugin` and `PostHTMLFormatterPlugin` is
to manage surrounding `<script>` and `<style>` tags properly so that
`Phoenix.LiveView.HTMLFormatter` can operate normally even when these tags aren't
included in source code. If you prefer, you can avoid using these plugins and use
wrapping tags when you define colocated code instead:
```elixir
    scope_css(~H"""
    <style>
      p {
        color: green;
      }
    </style>
    """css)
```
instead of
```elixir
    scope_css(~H"""
      p {
        color: green;
      }
    """css)
```
With `PreHTMLFormatterPlugin` and `PostHTMLFormatterPlugin` included in plugins, both
of these will behave identically and be formatted identically (any wrapping tags you
add will remain in place). Without these plugins, only the first example will work
with the formatter; the second will cause it to error.


