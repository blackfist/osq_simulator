defmodule Endpoint do
  @base_url  "https://osq.herokuapp.com"
  def start(group_name) do
    # Enroll the Endpoint
    try do
      response = HTTPotion.post "#{@base_url}/api/enroll",
        [body: "{\"enroll_secret\": \"#{inspect(self())}:#{group_name}:#{System.get_env("NODE_ENROLL_SECRET")}\"}",
         headers: ["User-Agent": "Elixir", "Content-Type": "application/json"]]

      case JSON.decode(response.body) do
        {:ok, json} ->
          case json do
            %{"node_invalid" => _} ->
              raise "invalid node_key. Does NODE_ENROLL_SECRET match what the server is using?"
            %{"node_key" => node_key} ->
              spawn(fn -> loop(node_key) end)
            _ ->
              raise "Response from server was not node_invalid or node_key"
          end
        _ ->
          raise "Unable to JSON.decode the response from the server"
      end
#      logdebug inspect(json)
#      node_key = json["node_key"]
#      spawn(fn -> loop(node_key) end)
    rescue
      e in HTTPotion.HTTPError -> logdebug "Error enrolling at #{@base_url}/api/enroll: #{e.message}"
      e in RuntimeError -> logdebug "Error enrolling at #{@base_url}/api/enroll: #{e.message}"
      _error -> logdebug "Got a generic error while enrolling at #{@base_url}/api/enroll"
    end

  end

  defp skew10(number) do
    low = number * 0.9 |> round
    high = number * 1.1 |> round
    range = high - low |> round
    low + :rand.uniform(range)
  end

  defp logdebug(message) do
    if System.get_env("OSQ_DEBUG") != nil do
      IO.puts message
    end
  end

  defp msec_to_min(number) do
    number / 60 / 1000 |> round
  end

  defp loop(node_key) do
    logdebug("process #{inspect(self())} requesting a new config with node key #{node_key}")
    try do
      response = HTTPotion.post "#{@base_url}/api/config",
        [body: "{\"node_key\": \"#{node_key}\"}",
        headers: ["User-Agent": "Elixir", "Content-Type": "application/json"]]

      case JSON.decode(response.body) do
        {:ok, json} ->
          sleep_for = skew10(1000 * 60 * 60)
          logdebug("process #{inspect(self())} sleeping for #{round(sleep_for / 60)} seconds. (#{msec_to_min(sleep_for)} minutes)")
          :timer.sleep(sleep_for) # Check for updates every hour
        _ ->
          raise "Unable to JSON.decode the response from the server"
      end

    rescue
      e in HTTPotion.HTTPError -> logdebug "Error getting config from #{@base_url}/api/config: #{e.message}"; :timer.sleep(:rand.uniform(120*1000))
      _error -> logdebug "Got a generic while trying to get config update from #{@base_url}/api/enroll"; :timer.sleep(:rand.uniform(120*1000))
    end

    loop(node_key) # error or not, we will try again after sleeping for some amount of time
  end

  def main(_) do
    if System.get_env("OSQ_DEBUG") == nil do
      IO.puts "Debuggin mode not set. Activate by putting any value into OSQ_DEBUG environment variable."
    end

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
