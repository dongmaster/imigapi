defmodule Imagapi.WebSocket.Server do
  require Logger
  @behaviour :websocket_client
  @volafile_wss_url "wss://#{Application.get_env(:imagapi, :server, "api.imig.es")}/?r=<%= room %>"

  # wss://api.imig.es/?r=JdfylP2
  defstruct [
    room: "",
    connected: false,
  ]

  # Client API

  def start_link(room) do
    url = generate_wss_url(@volafile_wss_url, room)

    cookie = Imagapi.Util.get_cookie(room)

    # result = {:ok, pid} =
    #   if Application.get_env(:imagapi, :password, nil) != nil and Application.get_env(:imagapi, :auto_login, false) === true do
    #     case Imagapi.Util.get_login_key(room) do
    #       {:error, message} ->
    #         Logger.error(message)
    #         :websocket_client.start_link(url, __MODULE__, %__MODULE__{room: room})
    #       {:success, key} ->
    #         :websocket_client.start_link(url, __MODULE__, %__MODULE__{room: room}, [{:extra_headers, [{"Cookie", "session=#{key}"}]}])
    #     end
    #   else
    #     :websocket_client.start_link(url, __MODULE__, %__MODULE__{room: room})
    #   end


    result = {:ok, pid} = :websocket_client.start_link(url, __MODULE__, %__MODULE__{room: room}, [{:extra_headers, [
                                                                                                      {"Cookie", cookie},
                                                                                                      {"Host", "api.imig.es"},
                                                                                                      {"Origin", "https://imig.es"},
                                                                                                    ]}])

    :global.register_name(this(room), pid)
    result
  end

  def this(room) do
    "volapi_wss_" <> room
  end

  def volaping(ping_reply, room) do
    :global.send(this(room), {:imagaping, %{"type" => "PING"}})
  end

  # There are two ack's.
  # One is used for when the client (volapi) sends something and the other is used for when the server (volafile) sends something.
  def reply(data, room) do
    :global.send(this(room), {:text, {:reply, data}})
    :ok
  end

  # Don't know which one is best for piping so I'm just creating a reverse function.
  # rreply means reverse reply
  def rreply(room, data) do
    reply(room, data)
  end

  def generate_wss_url(volafile_wss_url, room) do
    # rn = Imagapi.Util.random_id(10)
    # t = Imagapi.Util.random_id(7)
    # cs = Imagapi.Util.get_checksum()
    # nick = Application.get_env(:imagapi, :nick)

    EEx.eval_string(volafile_wss_url, [room: room])
  end

  # Server API

  def init(state) do
    {:once, state}
  end

  def onconnect(_wsreq, state) do
    # IO.inspect wsreq
    {:ok, %{state | connected: true}}
  end

  def ondisconnect({_, reason}, state) do
    Logger.error("[!!!] The websocket connection was closed! Reconnecting...")
    IO.inspect reason, label: "Reason for disconnect"
    Imagapi.Server.Client.set_config(:files, %Imagapi.Server{}.files, state.room)
    Process.sleep(6000)
    # {:reconnect, %{state | connected: false}}
    {:close, reason, %{state | connected: false}}
  end

  def websocket_handle({:pong, _}, _conn_state, state) do
    {:ok, state}
  end

  def websocket_handle({:text, data}, _conn_state, state) do
    Logger.debug(data)

    Imagapi.Client.Receiver.parse(Poison.decode!(data), state.room)
    {:ok, state}
  end

  def websocket_handle({:text, << "0" :: binary, data :: binary >>}, _conn_state, state) do
    Logger.debug("0DATA: #{data}")

    Imagapi.Client.Receiver.parse(Poison.decode(data), state.room)
    {:ok, state}
  end

  def websocket_handle({:text, << "4" :: binary, data :: binary >>}, _conn_state, state) do
    Logger.debug("4DATA: #{data}")

    Imagapi.Client.Receiver.parse(Poison.decode(data), state.room)
    {:ok, state}
  end


  def websocket_info({:imagaping, ping_reply}, _conn_state, state) do
    if state.connected == true do
      {:reply, {:text, ping_reply}, state}
    else
      Process.send_after(self(), {:imagaping, ping_reply}, 3000)
      {:ok, state}
    end
  end

  def websocket_info({:text, {:reply, data}}, _conn_state, state) do
    Logger.debug("REPLY: #{data}")

    if state.connected == true do
      {:reply, {:text, data}, state}
    else
      Process.send_after(self(), {:text, {:reply, data}}, 3000)
      {:ok, state}
    end
  end

  def websocket_info(something, _conn_state, state) do
    IO.puts "help does this execute? how about this"
    IO.inspect(something)
    {:ok, state}
  end

  def websocket_terminate(reason, conn_state, state) do
    IO.puts "Terminated! Reason: #{reason}"
    :ok
  end

end
