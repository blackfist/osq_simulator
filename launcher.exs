hermes = 1..100 |> Enum.map(fn(_) -> Endpoint.start("hermes"); :timer.sleep(1000) end )
shogun = 1..100 |> Enum.map(fn(_) -> Endpoint.start("shogun"); :timer.sleep(1000) end )
runtime = 1..100 |> Enum.map(fn(_) -> Endpoint.start("runtime"); :timer.sleep(1000) end )
