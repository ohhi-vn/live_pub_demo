# Introduce

This is simple demo for sharing topic "Phoenix LiveView & Pubsub for Realtime & Scable webapp"

## structure of project

Project has two part frontend service & trading service.

## Guide

Run trading_service first

```bash
cd trading_service
iex --cookie demo  --sname trading@localhost -S mix
```

Open new Terminal then run

```bash
cd frontend_service
iex --cookie demo --sname fe_1@localhost -S mix phx.server
```

Join frontend to trading service from Elixir shell

```Elixir
Node.connect(:trading@localhost)
 ```

Open browser then go to [http://127.0.0.1:4000/stocks?num=10](http://127.0.0.1:4000/stocks?num=10)

You can change number of stocks by change `num` in query parameter (from 1 to 10k)
