defmodule Servy.PledgeServer do
  @name :pledge_server

  use GenServer

  defmodule State do
    defstruct cache_size: 3, pledges: []
  end

  # Client Interface
  def start do
    IO.puts("Starting the pldge server...")
    GenServer.start(__MODULE__, %State{}, name: @name)
  end

  def set_cache_size(size) do
    GenServer.cast(@name, {:set_cache_size, size})
  end

  def create_pledge(name, amount) do
    GenServer.call(@name, {:create_pledge, name, amount})
  end

  def recent_pledges do
    GenServer.call(@name, :recent_pledges)
  end

  def total_pledged do
    GenServer.call(@name, :total_pledged)
  end

  def clear do
    GenServer.cast(@name, :clear)
  end

  # Server Callbacks

  def init(state) do
    pledges = fetch_recent_pledges_from_service()
    new_state = %{state | pledges: pledges}
    {:ok, new_state}
  end

  def handle_call({:create_pledge, name, amount}, _from, state) do
    {:ok, id} = send_pledge_to_service(name, amount)
    most_recent_pledges = Enum.take(state.pledges, state.cache_size - 1)
    cahced_pledges = [{name, amount} | most_recent_pledges]
    new_state = %{state | pledges: cahced_pledges}
    {:reply, id, new_state}
  end

  def handle_call(:recent_pledges, _from, state) do
    {:reply, state.pledges, state}
  end

  def handle_call(:total_pledged, _from, state) do
    total = Enum.map(state.pledges, &elem(&1, 1)) |> Enum.sum()
    {:reply, total, state}
  end

  def handle_info(message, state) do
    IO.puts("Cant touch this #{inspect(message)}")
    {:noreply, state}
  end

  def handle_cast(:clear, state) do
    {:noreply, %{state | pledges: []}}
  end

  def handle_cast({:set_cache_size, size}, state) do
    resized_cache = Enum.take(state.pledges, size)
    new_state = %{state | cache_size: size, pledges: resized_cache}
    {:noreply, new_state}
  end

  def send_pledge_to_service(_name, _amount) do
    {:ok, "pledge-${:rand.uniform(1000)}"}
  end

  defp fetch_recent_pledges_from_service do
    # CODE GOES HERE TO FETCH RECENT PLEDGES FROM EXTERNAL SERVICE

    # Example return value:
    [{"wilma", 15}, {"fred", 25}]
  end
end

alias Servy.PledgeServer

{:ok, pid} = PledgeServer.start()

PledgeServer.set_cache_size(4)

send(pid, {:stop, "hammertime"})

# IO.inspect(PledgeServer.create_pledge("Lucy", 10))

# IO.inspect(PledgeServer.clear())

# IO.inspect(PledgeServer.create_pledge("Lucy", 10))
# IO.inspect(PledgeServer.create_pledge("Lucy", 10))
# IO.inspect(PledgeServer.create_pledge("Lucy", 10))
# IO.inspect(PledgeServer.create_pledge("Lucy", 10))

IO.inspect(PledgeServer.recent_pledges())
IO.inspect(PledgeServer.total_pledged())
