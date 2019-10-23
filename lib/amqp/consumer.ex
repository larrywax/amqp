defmodule AMQP.Consumer do
  @moduledoc """
  Generic implementation of AMQP consumer
  """
  require Logger
  use GenServer
  import AMQP.Core
  alias AMQP.{Channel, Basic}

  defstruct [
    :channel,
    :handler_module,
    :handler_state,
    prefetch_count: 50,
    backoff: 5_000
  ]

  @type state() :: %__MODULE__{}

  @callback setup(Channel.t()) :: {:ok, map()} | {:error, any()}
  @callback handle_message(any(), map(), map()) :: {:ok, map()} | {:error, any()}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    state = struct(__MODULE__, opts)
    Process.send(self(), :setup, [])
    {:ok, state}
  end

  def handle_info(
        :setup,
        %{
          backoff: backoff,
          prefetch_count: prefetch_count,
          handler_module: handler_module
        } = state
      ) do
    case GenServer.call(AMQPConnectionManager, :get_connection) do
      nil ->
        :timer.sleep(backoff)
        {:stop, :not_ready, state}

      connection ->
        {:ok, channel} = Channel.open(connection)
        Process.monitor(channel.pid)
        state = %{state | channel: channel}

        Basic.qos(channel, prefetch_count: prefetch_count)

        {:ok, handler_state} = handler_module.setup(channel)
        state = %{state | handler_state: handler_state}

        {:noreply, state}
    end
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:"basic.consume_ok", _consumer_tag}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:"basic.cancel", _consumer_tag}, state) do
    {:stop, :basic_cancel, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:"basic.cancel_ok", _consumer_tag}, state) do
    {:stop, :basic_cancel_ok, state}
  end

  def handle_info(
        {basic_deliver(
           consumer_tag: consumer_tag,
           delivery_tag: delivery_tag,
           redelivered: redelivered,
           exchange: exchange,
           routing_key: routing_key
         ),
         amqp_msg(
           props:
             p_basic(
               content_type: content_type,
               content_encoding: content_encoding,
               headers: headers,
               delivery_mode: delivery_mode,
               priority: priority,
               correlation_id: correlation_id,
               reply_to: reply_to,
               expiration: expiration,
               message_id: message_id,
               timestamp: timestamp,
               type: type,
               user_id: user_id,
               app_id: app_id,
               cluster_id: cluster_id
             ),
           payload: payload
         )},
        state
      ) do
    meta = %{
      consumer_tag: consumer_tag,
      delivery_tag: delivery_tag,
      redelivered: redelivered,
      exchange: exchange,
      routing_key: routing_key,
      content_type: content_type,
      content_encoding: content_encoding,
      headers: headers,
      persistent: delivery_mode == 2,
      priority: priority,
      correlation_id: correlation_id,
      reply_to: reply_to,
      expiration: expiration,
      message_id: message_id,
      timestamp: timestamp,
      type: type,
      user_id: user_id,
      app_id: app_id,
      cluster_id: cluster_id
    }

    {:noreply, handle_message(payload, meta, state)}
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, state) do
    Logger.error("Monitored channel process crashed: #{inspect(reason)}")
    {:stop, :channel_exited, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state), do: {:stop, :EXIT, state}

  def handle_info({:error, reason, _pid}, state), do: {:stop, reason, state}

  def handle_info(message, state) do
    Logger.warn("Unknown message received #{inspect(message)}")
    {:noreply, state}
  end

  def terminate(_, %__MODULE__{channel: nil}), do: nil

  def terminate(_, %__MODULE__{channel: channel}) do
    if Process.alive?(channel.pid) do
      Channel.close(channel)
    end
  end

  defp handle_message(
         message,
         %{delivery_tag: tag, redelivered: redelivered} = meta,
         %__MODULE__{
           handler_module: handler_module,
           handler_state: handler_state,
           backoff: backoff
         } = state
       ) do
    try do
      {:ok, handler_state} = handler_module.handle_message(message, meta, handler_state)
      Basic.ack(state.channel, tag)
      %{state | handler_state: handler_state}
    rescue
      e in _ ->
        Logger.error(inspect(e))

        Task.start(fn ->
          :timer.sleep(backoff)
          Basic.reject(state.channel, tag, requeue: !redelivered)
        end)

        state
    end
  end
end