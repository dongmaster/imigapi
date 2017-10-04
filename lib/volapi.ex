defmodule Imagapi do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false


    :pg2.start
    :pg2.create(:modules)
    :ets.new(:modules, [:set, :named_table, :public, {:read_concurrency, true}, {:write_concurrency, true}])

    tables = Application.get_env(:imagapi, :ets_tables, [])

    Enum.each(tables, fn
      {table, options} ->
        Imagapi.Util.load_table(table, options)
      table when is_atom(table) ->
        Imagapi.Util.load_table(table)
    end)

    children = [
      #worker(Imagapi.Server, []),
      #worker(Imagapi.WebSocket.Server, [url]),
      supervisor(Imagapi.Server.Supervisor, []),
      supervisor(Imagapi.WebSocket.Supervisor, []),
      supervisor(Imagapi.KeepAlive.Supervisor, []),
      supervisor(Imagapi.Module.Supervisor, [[name: Imagapi.Module.Supervisor]])
    ]

    opts = [strategy: :one_for_one, name: Imagapi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

