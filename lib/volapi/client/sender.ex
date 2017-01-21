defmodule Volapi.Client.Sender do

  @doc """
  Generic function for sending frames using the Volapi.WebSocket.Server
  """
  def gen_send(frame, room) do
    {:ok, data} = gen_build(frame, room) |> Poison.encode

    IO.puts "HEYO"
    Volapi.WebSocket.Server.reply(data, room)
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
    server_ack = Volapi.Server.Client.get_ack(:server, room)
    client_ack = Volapi.Server.Client.get_ack(:client, room) + client_ack_offset
    [server_ack, [[0, frame], client_ack]]
  end

  def subscribe(nick, room) do
    checksum = Volapi.Util.get_checksum()

    frame = ["subscribe", %{"nick" => nick, "room" => room, "checksum" => checksum, "checksum2" => checksum}]

    gen_send(frame, room)
  end

  def send_message(message, room) do
    nick = Application.get_env(:volapi, :nick)
    send_message(message, nick, room)
  end

  def send_message(message, me: true, room) do
    nick = Application.get_env(:volapi, :nick)

    frame = ["call", %{"fn" => "command", "args" => [nick, "me", message]}]

    gen_send(frame)
  end

  def send_message(message, admin: true, room) do
    nick = Application.get_env(:volapi, :nick)

    frame = ["call", %{"fn" => "command", "args" => [nick, "me", message]}]

    gen_send(frame)
  end

  def send_message(message, opts, room) when opts == admin: false or opts == me: false do
    nick = Application.get_env(:volapi, :nick)

    send_message("I'm a dumb faggot that can't use Volapi correctly. Please rape my face. (Stop using admin: false and me: false with send_message)", nick, room)
  end

  def send_message(message, nick, room) do
    frame = ["call", %{"args" => [nick, message], "fn" => "chat"}]

    gen_send(frame, room)
  end

  def login(session, room) do
    frame = ["call", %{"fn" => "useSession", "args" => [session]}]

    gen_send(frame, room)
  end

  @doc """
  `id` refers to the id key in the %Volapi.Chat{} struct.
  It is only available to room owners.
  """
  def timeout_chat(id, nick, room) do
    frame = ["call", %{"fn" => "timeoutChat", "args" => [id, nick]}]

    gen_send(frame, room)
  end

  @doc """
  `id` refers to the file_id key in any of the %Volapi.File.*{} structs.
  It is only available to room owners.
  """
  def timeout_file(id, nick, room) do
    frame = ["call", %{"fn" => "timeoutFile", "args" => [id, nick]}]

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

  def delete_file(file_id, room) do
    frame = ["call", %{"fn" => "deleteFiles", "args" => [[file_id]]}]

    gen_send(frame, room)
  end
end
