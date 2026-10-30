defmodule ElixirMessengerWeb.Router do
  use ElixirMessengerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ElixirMessengerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug ElixirMessengerWeb.Auth, :require
  end

  pipeline :redirect_if_authenticated do
    plug ElixirMessengerWeb.Auth, :redirect_if_authenticated
  end

  scope "/", ElixirMessengerWeb do
    pipe_through [:browser, :redirect_if_authenticated]

    get "/login", AuthController, :login
    post "/login", AuthController, :create_login
    get "/signup", AuthController, :signup
    post "/signup", AuthController, :create_signup
  end

  scope "/", ElixirMessengerWeb do
    pipe_through [:browser, :auth]

    get "/", ChatController, :index
    delete "/logout", AuthController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", ElixirMessengerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:elixir_messenger, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ElixirMessengerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
