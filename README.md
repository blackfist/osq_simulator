# OSQuery Endpoint Simulator

If you're testing some software that will provide configurations to osquery
endpoints but you don't want to spin up hundres of virtual machines, you can
use this code (with some modifications) to simulate as many endpoints as you
want. They generate the traffic that an endpoint would generate and you can
see how your server is responding.

## Set up

1. Clone the repo
2. Make sure you have erlang installed
3. Copy `config.yaml.example` to `config.yaml`
4. Edit `config.yaml` to taste
5. run `./start_servers`

## Configuration

The file `config.yaml` will set the base url that osq_simulator will try to
contact to enroll the fake servers. This should be the dns address of the server
with a protocol on the front, such as `http://localhost:4567`.

Osquery servers will normally try to enroll using an enroll secret value which
is also set in `config.yaml`.

If you're using this with a server like [windmill](https://github.com/heroku/windmill)
which takes the id and group with the enroll secret then in your `config.yaml` file
make sure to set `send_id` and `send_group` to true.

Finally, in the groups variable, set a group name and the number of endpoints
you want from that group.
