defmodule Endpoint do
  def start(group_name) do
    # Seed the random number generator used later
    :random.seed(:os.timestamp)

    # Enroll the Endpoint
    response = HTTPotion.post "https://osq.herokuapp.com/api/enroll",
      [body: "{\"enroll_secret\": \"#{inspect(self())}:#{group_name}:#{System.get_env("NODE_ENROLL_SECRET")}\"}",
       headers: ["User-Agent": "Elixir", "Content-Type": "application/json"]]
    {:ok, json} = JSON.decode(response.body)
    node_key = json["node_key"]
    spawn(fn -> loop(node_key) end)
  end

  def skew10(number) do
    low = number * 0.9
    high = number * 1.1
    range = high - low
    round (low + (range * :random.uniform))
  end

  defp loop(node_key) do
    # IO.puts "requesting a new config with node key #{node_key}"
    request = HTTPotion.post "https://osq.herokuapp.com/api/config",
      [body: "{\"node_key\": \"#{node_key}\"}",
      headers: ["User-Agent": "Elixir", "Content-Type": "application/json"]]
    # IO.puts request.body
    :timer.sleep(skew10(1000 * 60 * 60)) # Check for updates every hour
    loop(node_key)
  end

  def main(_) do
    if System.get_env("NODE_ENROLL_SECRET") == nil do
      raise "You don't have anything in NODE_ENROLL_SECRET environment var"
    end
    IO.puts "Starting 100 hermes endpoints"
    hermes = 1..100 |> Enum.map(fn(_) -> spawn(fn -> Endpoint.start("hermes") end); :timer.sleep(500) end )

    IO.puts "Starting 100 shogun endpoints"
    shogun = 1..100 |> Enum.map(fn(_) -> spawn(fn -> Endpoint.start("shogun") end); :timer.sleep(500) end )

    IO.puts "Starting 100 runtime endpoints"
    runtime = 1..100 |> Enum.map(fn(_) -> spawn(fn -> Endpoint.start("runtime") end); :timer.sleep(500) end )

    IO.puts "All servers running. CTRL+C to stop."

    receive do
      {:quit} -> IO.puts "quitting"
    end
  end
end
