# OSQuery Endpoint Simulator

If you're testing some software that will provide configurations to osquery
endpoints but you don't want to spin up hundres of virtual machines, you can
use this code (with some modifications) to simulate as many endpoints as you
want. They generate the traffic that an endpoint would generate and you can
see how your server is responding.

## Set up

1. Clone the repo
2. Put a value in environment variable NODE_ENROLL_SECRET
3. From bash `mix deps.get`
4. From bash `iex -S mix`

## Running
Launcher script is built by running `mix Escript.Build`. That creates an executable
called start_servers which you can run on any machine that has erlang installed. If
you don't change anything in this code, it will create 100 machines in 3 groups,
named "hermes", "shogun", and "runtime". Each machine will check in for updates
every hour.

Another simple way to start one endpoint is `iex -S mix` and then
 `Endpoint.start("some string")`

If you want 100 endpoints you can use this bit of code:

`hermes = 1..100 |> Enum.map(fn(_) -> Endpoint.start("hermes"); :timer.sleep(1000) end )`

That will create a pool of 100 endpoints all in the variable named hermes. There is a
one second delay between creation of each endpoint so you don't overload the server
with 100 endpoints all trying to enroll at once.

## Modifying for your needs
Look in lib/endpoint.ex. You'll need to change the url that the endpoints will
try to reach. Also you migth want to change the format of the enroll string that
is being sent since right now it is based on windmill.
