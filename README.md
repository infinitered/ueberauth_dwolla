# UeberauthDwolla

[![license img](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `ueberauth_dwolla` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_dwolla, "~> 0.1.0"}]
    end
    ```

  2. Ensure `ueberauth_dwolla` is started before your application:

    ```elixir
    def application do
      [applications: [:ueberauth_dwolla]]
    end
    ```

  3. Add Dwolla to your Überauth configuration in `config.exs`

    ```elixir
    providers: [
      dwolla: {Ueberauth.Strategy.Dwolla, [default_scope: "Send|Transactions|Funding|ManageCustomers"]}
    ]
    ```

  4. Update your provider configuraton

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Dwolla.OAuth,
      client_id: System.get_env("DWOLLA_CLIENT_ID"),
      client_secret: System.get_env("DWOLLA_SECRET_KEY"),
      redirect_uri: "http://localhost:4000/oauth/dwolla/callback"
    ```

  5. Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

  6. Create the request and callback routes if you haven't already:

  ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
  ```

  7. Your controller will need to implement callbacks for the following `Ueberauth.Auth` and `Ueberauth.Failure` responses.

  For an example implementation you can look at the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

  ## Calling

  Depending on the configured url you can initial the request through:

    /auth/dwolla

  Or with options:

      /auth/dwolla?scope=Send|Transactions|Funding

  The default requested scope is "Send|Transactions|Funding|ManageCustomers". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

  ```elixir
  config :ueberauth, Ueberauth,
    providers: [
      dwolla: {Ueberauth.Strategy.Dwolla, [default_scope: "Send|Transactions"]}
    ]
  ```

  ## Project License

  Please see [LICENSE](https://github.com/infinitered/ueberauth_dwolla/blob/master/LICENSE) for licensing details.
