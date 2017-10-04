defmodule Imagapi.Message.Chat do
  # There's a data key in message maps that contains data such as if a message is sent by you (self: true) or IP addresses
  defstruct [
    message: "", # Multi-part. Multiple parts can be witnessed when using newlines in a message and links.
    room: "",
    nick: "",
    nick_alt: "", # Convenience key. Useful for pattern matching. It's just the nick downcased.
    timestamp: "",
  ]

  def raw_to_string(raw_message) do
    Enum.map_join(raw_message, "", fn
      %{"type" => "text", "value" => value} ->
        value
      %{"type" => "url", "text" => value} ->
        value
      %{"type" => "break"} ->
        "\n"
      %{"type" => "file", "id" => id} -> # There's a third key in this map called "name" which includes the name of the file.
        "@#{id}"
      %{"type" => "room", "id" => id} -> # Same as the comment about about the file message type.
        "##{id}"
      %{"value" => value} ->
        value
      _ ->
        ""
    end)
  end

  @doc """
  Alternate version of the raw_to_string function where filenames and room names are outputted to the string, instead of the file id and room id.
  """
  def raw_to_string_alternate(raw_message) do
    Enum.map_join(raw_message, "", fn
      %{"type" => "text", "value" => value} ->
        value
      %{"type" => "url", "text" => value} ->
        value
      %{"type" => "break"} ->
        "\n"
      %{"type" => "file", "name" => name} -> # There's a third key in this map called "name" which includes the name of the file.
        name
      %{"type" => "room", "name" => name} -> # Same as the comment about about the file message type.
        name
      %{"value" => value} ->
        value
      _ ->
        ""
    end)
  end

  def get_files(raw_message) do
    for %{"type" => type, "id" => id} when type === "file" <- raw_message do
      id
    end
  end

  def get_rooms(raw_message) do
    for %{"type" => type, "id" => id} when type === "room" <- raw_message do
      id
    end
  end
end
