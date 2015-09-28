defmodule Endpoint do
  def start(group_name) do
    # Enroll the Endpoint
    response = HTTPotion.post "https://osq.herokuapp.com/api/enroll",
      [body: "{\"enroll_secret\": \"#{inspect(self())}:#{group_name}:#{System.get_env('NODE_ENROLL_SECRET')}\"}",
       headers: ["User-Agent": "Elixir", "Content-Type": "application/json"]]
    {:ok, json} = JSON.decode(response.body)
    node_key = json["node_key"]
    # IO.puts "Running the loop with node key #{node_key}"
    spawn(fn -> loop(node_key) end)
  end

  defp loop(node_key) do
    # IO.puts "requesting a new config with node key #{node_key}"
    request = HTTPotion.post "http://localhost:4567/api/config",
      [body: "{\"node_key\": \"#{node_key}\"}",
      headers: ["User-Agent": "Elixir", "Content-Type": "application/json"]]
    # IO.puts request.body
    :timer.sleep(1000 * 60 * 60) # Check for updates every hour
    loop(node_key)
  end
end
