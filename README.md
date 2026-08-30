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
gaps, providing ergonomic tooling out-of-the-box which integrates well with any
template system.

Coloco aims to provide an excellent dev experience in these areas:
- **Ergonomics:** A set of macros allow flexible expression of JS and CSS code within
  Phoenix component files, next to or within the template the code is relevant to.
  This comes without any runtime cost.
- **CSS Scoping:** Coloco provides a "low-fi" or "low-magic" form of CSS scoping using
  generated `@scope` rules, with fallback strategy for browsers that don't support this.
    - Note that "de-scoping" does not always happen automatically. Often you'll want
      a CSS scope to end when a component's slot content starts, and in these cases
      you'll need to use an element with a `descope_css` class or attr around the slot.
    - Coloco does generate CSS to automatically "de-scope" wherever a new CSS scope
      begins. So in cases where a CSS-scoped parent component has child sub-components
      with their own scope, no manual de-scope is needed; the scopes will not overlap.
- **CSS Post-Processing:** In most production settings, it's highly beneficial to do
  some transformation of CSS between source code and what is shipped to the browser.
  [Autoprefixer](https://github.com/postcss/autoprefixer) is ubiquitous for auto-adding
  variations of rules for browser compatibility reasons. Another good example is CSS
  nesting, which is not yet supported in older browsers. PostCSS provides plugin-based
  handling of these transforms and many others from a rich ecosystem, but it has rough
  edges when integrated with Phoenix. Coloco makes PostCSS configuration relatively
  simple, and handles issues like the PostCSS watcher process not terminating during
  Phoenix server shutdown when it's installed normally
  ([see this issue](https://elixirforum.com/t/extra-watcher-doesnt-get-killed-when-shutting-down-phoenix/2807)).
- **Colocated Code Formatting:** Setting up automatic formatting of colocated code
  is possible in LiveView 1.2, which is amazing, but much of the actual implementation
  is left to user-side plugin code making the setup cumbersome. Coloco provides
  pre-built plugins which use Prettier to format colocated JS and CSS, with only a few
  changes to `.formatter.exs` required.

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

## PostCSS (Browser-compatible CSS nesting & auto-prefixing)

Coloco expects the calling application to manage installation of PostCSS and its
plugins, which gives much greater flexibility. First, run these commands in the
`assets` directory:
```sh
cd assets
! [[ -f package.json ]] && echo "{}" >> package.json
npm install --save-dev postcss postcss-import postcss-nesting autoprefixer prettier tailwindcss @tailwindcss/cli @tailwindcss/postcss daisyui
```
Now you'll need to add a PostCSS config file in `assets`. Here's an example using the
plugins installed above; copy this config into `assets/postcss.config.cjs`:
```javascript
const path = require("path")
module.exports = {
  plugins: [
    require("postcss-import")({ path: process.env.NODE_PATH.split(path.delimiter) }),
    // postcss-import should come first (per plugin docs)
    require("@tailwindcss/postcss"),
    require("postcss-nesting"),
    require("autoprefixer"),
  ]
}
```
Now, make these changes to Phoenix app config to run PostCSS during build and also
watch source files changes to rebuild when the dev server is running:
```diff
    # mix.exs

    defp aliases do
      [
        setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
        "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
        "ecto.reset": ["ecto.drop", "ecto.setup"],
        test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
        "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
---     "assets.build": ["compile", "tailwind example_app", "esbuild example_app"],
+++     "assets.build": ["compile", &Coloco.PostCSS.build/1, "esbuild example_app"],
        "assets.deploy": [
---       "tailwind example_app --minify",
          "esbuild example_app --minify",
          "phx.digest"
        ],
```
```diff
    # config/dev.exs

    config :example_application, ExampleApplication.Endpoint
      ...,
      watchers: [
        esbuild: {Esbuild, :install_and_run, [:example_app, ~w(--sourcemap=inline --watch)]},
---     tailwind: {Tailwind, :install_and_run, [:example_app, ~w(--watch)]}
+++     postcss: {Coloco.PostCSS, :watcher, []}
      ]
```
Note that PostCSS runs all Tailwind-related processing via the `@tailwind/postcss`
plugin, so standalone commands to invoke tailwind are no longer necessary and are
removed from the files above.

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


