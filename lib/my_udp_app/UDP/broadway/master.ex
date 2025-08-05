defmodule MyUdpApp.UDP.Broadway.Master do
  require Logger

  use Broadway
  alias Broadway.Message

  def start_link(_opts) do

    Broadway.start_link(__MODULE__,
      name: MyUdpApp.UDP.Broadway.Producer,
      producer: [
        module:
          {MyUdpApp.UDP.Broadway.Producer,
           [port: 5000]},
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 1000, hibernate_after: 15000, max_demand: 1]
      ]
    )
  end

  # process message
  def handle_message(_, %Message{data: _data} = msg, _ctx) do
    # Logger.info("Received message: #{inspect(data)}")

    # use some function to slow handle
    Process.sleep(100)
    msg
  end

end
