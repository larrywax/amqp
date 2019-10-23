defmodule AMQP.Test.Support.Consumer1 do
  @moduledoc nil
  @behaviour AMQP.Consumer

  alias AMQP.Basic
  alias AMQP.Helper

  @config Application.get_env(:amqp, __MODULE__)
  @queue Application.get_env(:amqp, __MODULE__)[:queue]

  def setup(channel) do
    Helper.declare(channel, @config)
    Basic.consume(channel, @queue, self())
    {:ok, %{}}
  end

  def handle_message(_payload, _meta, state) do
    {:ok, state}
  end
end
