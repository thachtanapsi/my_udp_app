defmodule MyUdpApp.UDP.Broadway.Producer do
  use GenStage

  require Logger

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    port = Keyword.get(opts, :port)

    {:ok, socket} =
      :gen_udp.open(
        port,
        [:binary, active: true, reuseaddr: true]
      )

    state = %{
      socket: socket,
      queue: :queue.new(),
      demand: 0,
      port: port
    }

    {:producer, state, [buffer_size: :infinity]}
  end

  def handle_demand(incoming_demand, %{demand: demand} = state) do
    dispatch_messages(%{state | demand: demand + incoming_demand})
  end

  def handle_info({:udp, _socket, _ip, _port, msg}, state) do
    message = %Broadway.Message{
      data: %{
        payload: msg
      },
      acknowledger: {Broadway.NoopAcknowledger, nil, nil}
    }

    new_queue = :queue.in(message, state.queue)
    dispatch_messages(%{state | queue: new_queue})
  end

  def handle_info(:show_state, state) do
    Logger.info(
      %{
        message: "++++++++++++++  Show state producer ++++++++++++++",
        queue_length: :queue.len(state.queue),
        demand: state.demand,
        port: state.port
      }
    )

    {:noreply, [], state}
  end

  # Highly optimized version: O(N) dequeue with early stop
  defp dispatch_messages(%{demand: demand, queue: queue} = state) when demand > 0 do
    do_dequeue(queue, demand, [], state)
  end

  defp dispatch_messages(state), do: {:noreply, [], state}

  defp do_dequeue(queue, 0, acc, state) do
    {:noreply, Enum.reverse(acc), %{state | queue: queue, demand: 0}}
  end

  defp do_dequeue(queue, n, acc, state) do
    case :queue.out(queue) do
      {{:value, msg}, new_queue} ->
        do_dequeue(new_queue, n - 1, [msg | acc], state)

      {:empty, _} ->
        {:noreply, Enum.reverse(acc), %{state | queue: queue, demand: n}}
    end
  end
end
