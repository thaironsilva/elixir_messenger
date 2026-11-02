# ElixirMessenger (work in progress)

A small messenger app I'm building in Elixir/Phoenix. The goal is to have it deployed
in production with complete CI/CD.

## Progress

- [x] Sign up, log in, and log out
- [x] Hash passwords (PBKDF2-HMAC-SHA256) before storing them
- [x] Store users in ETS with unique usernames
- [x] Protect the chat page, which shows a placeholder and a logout button
- [x] Server-side chat channel that requires a logged-in user
- [x] Tests covering users, auth, and the socket/channel
- [ ] Send and receive messages in the UI (the channel isn't connected to the page yet)
- [ ] Persist data (ETS is in memory, so a restart wipes it)
- [ ] GitHub Actions CI
- [ ] Docker image
- [ ] Terraform for AWS
- [ ] ALB/NLB, ingress, routing, health checks
- [ ] Argo CD deployment

## Running it locally

    mix setup
    mix phx.server

Then open http://localhost:4000.

Run the tests with:

    mix test
