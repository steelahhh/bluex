defmodule Bluex do
  NimbleCSV.define(CSVParser, separator: ",", escape: "\"")

  def main(args) do
    aliases = [s: :source, o: :output]
    paths = [source: :string, output: :keep]
    parse = OptionParser.parse(args, aliases: aliases, strict: paths)

    case parse do
      {[source: source, output: output], _, _} ->
        generate_transactions(source, output)

      {_, _, _} ->
        IO.puts("Missing required arguments \n\nUsage: \n\tbluex -s file.csv -o new.csv")
    end
  end

  defp generate_transactions(file_path, output) do
    file_path
    |> read_dnc_transactions()
    |> bluecoins_standard_transactions()
    |> Stream.each(&IO.inspect/1)
    |> prepare_transactions_for_csv()
    |> append_csv_header()
    |> Stream.into(File.stream!(output))
    |> Stream.run()
  end

  defp read_dnc_transactions(path) do
    path
    |> File.stream!(read_ahead: 10_000)
    |> CSVParser.parse_stream()
    |> Stream.map(fn [date, description, category, payee, account, transfer_account, amount] ->
      {parent_category, sub_category} = Helpers.split_category(category)

      %{
        date: Helpers.debit_date(date),
        description: :binary.copy(description),
        parent_category: parent_category,
        sub_category: sub_category,
        amount: Helpers.sanitize_number(amount),
        account_dest: transfer_account,
        account: account,
        payee: :binary.copy(payee)
      }
    end)
  end

  defp bluecoins_standard_transactions(dnc_transactions) do
    dnc_transactions
    |> Stream.map(fn transaction ->
      {amount, origin_account, dest_account} =
        swap_accounts(transaction.amount, transaction.account, transaction.account_dest)

      %{transaction | amount: amount, account: origin_account, account_dest: dest_account}
    end)
    |> Stream.map(fn transaction ->
      type = Helpers.type_from_transaction(transaction)

      parent_cat =
        cond do
          type == "t" -> "(Transfer)"
          true -> transaction.parent_category
        end

      sub_cat =
        cond do
          type == "t" -> "(Transfer)"
          true -> transaction.sub_category
        end

      am =
        cond do
          type != "t" -> abs(transaction.amount)
          true -> transaction.amount
        end

      [
        type: type,
        date: Helpers.blue_date(transaction.date),
        payee: :binary.copy(transaction.payee),
        amount: am,
        parent_category: :binary.copy(parent_cat),
        category: :binary.copy(sub_cat),
        # Debit & Credit doesn't support account types, so just assume bank
        account_type: "Bank",
        account: :binary.copy(transaction.account),
        notes: :binary.copy(transaction.description),
        label: "",
        status: "",
        split: ""
      ]
    end)
  end

  defp prepare_transactions_for_csv(transactions) do
    transactions
    |> Stream.map(fn transaction ->
      raw =
        transaction
        |> Keyword.values()
        |> Enum.join(",")

      raw <> "\n"
    end)
  end

  defp append_csv_header(transactions) do
    header = [
      "(1)Type,(2)Date,(3)Item or Payee,(4)Amount,(5)Parent Category,(6)Category,(7)Account Type,(8)Account,(9)Notes,(10) Label,(11) Status,(12) Split\n"
    ]

    Stream.concat(header, transactions)
  end

  # swap origin and destination accounts for transfers, 
  #  because bluecoins expects transactions in the opposite order 
  defp swap_accounts(amount, account, transfer_account) do
    cond do
      amount > 0 && transfer_account != "" ->
        {-amount, transfer_account, account}

      amount < 0 && transfer_account != "" ->
        {-amount, transfer_account, account}

      true ->
        {amount, account, transfer_account}
    end
  end
end
