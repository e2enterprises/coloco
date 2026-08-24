defmodule ColocoGlobalCSSTest do
  use ExUnit.Case
  doctest Coloco.GlobalCSS

  test "greets the world" do
    {:ok, css, []} = Coloco.GlobalCSS.transform("style", [], "hello world", __ENV__)
    assert css == "hello world"
  end
end

defmodule ColocoScopedCSSTest do
  use ExUnit.Case
  doctest Coloco.ScopedCSS

  test "greets the world" do
    {:ok, css, []} = Coloco.ScopedCSS.transform("style", [], "hello world", __ENV__)
    assert css |> String.starts_with?("@scope")
    assert css |> String.contains?("{ hello world }")
  end
end
