defmodule Servy.PledgeGenericServer do
  def start(callback_module, initial_state, name) do
    pid = spawn(__MODULE__, :listen_loop, [initial_state, callback_module])
    Process.register(pid, name)
    pid
  end

  def call(pid, message) do
    send(pid, {:call, self(), message})

    receive do
      {:response, response} ->
        response
    end
  end

  def cast(pid, message) do
    send(pid, {:cast, message})
  end

  def listen_loop(state, callback_module) do
    receive do
      {:call, sender, message} when is_pid(sender) ->
        {response, new_state} = callback_module.handle_call(message, state)
        send(sender, {:response, response})
        listen_loop(new_state, callback_module)

      {:cast, message} ->
        new_state = callback_module.handle_cast(message, state)
        listen_loop(new_state, callback_module)

      other ->
        new_state = callback_module.handle_info(other, state)
        listen_loop(new_state, callback_module)
    end
  end
end

defmodule Servy.PledgeServerHandRolled do
  @name :pledge_server_hand_rolled

  alias Servy.PledgeGenericServer

  # Client Interface
  def start do
    IO.puts("Starting the pldge server...")
    PledgeGenericServer.start(__MODULE__, [], @name)
  end

  def create_pledge(name, amount) do
    PledgeGenericServer.call(@name, {:create_pledge, name, amount})
  end

  def recent_pledges do
    PledgeGenericServer.call(@name, :recent_pledges)
  end

  def total_pledged do
    PledgeGenericServer.call(@name, :total_pledged)
  end

  def clear do
    PledgeGenericServer.cast(@name, :clear)
  end

  # Server Callbacks

  def handle_call({:create_pledge, name, amount}, state) do
    {:ok, id} = send_pledge_to_service(name, amount)
    most_recent_pledges = Enum.take(state, 2)
    new_state = [{name, amount} | most_recent_pledges]
    {id, new_state}
  end

  def handle_call(:recent_pledges, state) do
    {state, state}
  end

  def handle_call(:total_pledged, state) do
    total = Enum.map(state, &elem(&1, 1)) |> Enum.sum()
    {total, state}
  end

  def handle_cast(:clear, _state) do
    []
  end

  def handle_info(other, state) do
    IO.puts("Unexpected message: #{inspect(other)}")
    state
  end

  def send_pledge_to_service(_name, _amount) do
    {:ok, "pledge-${:rand.uniform(1000)}"}
  end
end

# alias Servy.PledgeServerHandRolled

# PledgeServerHandRolled.start()

# IO.inspect(PledgeServerHandRolled.create_pledge("Lucy", 10))
# IO.inspect(PledgeServerHandRolled.create_pledge("Lucy", 10))
# IO.inspect(PledgeServerHandRolled.create_pledge("Lucy", 10))
# IO.inspect(PledgeServerHandRolled.create_pledge("Lucy", 10))

# IO.inspect(PledgeServerHandRolled.recent_pledges())
# IO.inspect(PledgeServerHandRolled.total_pledged())

# IO.inspect(PledgeServerHandRolled.clear())
# IO.inspect(PledgeServerHandRolled.recent_pledges())
