defmodule Nebulex.Telemetry.StatsHandler do
  @moduledoc """
  Telemetry handler for aggregating cache stats; it relies on the default stats
  implementation based on Erlang counters. See `Nebulex.Adapter.Stats`.

  This handler is used by the built-in local adapter when the option `:stats`
  is set to `true`.
  """

  alias Nebulex.Adapter.Stats

  ## Handler

  @doc false
  def handle_event(_event, _measurements, %{adapter_meta: %{stats_counter: ref}} = metadata, ref) do
    update_stats(metadata)
  end

  # coveralls-ignore-start

  def handle_event(_event, _measurements, _metadata, _ref) do
    :ok
  end

  # coveralls-ignore-stop

  defp update_stats(%{
         function_name: action,
         result: :"$expired",
         adapter_meta: %{stats_counter: ref}
       })
       when action in [:get, :take, :ttl] do
    :ok = Stats.incr(ref, :misses)
    :ok = Stats.incr(ref, :evictions)
    :ok = Stats.incr(ref, :expirations)
  end

  defp update_stats(%{function_name: action, result: nil, adapter_meta: %{stats_counter: ref}})
       when action in [:get, :take, :ttl] do
    :ok = Stats.incr(ref, :misses)
  end

  defp update_stats(%{function_name: action, result: _, adapter_meta: %{stats_counter: ref}})
       when action in [:get, :ttl] do
    :ok = Stats.incr(ref, :hits)
  end

  defp update_stats(%{function_name: :take, result: _, adapter_meta: %{stats_counter: ref}}) do
    :ok = Stats.incr(ref, :hits)
    :ok = Stats.incr(ref, :evictions)
  end

  defp update_stats(%{
         function_name: :put,
         args: [_, _, _, :replace, _],
         result: true,
         adapter_meta: %{stats_counter: ref}
       }) do
    :ok = Stats.incr(ref, :updates)
  end

  defp update_stats(%{function_name: :put, result: true, adapter_meta: %{stats_counter: ref}}) do
    :ok = Stats.incr(ref, :writes)
  end

  defp update_stats(%{
         function_name: :put_all,
         result: true,
         args: [entries | _],
         adapter_meta: %{stats_counter: ref}
       }) do
    :ok = Stats.incr(ref, :writes, length(entries))
  end

  defp update_stats(%{function_name: :delete, result: _, adapter_meta: %{stats_counter: ref}}) do
    :ok = Stats.incr(ref, :evictions)
  end

  defp update_stats(%{
         function_name: :execute,
         args: [:delete_all | _],
         result: result,
         adapter_meta: %{stats_counter: ref}
       }) do
    :ok = Stats.incr(ref, :evictions, result)
  end

  defp update_stats(%{function_name: action, result: true, adapter_meta: %{stats_counter: ref}})
       when action in [:expire, :touch] do
    :ok = Stats.incr(ref, :updates)
  end

  defp update_stats(%{
         function_name: :update_counter,
         args: [_, amount, _, default, _],
         result: result,
         adapter_meta: %{stats_counter: ref}
       }) do
    offset = if amount >= 0, do: -1, else: 1

    if result + amount * offset === default do
      :ok = Stats.incr(ref, :writes)
    else
      :ok = Stats.incr(ref, :updates)
    end
  end

  defp update_stats(_), do: :ok
end
