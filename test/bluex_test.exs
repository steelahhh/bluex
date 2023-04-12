defmodule BluexTest do
  use ExUnit.Case
  doctest Bluex

  test "number sanitizer works for negative number" do
    assert Helpers.sanitize_number("-140 439,49") == -140_439.49
  end

  test "number sanitizer works for positive number" do
    assert Helpers.sanitize_number("103 818,00") == 103_818.00
  end
end
