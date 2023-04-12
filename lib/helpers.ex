defmodule Helpers do
  def debit_date(date) do
    date
    |> Timex.parse!("{D} {Mfull} {YYYY} at {h24}:{m}")
  end

  def blue_date(date) do
    date |> Timex.format!("{D}/{0M}/{YYYY}")
  end

  def sanitize_number(num) do
    {parsed, _} =
      num
      |> String.replace(",", ".")
      |> String.replace(~r"[^\d^\.^-]", "")
      |> Float.parse()

    parsed
  end

  def type_from_transaction(transaction) do
    cond do
      transaction.account_dest != "" -> "t"
      transaction.amount > 0 -> "i"
      transaction.amount < 0 -> "e"
      true -> ""
    end
  end

  # split category into parent- and sub-category
  def split_category(category) do
    categories =
      category
      |> String.split("-")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&value_or_empty/1)
      |> Enum.reverse()

    case categories do
      [parent_category] ->
        {parent_category, ""}

      [parent_category, sub_category] ->
        {parent_category, sub_category}
    end
  end

  def value_or_empty(value) do
    if value == nil do
      ""
    else
      value
    end
  end
end
