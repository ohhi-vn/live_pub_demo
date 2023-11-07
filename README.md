# Introduce

This is simple demo for sharing topic "Phoenix LiveView & Pubsub for Realtime & Scable webapp"

## structure of project

Project has two part frontend service & trading service.

Trading service is a simulator stock price & push stock price change to frontend.

Frontend show stock price from simulator by Phoenix LiveView.

Using Phoenix PubSub to transport data from trading to frontend.

## Guide

Run trading_service first

```bash
cd trading_service
iex --cookie demo  --sname trading@localhost -S mix
```

Open new Terminal then run

```bash
cd frontend_service
PORT=4001 iex --cookie demo --sname fe_1@localhost -S mix phx.server
```

Join frontend to trading service from Elixir shell

```Elixir
Node.connect(:trading@localhost)
```

For multi frontend you can start other instance like

```bash
PORT=4002 iex --cookie demo --sname fe_2@localhost -S mix phx.server 
```

and join to trading service by above command.

Open browser then go to: 

dynamic stock list [http://localhost:4001/dynamic_list?from=1&to=1500](http://localhost:4001/dynamic_list?from=1&to=1500)

fixed stock list [http://localhost:4001/fix_list](http://localhost:4001/fix_list)

You can change number of stocks by change `num` in query parameter (from 1 to 10k)
