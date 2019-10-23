defmodule AMQP.Test.Support.Producer3 do
  @moduledoc nil

  require Logger

  alias AMQP.Producer

  @spec send_payload(map) :: :ok | :error
  def send_payload(payload) do
    Producer.publish("test_exchange", "", Jason.encode!(payload))
  end
end
