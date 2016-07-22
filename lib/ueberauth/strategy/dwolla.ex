defmodule Ueberauth.Strategy.Dwolla do
  @moduledoc """
  Dwolla strategy for Überauth.
  """

  use Ueberauth.Strategy, uid_field: :sub,
                          default_scope: "Send|Transactions|Funding|ManageCustomers"

  import Calendar.DateTime, only: [add!: 2, now_utc: 0]
  import Calendar.DateTime.Format, only: [unix: 1]

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Strategy.Dwolla.OAuth

  @token_url "https://uat.dwolla.com/oauth/v2/token"

  @doc """
  Handles initial request by redirecting to dwolla
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [ scope: scopes ]
    if conn.params["state"], do: opts = Keyword.put(opts, :state, conn.params["state"])
    opts = Keyword.put(opts, :redirect_uri, callback_url(conn))

    redirect!(conn, OAuth.authorize_url!(opts))
  end

  @doc """
  Handles the callback from Dwolla
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}}=conn) do
    opts = [redirect_uri: callback_url(conn)]
    token = OAuth.get_token!([code: code], opts)

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc """
  Fallback for handle callback
  """
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Clean up the conn
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:dwolla_user, nil)
    |> put_private(:dwolla_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.dwolla_user[uid_field]
  end

  @doc """
  Returns the credentials from the Dwolla response
  """
  def credentials(conn) do
    token = conn.private.dwolla_token
    scopes = (token.other_params["scope"] || "") |> String.split("|")

    %Credentials{
      expires: true,
      expires_at: token.expires_at, # Add 1 hour
      scopes: scopes,
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.dwolla_user
    require Logger
    Logger.error inspect(conn.private.dwolla_user)
    %Info{
      name: user["name"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the dwolla callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.dwolla_token,
        user: conn.private.dwolla_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :dwolla_token, token)

    response =
      "#{token.other_params["_links"]["account"]["href"]}"
      |> HTTPoison.get([{"Accept", "application/vnd.dwolla.v1.hal+json"}, {"Authorization", "Bearer #{token.access_token}"}])

    case response do
      {:ok, %HTTPoison.Response{status_code: 401, body: body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %HTTPoison.Response{status_code: status_code, body: user} } when status_code in 200..399 ->
        put_private(conn, :dwolla_user, Poison.decode!(user))
      {:error, reason} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Dict.get(options(conn), key, Dict.get(default_options, key))
  end
end
