defmodule Imagapi.Client.Sender do
  @short 1800
  @medium 7200
  @long 86400

  @doc """
  Generic function for sending frames using the Imagapi.WebSocket.Server
  """
  def gen_send(frame, room) do
    # {:ok, data} = gen_build(frame, room) |> Poison.encode
    {:ok, data} = Poison.encode(frame)

    Imagapi.WebSocket.Server.reply(data, room)
  end

  @doc """
  Convenience function for building your own frames.
  Adds 1 to the client_ack automatically.
  """
  def gen_build(frame, room) do
    gen_build(frame, 1, room)
  end

  @doc """
  Convenience function for building your own frames.
  Takes a second parameter so you can decide your own client_ack offset.

  Be wary when using this so you don't set a wrong client_ack.
  """
  def gen_build(frame, client_ack_offset, room) do
    server_ack = Imagapi.Server.Client.get_ack(:server, room)
    client_ack = Imagapi.Server.Client.get_ack(:client, room) + client_ack_offset
    [server_ack, [[0, frame], client_ack]]
  end

  @doc """
  Special internal function that should hopefully keep the connection alive.
  """
  def keep_alive(room) do
    # {:ok, data} = [Imagapi.Server.Client.get_ack(:server, room)] |> Poison.encode

    # Imagapi.WebSocket.Server.reply(data, room)
  end

  def subscribe(nick, room) do
    checksum = Imagapi.Util.get_checksum()

    frame = ["subscribe", %{"nick" => nick, "room" => room, "checksum" => checksum, "checksum2" => checksum}]

    gen_send(frame, room)
  end

  def send_message(message, room) do
    nick = Application.get_env(:imagapi, :nick)
    send_message(message, nick, room)
  end

  def send_message(message, :me, room) do
    nick = Application.get_env(:imagapi, :nick)

    frame = ["call", %{"fn" => "command", "args" => [nick, "me", message]}]

    # gen_send(frame, room)
  end

  def send_message(message, :admin, room) do
    nick = Application.get_env(:imagapi, :nick)

    frame = ["call", %{"fn" => "command", "args" => [nick, "a", message]}]

    # gen_send(frame, room)
  end

  def send_message(message, nick, room) do
    #frame = ["call", %{"args" => [nick, message], "fn" => "chat"}]
    frame = %{"type" => "CHAT_MESSAGE", "data" => %{"message" => message, "timestamp" => "2017-10-04T00:00:00.000Z", "sender" => nick}}
    # {"type":"CHAT_MESSAGE","data":{"message":"incognito still uses cookies","timestamp":"2017-10-04T15:17:51.138Z","sender":"Soniwoh"}}
    gen_send(frame, room)
  end

  def login(session, room) do
    frame = ["call", %{"fn" => "useSession", "args" => [session]}]

    gen_send(frame, room)
  end

  def timeout_chat(id, nick, :short, room) do
    timeout_chat(id, nick, @short, room)
  end

  def timeout_chat(id, nick, :medium, room) do
    timeout_chat(id, nick, @medium, room)
  end

  def timeout_chat(id, nick, :long, room) do
    timeout_chat(id, nick, @long, room)
  end

  def timeout_chat(id, nick, room) do
    timeout_chat(id, nick, @medium, room)
  end

  @doc """
  `id` refers to the id key in the %Imagapi.Chat{} struct.
  It is only available to room owners.

  The seconds argument can also be :short, :medium and :long.
  """
  def timeout_chat(id, nick, seconds, room) do
    frame = ["call", %{"fn" => "timeoutChat", "args" => [id, nick, seconds]}]

    gen_send(frame, room)
  end


  def timeout_file(id, nick, :short, room) do
    timeout_file(id, nick, @short, room)
  end

  def timeout_file(id, nick, :medium, room) do
    timeout_file(id, nick, @medium, room)
  end

  def timeout_file(id, nick, :long, room) do
    timeout_file(id, nick, @long, room)
  end

  def timeout_file(id, nick, room) do
    timeout_file(id, nick, @medium, room)
  end

  @doc """
  `id` refers to the file_id key in any of the %Imagapi.File.*{} structs.
  It is only available to room owners.
  """
  def timeout_file(id, nick, seconds, room) do
    frame = ["call", %{"fn" => "timeoutFile", "args" => [id, nick, seconds]}]

    gen_send(frame, room)
  end

  @doc """
  The id returned by this is always a chat id, so use `timeout_chat` on id's that come from this function.
  """
  def get_timeouts(room) do
    frame = ["call", %{"fn" => "requestTimeoutList", "args" => []}]

    gen_send(frame, room)
  end

  def ban_user(ip, ban_opts, room) do
    frame = ["call", %{"fn" => "banUser", "args" => [ip, ban_opts]}]

    gen_send(frame, room)
  end

  def unban_user(ip, ban_opts, room) do
    frame = ["call", %{"fn" => "unbanUser", "args" => [ip, ban_opts]}]

    gen_send(frame, room)
  end

  def delete_file(file_id, room) do
    frame = ["call", %{"fn" => "deleteFiles", "args" => [[file_id]]}]

    gen_send(frame, room)
  end
end
