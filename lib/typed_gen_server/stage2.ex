defmodule TypedGenServer.Stage2.Server do
  use GenServer
  use GradualizerEx.TypeAnnotation
  alias Stage2.TypedServer

  ## Start IEx with:
  ##   iex -S mix run --no-start
  ##
  ## Then use the following to recheck the file on any change:
  ##   recompile(); GradualizerEx.type_check_file(:code.which( TypedGenServer.Stage2.Server ), [:infer])

  @opaque t :: pid()

  ## Try switching between the definitions and see what happens
  @type message :: Contract.Echo.req() | Contract.Hello.req()
  #@type message :: Contract.Echo.req()
  #@type message :: {:echo_req, String.t()} | {:hello, String.t()}

  @type state :: map()

  @spec start_link() :: {:ok, t()} | :ignore | {:error, {:already_started, t()} | any()}
  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  @spec echo(t(), String.t()) :: String.t()
  # @spec echo(t(), String.t()) :: {:echo_req, String.t()}
  def echo(pid, message) do
    case annotate_type( GenServer.call(pid, {:echo_req, message}), Contract.Echo.res() ) do
    #case call_echo(pid, message) do
      ## Try changing the pattern or the returned response
      {:echo_res, response} -> response
    end
  end

  ## This could be generated based on present handle clauses - thanks, Robert!
  @spec call_echo(t(), String.t()) :: Contract.Echo.res()
  defp call_echo(pid, message) do
    GenServer.call(pid, {:echo_req, message})
  end

  @spec hello(t(), String.t()) :: :ok
  def hello(pid, name) do
    case GenServer.call(pid, {:hello, name}) |> annotate_type(Contract.Hello.res()) do
      :ok -> :ok
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(m, from, state) do
    {:noreply, handle(m, from, state)}
  end

  @spec handle(message(), any, any) :: state()
  ## Try breaking the pattern match, e.g. by changing 'echo_req'
  def handle({:echo_req, payload}, from, state) do
    ## This could register {:echo_req, payload} <-> {:echo_res, payload} mapping
    ## and response type at compile time to generate call_echo() automatically.
    ## Thanks Robert!
    #TypedServer.reply( from, {:echo_res, payload}, Contract.Echo.res() )
    GenServer.reply( from, {:echo_res, payload} )
    state
  end

  ## Try commenting out the following clause
  def handle({:hello, name}, from, state) do
    IO.puts("Hello, #{name}!")
    GenServer.reply(from, :ok)
    state
  end
end

defmodule Test.TypedGenServer.Stage2.Server do
  alias TypedGenServer.Stage2.Server

  ## Typecheck with:
  ##   recompile(); GradualizerEx.type_check_file(:code.which( Test.TypedGenServer.Stage2.Server ), [:infer])

  @spec test :: any()
  def test do
    {:ok, srv} = Server.start_link()
    pid = self()
    "payload" = Server.echo(srv, "payload")
    ## This won't typecheck, since Server.echo only accepts Server.t(), that is our Server pids
    #"payload" = Server.echo(pid, "payload")
  end
end
