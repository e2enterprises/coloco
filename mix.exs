defmodule Coloco.MixProject do
  use Mix.Project

  @name "Coloco"
  @version "0.1.1"
  @repository "https://github.com/e2enterprises/coloco"

  defp description() do
    "Colocated, Scoped, Formatted, Ergonomic. Intermix JS, CSS & Phoenix components without limits."
  end

  def project do
    [
      app: :coloco,
      description: description(),
      version: @version,
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: docs(),
      deps: deps(),

      # Docs (see https://github.com/elixir-lang/ex_doc)
      name: @name,
      source_url: @repository,
      homepage_url: @repository
    ]
  end

  defp package() do
    [
      maintainers: ["Evan Campbell Purcer"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repository}
    ]
  end

  defp docs() do
    [
      main: Coloco,
      # TODO
      # logo: nil
      before_closing_head_tag: &before_closing_head_tag/1,
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8.9"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.2.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:makeup_js, "~> 0.1.0", only: :dev, runtime: false},
      {:makeup_diff, "~> 0.1.0", only: :dev, runtime: false}
    ]
  end

  def application do
    []
  end

  defp before_closing_head_tag(:epub), do: nil

  defp before_closing_head_tag(:html) do
    # Because we have no "extras" in the Pages section, hide this tab for clarity:
    """
    <style>
      #extras-list-tab-button { display: none; }
    </style>
    """
  end

  defp before_closing_body_tag(:epub), do: nil

  defp before_closing_body_tag(:html) do
    # Automatically expand the "Sections" list in the sidebar for visibility.
    # Expand during page load, and also any time the sidebar is opened (for mobile).
    """
    <script>
      function expandSections() {
        const selector = 'button[aria-controls="Coloco-sections-list"]';
        const sectionsToggle = document.querySelector(selector);
        if (sectionsToggle && sectionsToggle.getAttribute("aria-expanded") !== "true") {
          sectionsToggle.click();
        }
      }
      function expandSectionsWhenSidebarOpens() {
        const sidebarToggle = document.querySelector('button#sidebar-menu');
        if (sidebarToggle && window.MutationObserver !== undefined) {
          new MutationObserver(function (mutationList) {
            for (const mutation of mutationList) {
              if (mutation.type === "attributes"
                && mutation.attributeName === "aria-expanded"
                && mutation.target.getAttribute("aria-epanded") === "true"
              ) {
                expandSections();
              }
            }
          }).observe(sidebarToggle, { attributes: true });
        }
      }
      addEventListener("DOMContentLoaded", function () {
        requestAnimationFrame(expandSections); // wait for full sidebar render
        requestAnimationFrame(expandSectionsWhenSidebarOpens);
      });
    </script>
    """
  end
end
