defmodule AMQP.Test.Support.Producer1 do
  @moduledoc nil

  require Logger

  alias AMQP.Producer

  @spec send_payload(map) :: :ok | :error
  def send_payload(payload) do
    Producer.publish("topic1", "amqp.test1", Jason.encode!(payload))
  end
end
