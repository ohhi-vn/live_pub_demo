# Introduce

This is simple demo for sharing topic "Phoenix LiveView & Pubsub for Realtime & Scable webapp".

Project start from old version of Phoenix and converted to version 1.7.

## structure of project

Project has two app, frontend service & trading service. Two apps join together in cluster.

Trading service is a simulator stock price & push price change to frontend.

Frontend show stock price from simulator by Phoenix LiveView. We can add more frontends if needed.

Using Phoenix PubSub to transport data between trading to frontend.

### Cluster

One frontend:

```mermaid
graph LR
    Frontend(Frontend) -->|subs stocks| Trading(Trading)
    Trading-->|update stock| Frontend
```

multi frontends:

```mermaid
graph LR
    Frontend_1(Frontend_1) <--> Trading(Trading)
    Frontend_2(Frontend_2) <--> Trading(Trading)
    Frontend_3(Frontend_3) <--> Trading(Trading)
```

### Flow of events (Websocket phase)

Fix stock list, dynamic stock list, simple stock list:

```mermaid
sequenceDiagram
    participant Client
    participant LiveView Process
    participant Trading
    Client->>LiveView Process:  Open Websocket
    LiveView Process->>Trading: Subscribe & Request stock price from trading (use PubSub)
    LiveView Process->>Client: HTML content
    Trading->>LiveView Process: update stock price
    LiveView Process->>Client: diff HTML
```

For custom stock list input by user:

```mermaid
sequenceDiagram
    participant Client
    participant LiveView Process
    participant Trading
    Client->>LiveView Process:  Open Websocket
    LiveView Process->>Client: HTML content
    Client->>LiveView Process:  user input data
    LiveView Process->>Trading: Subscribe & Request stock price from trading (use PubSub)
    Trading->>LiveView Process: update stock price
    LiveView Process->>Client: diff HTML
```

## Guide

To run demo, please follow step.

In case you are binding by other IP please change app config and commands.

Run trading_service first

```bash
cd trading_service
mix deps.get
iex --name trading@127.0.0.1 -S mix
```

Open new Terminal then run

```bash
cd frontend_service
mix deps.get
PORT=4001 iex --name frontend_1@127.0.0.1 -S mix phx.server
```

For multi frontend you can start other instance like

```bash
PORT=4002 iex --name frontend_2@127.0.0.1 -S mix phx.server
```

frontends & trading service auto join to cluster by `:libcluster`.

Note: If you use Windows please run `set PORT=4001` to set environment variable. Similar for other instance.

Open browser then go to:

Home page [http://localhost:4001/](http://localhost:4001/) and choose a link need to open.

Or open directly with link:

dynamic stock list [http://localhost:4001/dynamic_list?from=1&to=1500](http://localhost:4001/dynamic_list?from=1&to=1500)

You can change number of stocks by change `from` and `to` parameter (from 1 to 10k) in query.

fixed stock list [http://localhost:4001/fix_list](http://localhost:4001/fix_list)

custom stock list [http://localhost:4001/custom_list](http://localhost:4001/custom_list)
