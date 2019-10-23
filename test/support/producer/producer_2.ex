defmodule AMQP.Test.Support.Producer2 do
  @moduledoc nil

  require Logger

  alias AMQP.Producer

  @spec send_payload(map) :: :ok | :error
  def send_payload(payload) do
    Producer.publish("topic2", "amqp.test2", Jason.encode!(payload), type: "ciao")
  end
end
