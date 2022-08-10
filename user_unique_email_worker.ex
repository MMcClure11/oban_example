defmodule TextingTool.Workers.UserUniqueEmailWorker do
  @moduledoc """
  Schedules a unique email from `TextingTool.Users.UserEmail` to be sent.
  """
  use Oban.Worker,
    queue: :emails,
    tags: ["email", "user-email"],
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :executing, :retryable, :completed]
    ]

  alias TextingTool.Mailer
  alias TextingTool.Users.UserEmail
  alias TextingTool.Workers.UserEmailHelpers

  @emails :functions
          |> UserEmail.__info__()
          |> Keyword.keys()
          |> Enum.reject(fn f -> f == :render end)
          |> Enum.map(&Atom.to_string/1)

  @impl true
  @spec perform(Oban.Job.t()) :: Oban.Worker.result()
  def perform(%Oban.Job{args: %{"email" => email} = args}) when email in @emails do
    email_args = UserEmailHelpers.create_email_args(args)
    email = apply(UserEmail, String.to_existing_atom(email), email_args)
    {:ok, Mailer.deliver_now(email)}
  end

  def perform(_job), do: {:discard, :invalid_email}

  defimpl TextingTool.Workers.Reportable do
    @threshold 3

    @spec reportable?(Oban.Worker.t(), integer) :: boolean
    def reportable?(_worker, attempt), do: attempt > @threshold
  end
end
