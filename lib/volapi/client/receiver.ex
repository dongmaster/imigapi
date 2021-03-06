defmodule Imagapi.Client.Receiver do
  import Logger

  # If a frame is sent by the server, the server_ack is the number at the end of the list. The client_ack is the first number
  # If a frame is sent by the client, the reverse applies to the above.

  # Receivers

  @doc """
  The first frame to be received by Imagapi.
  """
  # def parse({:ok, %{"pingInterval" => ping_interval, "pingTimeout" => ping_timeout, "sid" => sid, "upgrades" => upgrades}}, room) do
  #   :timer.apply_interval(ping_interval, __MODULE__, :ping, [room])
  #   :ok
  # end

  # {"type":"CONNECTIONS","data":8}
  def parse(%{"type" => "CONNECTIONS", "data" => data}, room) do
    :timer.apply_interval(60_000 * 2, __MODULE__, :ping, [room])
    :ok
  end

  def parse(%{"type" => "CHAT_MESSAGE", "data" => %{"message" => message, "timestamp" => timestamp, "sender" => sender}}, room) do
    msg = %Imagapi.Message.Chat
    {
      message: message,
      #message: Imagapi.Message.Chat.raw_to_string(message),
      #message_alt: Imagapi.Message.Chat.raw_to_string_alternate(message),
      room: room,
      # self: Map.get(data, "self", false),
      # id: Map.get(data, "id", ""),
      # ip: Map.get(data, "ip", ""),
      # channel: Map.get(data, "channel", ""),
      nick: sender,
      nick_alt: String.downcase(sender),
      # admin: Map.get(options, "admin", false),
      # donator: Map.get(options, "donator", false),
      # profile: Map.get(options, "profile", ""),
      # staff: Map.get(options, "staff", false),
      # user: Map.get(options, "user", false), # This will be phased out/deprecated soon, will be changed to logged_in
      # logged_in: Map.get(options, "user", false),
      # files: Imagapi.Message.Chat.get_files(message), # Files mentioned in the chat message
      # rooms: Imagapi.Message.Chat.get_rooms(message), # Rooms mentioned in the chat message
      timestamp: timestamp
    }

    Imagapi.Server.Client.add_message(msg, room)
  end

  @doc """
  One of the first frames to be received by Imagapi.
  """
  def parse({:ok, %{"version" => version, "session" => session, "ack" => ack}}, room) do
    Imagapi.Server.Client.set_ack(:server, ack, room)
  end

  def parse({:ok, [client_ack | frames]}, room) do
    Imagapi.Server.Client.set_ack(:client, client_ack, room)
    Imagapi.KeepAlive.keep_alive(room)
    parse(frames, room)
  end

  def parse([], room) do
    :ok
  end

  @doc """
  Stores the user count.
  """
  def parse([[[_, ["user_count", user_count]], server_ack] | t], room) do
    Imagapi.Server.Client.set_ack(:server, server_ack, room)
    Imagapi.Server.Client.set_user_count(%Imagapi.Message.UserCount{user_count: user_count, room: room}, room)
    parse(t, room)
  end

  @doc """
  Handles files
  {"type":"NEW_FILE","data":{"name":"1491043308258 - Copy - Copy (5) - Copy.jpg","mimetype":"image/jpeg","cuid":"cj8d5z2oa03m70yp9lrqfhxbo","size":12703,"uploader":"Caw"}}
  """
  def parse(%{"type" => "NEW_FILE", "data" => %{"name" => file_name, "mimetype" => mimetype, "cuid" => cuid, "size" => size, "uploader" => uploader}}, room) do
    #Imagapi.Server.Client.set_ack(:server, server_ack, room)

    #handle_file(files, room)
    #|> Imagapi.Server.Client.add_files(room)

    #parse(t, room)
  end

  @doc """
  Handles deleted files
  {"type":"FILE_DELETED","data":{"fileId":"cj8d5u73v03im0yp9eov4dtr5"}}
  """
  def parse(%{"type" => "FILE_DELETED", "data" => %{"fileId" => file_id}}, room) do
    # Imagapi.Server.Client.set_ack(:server, server_ack, room)

    Imagapi.Server.Client.del_file(file_id, room)
  end

  # def parse([[[_, ["chat", %{"data" => data, "message" => message, "nick" => nick, "options" => options}]], server_ack] | t], room) do
  #   Imagapi.Server.Client.set_ack(:server, server_ack, room)

  #   msg = %Imagapi.Message.Chat
  #   {
  #     raw_message: message,
  #     message: Imagapi.Message.Chat.raw_to_string(message),
  #     message_alt: Imagapi.Message.Chat.raw_to_string_alternate(message),
  #     room: room,
  #     self: Map.get(data, "self", false),
  #     id: Map.get(data, "id", ""),
  #     ip: Map.get(data, "ip", ""),
  #     channel: Map.get(data, "channel", ""),
  #     nick: nick,
  #     nick_alt: String.downcase(nick),
  #     admin: Map.get(options, "admin", false),
  #     donator: Map.get(options, "donator", false),
  #     profile: Map.get(options, "profile", ""),
  #     staff: Map.get(options, "staff", false),
  #     user: Map.get(options, "user", false), # This will be phased out/deprecated soon, will be changed to logged_in
  #     logged_in: Map.get(options, "user", false),
  #     files: Imagapi.Message.Chat.get_files(message), # Files mentioned in the chat message
  #     rooms: Imagapi.Message.Chat.get_rooms(message), # Rooms mentioned in the chat message
  #   }

  #   Imagapi.Server.Client.add_message(msg, room)
  #   parse(t, room)
  # end

  def parse([[[_, ["chat", %{"message" => message, "nick" => nick, "options" => options}]], server_ack] | t], room) do
    parse([[[0, ["chat", %{"data" => %{}, "message" => message, "nick" => nick, "options" => options}]], server_ack] | t], room)
  end

  def parse([[[_, ["subscribed", _]], server_ack] | t], room) do
    Imagapi.Server.Client.set_ack(:server, server_ack, room)

    Imagapi.Server.Util.cast(:connect, %Imagapi.Message.Connected{connected: true, room: room})

    if Application.get_env(:imagapi, :password, nil) != nil and Application.get_env(:imagapi, :auto_login, false) == true do
      Imagapi.Util.login(room)
    end

    parse(t, room)
  end

  def parse([[[_, ["login", name]], server_ack] | t], room) do
    Imagapi.Server.Client.login(%Imagapi.Message.Login{logged_in: true, nick: name, room: room}, room)
    parse(t, room)
  end

  def parse([[[_, ["logout", _]], server_ack] | t], room) do
    Imagapi.Server.Client.logout(%Imagapi.Message.Login{logged_in: false, room: room}, room)
    parse(t, room)
  end

  def parse([[[_, ["owner", %{"owner" => owner}]], server_ack] | t], room) do
    Imagapi.Server.Util.cast(:is_owner, owner)
    parse(t, room)
  end

  def parse([[[_, ["showTimeoutList", timeouts]], server_ack] | t], room) do
    Enum.each(timeouts, fn(%{"id" => id, "name" => name, "date" => date}) ->
      Imagapi.Server.Client.add_timeout(%Imagapi.Message.Timeout{id: id, name: name, date: date}, room)
    end)
    parse(t, room)
  end

  def parse([[[_, ["roomScore", room_score]], server_ack] | t], room) do
    Imagapi.Server.Client.set_config(:room_score, room_score, room)
    parse(t, room)
  end

  def parse([[h, server_ack] | t], room) do
    Imagapi.Server.Client.set_ack(:server, server_ack, room)
    IO.puts("Ignoring the following frame:")
    IO.inspect h
    IO.puts("Ignoring the above frame.")
    parse(t, room)
  end

  def ping(room) do
    Imagapi.WebSocket.Server.volaping(2, room)
  end

  def handle_file(files, room) do
    Enum.map(files, fn
      [file_id, file_name, file_type, file_size, file_expiration_time, file_life_time, metadata, _] ->
        %{user: nick, artist: artist, album: album, ip: ip} =
          case metadata do
            %{"user" => uploader, "artist" => artist, "album" => album} ->
              %{user: uploader, artist: artist, album: album, ip: ""}
            %{"user" => uploader, "artist" => artist} ->
              %{user: uploader, artist: artist, album: "", ip: ""}
            %{"user" => uploader, "album" => album} ->
              %{user: uploader, artist: "", album: album, ip: ""}
            %{"user" => uploader} ->
              %{user: uploader, artist: "", album: "", ip: ""}
            # autism ->
            #   %{user: Map.get(autism, "user", ""), artist: Map.get(autism, "artist", ""), album: Map.get(autism, "album", ""), ip: Map.get(autism, "ip", "")}
            _ ->
              %{user: "", artist: "", album: "", ip: ""}
          end

        %Imagapi.Message.File
        {
          file_id: file_id,
          file_name: file_name,
          file_type: file_type,
          file_size: file_size,
          file_expiration_time: file_expiration_time,
          file_life_time: file_life_time,
          ip: Map.get(metadata, "ip", ""),
          nick: nick,
          nick_alt: String.downcase(nick),
          artist: artist,
          album: album,
          room: room,
        }
      _ ->
        %Imagapi.Message.File{}
    end)
  end
end
