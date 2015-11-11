defmodule Endpoint do
  def start(group_name) do
    # Enroll the Endpoint
    final_secret = ""
    if Application.get_env(:osq_simulator, :send_id, false) == true do
      final_secret = final_secret <> "#{inspect(self())}:"
    end
    if Application.get_env(:osq_simulator, :send_group, false) == true do
      final_secret = final_secret <> "#{group_name}:"
    end
    final_secret = final_secret <> to_string(Application.get_env(:osq_simulator, :enroll_secret))

    logdebug "Secret being sent to server is: #{final_secret}"

    try do
      response = HTTPotion.post "#{Application.get_env(:osq_simulator, :base_url)}/api/enroll",
        [body: "{\"enroll_secret\": \"#{final_secret}\"}",
         headers: ["User-Agent": "Elixir", "Content-Type": "application/json"]]

      logdebug(response.body)

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

    rescue
      e in HTTPotion.HTTPError -> logdebug "Error enrolling #{group_name} at #{Application.get_env(:osq_simulator, :base_url)}/api/enroll: #{e.message}"
      e in RuntimeError -> logdebug "Error enrolling at #{Application.get_env(:osq_simulator, :base_url)}/api/enroll: #{e.message}"
      _error -> logdebug "Got a generic error while enrolling at #{Application.get_env(:osq_simulator, :base_url)}/api/enroll"
    end

  end

  defp skew10(number) do
    low = number * 0.9 |> round
    high = number * 1.1 |> round
    range = high - low |> round
    low + :rand.uniform(range)
  end

  defp logdebug(message) do
    if Application.get_env(:osq_simulator, :debug, false) == true do
      IO.puts message
    end
  end

  defp msec_to_min(number) do
    number / 60 / 1000 |> round
  end

  defp loop(node_key) do
    logdebug "process #{inspect(self())} requesting a new config with node key #{node_key}"
    try do
      response = HTTPotion.post "#{Application.get_env(:osq_simulator, :base_url)}/api/config",
        [body: "{\"node_key\": \"#{node_key}\"}",
        headers: ["User-Agent": "Elixir", "Content-Type": "application/json"]]

      case JSON.decode(response.body) do
        {:ok, json} ->
          sleep_for = skew10(1000 * 60 * 60)
          logdebug "process #{inspect(self())} sleeping for #{round(sleep_for / 60)} seconds. (#{msec_to_min(sleep_for)} minutes)"
          :timer.sleep(sleep_for) # Check for updates every hour
        _ ->
          raise "Unable to JSON.decode the response from the server"
      end

    rescue
      e in HTTPotion.HTTPError -> logdebug("Error getting config from #{Application.get_env(:osq_simulator, :base_url)}/api/config: #{e.message}"); :timer.sleep(:rand.uniform(120*1000))
      _error -> logdebug("Got a generic while trying to get config update from #{Application.get_env(:osq_simulator, :base_url)}/api/enroll"); :timer.sleep(:rand.uniform(120*1000))
    end

    loop(node_key) # error or not, we will try again after sleeping for some amount of time
  end

  def launcher(name, size) do
    1..size |> Enum.map(fn(_) -> spawn(fn -> Endpoint.start(name) end); :timer.sleep(Application.get_env(:osq_simulator, :sleep_time, 500)) end )
  end

  def main(_) do
    try do
      [ config | _ ] = :yamerl_constr.file("config.yaml")
      Application.put_env(:osq_simulator, :base_url, :proplists.get_value('base_url', config))
      Application.put_env(:osq_simulator, :enroll_secret, :proplists.get_value('enroll_secret', config))
      Application.put_env(:osq_simulator, :debug, :proplists.get_value('debug', config))
      Application.put_env(:osq_simulator, :groups, :proplists.get_value('groups', config))
      Application.put_env(:osq_simulator, :send_id, :proplists.get_value('send_id', config))
      Application.put_env(:osq_simulator, :send_group, :proplists.get_value('send_group', config))

      if Application.get_env(:osq_simulator, :debug) != true do
        IO.puts "Debugging mode not set. Activate by setting debug to true in config/config.exs."
      end

      if Application.get_env(:osq_simulator, :enroll_secret, "unset") == "unset" do
        raise "You don't have anything set in config/config.exs for enroll_secret"
      end

      Application.get_env(:osq_simulator, :groups) |> Enum.each(fn(x) -> {name, size} = x; Endpoint.launcher(name, size); end)

      receive do
        {:quit} -> IO.puts "quitting"
      end
    catch
      {_, longerr} -> [inner] = longerr; elem(inner, 2) |> to_string |> raise
    end
  end
end
