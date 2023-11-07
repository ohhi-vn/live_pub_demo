import Config

# Use for join cluster with libcluster
config :libcluster,
  topologies: [
    local_epmd: [
      # The selected clustering strategy. Required.
      strategy: Cluster.Strategy.LocalEpmd,
      # Configuration for the provided strategy. Optional.
      config: [hosts: [:"frontend_1@127.0.0.1", :"front_end_2@127.0.0.1", :"trading@127.0.0.1"]],
      # The function to use for connecting nodes. The node
      # name will be appended to the argument list. Optional
      connect: {:net_kernel, :connect_node, []},
      # The function to use for disconnecting nodes. The node
      # name will be appended to the argument list. Optional
      disconnect: {:erlang, :disconnect_node, []},
      # The function to use for listing nodes.
      # This function must return a list of node names. Optional
      list_nodes: {:erlang, :nodes, [:connected]},
    ]]
