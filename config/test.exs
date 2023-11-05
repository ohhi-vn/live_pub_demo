import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_pub_demo, LivePubDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "AJSF07nMptyGqfUlQBdJ5IWJJ7AteGTZlpssYDgCBs90rBx/yQG3SRpiGRQLTDiY",
  server: false

# In test we don't send emails.
config :live_pub_demo, LivePubDemo.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
