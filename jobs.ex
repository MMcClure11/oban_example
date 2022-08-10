defmodule TextingTool.Jobs do
  @moduledoc """
  The `TextingTool.Jobs` context.
  """

  import Ecto.Query, warn: false

  alias TextingTool.Users.User
  alias TextingTool.Workers
  alias __MODULE__.Job

  @doc """
  For two given active P2P `TextingTool.Jobs.Job`s, inserts an
  `TextingTool.Workers.RescheduleEmailsWorker` `Oban.Job` when the start or end date change.
  """
  @spec maybe_reschedule_emails(Job.t(), Job.t()) :: Job.t()
  def maybe_reschedule_emails(
        %Job{status: :active, job_type: :p2p} = updated_job,
        %Job{status: :active, job_type: :p2p} = job
      ) do
    if reschedule_workers?(updated_job, job) do
      reschedule_emails(updated_job)
    end

    updated_job
  end

  def maybe_reschedule_emails(updated_job, _job), do: updated_job

  @doc """
  For a job in a :queued sending stage, returns a boolean to determine if the `start_on`,
  `daily_start_time`, or `timezone` of two given `TextingTool.Jobs.Job`s are different.

  For a job in an :initial_send sending stage, returns a boolean to determine if the `end_on`,
  `daily_end_time`, or `timezone` of two given `TextingTool.Jobs.Job`s are different.
  """
  @spec reschedule_workers?(Job.t(), Job.t()) :: boolean()
  def reschedule_workers?(
        %{sending_stage: :queued} = updated_job,
        %{sending_stage: :queued} = job
      ) do
    start_on_changed? = job.start_on != updated_job.start_on
    daily_start_time_changed? = job.daily_start_time != updated_job.daily_start_time
    timezone_changed? = job.timezone != updated_job.timezone

    start_on_changed? || daily_start_time_changed? || timezone_changed?
  end

  def reschedule_workers?(
        %{sending_stage: :initial_send} = updated_job,
        %{sending_stage: :initial_send} = job
      ) do
    end_on_changed? = job.end_on != updated_job.end_on
    daily_end_time_changed? = job.daily_end_time != updated_job.daily_end_time
    timezone_changed? = job.timezone != updated_job.timezone

    end_on_changed? || daily_end_time_changed? || timezone_changed?
  end

  def reschedule_workers?(_updated_job, _job), do: false

  @spec reschedule_emails(Job.t()) :: Oban.Worker.result()
  defp reschedule_emails(%{status: :active, sending_stage: sending_stage, job_type: :p2p} = job)
       when sending_stage in [:queued, :initial_send] do
    %{job_id: job.id}
    |> Workers.RescheduleEmailsWorker.new()
    |> Oban.insert()
  end

  defp reschedule_emails(job), do: {:ok, job}

  @doc """
  Cancels all `TextingTool.Workers.UserUniqueEmailWorker` `Oban.Job`s  of email type
  `job_starts_2_hours_notification` found for the given `job_id` and `user_id`.
  """
  @spec cancel_job_starts_2_hours_email(Ecto.UUID.t(), Ecto.UUID.t()) :: {:ok, non_neg_integer()}
  def cancel_job_starts_2_hours_email(job_id, user_id) do
    cancel_scheduled_email(job_id, user_id, "job_starts_2_hours_notification")
  end

  @doc """
  Cancels all `TextingTool.Workers.UserUniqueEmailWorker` `Oban.Job`s  of email type
  `job_ends_2_hours_notification` found for the given `job_id` and `user_id`.
  """
  @spec cancel_job_ends_2_hours_email(Ecto.UUID.t(), Ecto.UUID.t()) :: {:ok, non_neg_integer()}
  def cancel_job_ends_2_hours_email(job_id, user_id) do
    cancel_scheduled_email(job_id, user_id, "job_ends_2_hours_notification")
  end

  @doc """
  Cancels all `TextingTool.Workers.UserUniqueEmailWorker` `Oban.Job`s  of email type
  `reply_window_ends_2_hours_notification` found for the given `job_id` and `user_id`.
  """
  @spec cancel_reply_window_ends_2_hours_email(Ecto.UUID.t(), Ecto.UUID.t()) ::
          {:ok, non_neg_integer()}
  def cancel_reply_window_ends_2_hours_email(job_id, user_id) do
    cancel_scheduled_email(job_id, user_id, "reply_window_ends_2_hours_notification")
  end

  @spec cancel_scheduled_email(Ecto.UUID.t(), Ecto.UUID.t(), String.t()) ::
          {:ok, non_neg_integer()}
  defp cancel_scheduled_email(job_id, user_id, email_type) do
    {:ok, _} =
      Oban.Job
      |> where([j], worker: "TextingTool.Workers.UserUniqueEmailWorker")
      |> Ecto.Query.where([j], fragment("? ->> ? = ?", j.args, "job_id", ^job_id))
      |> Ecto.Query.where([j], fragment("? ->> ? = ?", j.args, "user_id", ^user_id))
      |> Ecto.Query.where(
        [j],
        fragment("? ->> ? = ?", j.args, "email", ^email_type)
      )
      |> Oban.cancel_all_jobs()
  end

  @doc """
  Schedules an email notification to texters assigned to the given `TextingTool.Jobs.Job`
  2 hours before start time if that 2 hour time has not already passed.
  """
  @spec maybe_schedule_job_starts_2_hours_notif_for_user(Job.t(), User.t(), [{:now, DateTime.t()}]) ::
          {:ok, Job.t()}
  def maybe_schedule_job_starts_2_hours_notif_for_user(job, user, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    {:ok, start_date_time} = DateTime.new(job.start_on, job.daily_start_time, job.timezone)
    hours_before = Timex.Duration.from_hours(2)
    send_emails_time = Timex.subtract(start_date_time, hours_before)
    diff = Timex.diff(send_emails_time, now, :minutes)
    schedule_job_starts_2_hours_notif_for_user(job, diff, send_emails_time, user)
  end

  @spec schedule_job_starts_2_hours_notif_for_user(Job.t(), integer(), DateTime.t(), User.t()) ::
          {:ok, Job.t()}
  defp schedule_job_starts_2_hours_notif_for_user(job, minute_difference, send_time, user)
       when minute_difference >= 0 do
    org = Organizations.get_organization!(job.organization_id)
    Users.deliver_user_job_starts_2_hours_notifications(user, org, job, send_time)
    {:ok, job}
  end

  defp schedule_job_starts_2_hours_notif_for_user(job, _minute_difference, _send_time, _user),
    do: {:ok, job}
end
