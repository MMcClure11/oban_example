defmodule TextingTool.Users.UserNotifier do
  @moduledoc """
  Delivers notifications to `TextingTool.Users.User`s.
  """
  import TextingToolWeb.TemplateHelpers, only: [format_timestamp: 2, format_timestamp: 3]

  alias TextingTool.Jobs.Job
  alias TextingTool.Mailer
  alias TextingTool.Organizations.Organization
  alias TextingTool.Users.User
  alias TextingTool.Users.UserEmail
  alias TextingTool.Workers.UserUniqueEmailWorker

  @type notifier_result ::
          {:ok, Bamboo.Email.t()}
          | {:ok, {Bamboo.Email.t(), any}}
          | {:ok, Oban.Job.t()}
          | {:error, Oban.Job.changeset()}
          | {:error, term()}

  @doc """
  Deliver notification that an `TextingTool.Jobs.Job` starts in 2 hours
  that an `TextingTool.Users.User` was assigned to with a formatted timestamp
  for when the `TextingTool.Jobs.Job` starts.
  """
  @spec deliver_job_starts_2_hours_notification(
          User.t(),
          Organization.t(),
          Job.t(),
          DateTime.t(),
          String.t(),
          boolean
        ) ::
          notifier_result
  def deliver_job_starts_2_hours_notification(user, org, job, send_time, url, true) do
    %{
      email: "job_starts_2_hours_notification",
      user_id: user.id,
      organization_id: org.id,
      job_id: job.id,
      url: url,
      time: time_for_job_start_assignment(job)
    }
    |> UserUniqueEmailWorker.new(scheduled_at: send_time)
    |> Oban.insert()
  end

  def deliver_job_starts_2_hours_notification(user, org, job, _send_time, url, false) do
    {:ok,
     user
     |> UserEmail.job_starts_2_hours_notification(
       org,
       job,
       url,
       time_for_job_start_assignment(job)
     )
     |> Mailer.deliver_now()}
  end


  @doc """
  Deliver notification that a `TextingTool.Jobs.Job` ends in 2 hours
  that a `TextingTool.Users.User` was assigned to with a formatted timestamp
  for when the `TextingTool.Jobs.Job` ends.
  """
  @spec deliver_job_ends_2_hours_notification(
          User.t(),
          Organization.t(),
          Job.t(),
          DateTime.t(),
          String.t(),
          boolean(),
          boolean()
        ) ::
          notifier_result
  def deliver_job_ends_2_hours_notification(user, org, job, send_time, url, can_reply?, true) do
    %{
      email: "job_ends_2_hours_notification",
      user_id: user.id,
      organization_id: org.id,
      job_id: job.id,
      url: url,
      start_time: time_for_job_start_assignment(job),
      end_time: time_for_job_end_assignment(job),
      can_reply?: can_reply?
    }
    |> UserUniqueEmailWorker.new(scheduled_at: send_time)
    |> Oban.insert()
  end

  def deliver_job_ends_2_hours_notification(user, org, job, _send_time, url, can_reply?, false) do
    {:ok,
     user
     |> UserEmail.job_ends_2_hours_notification(
       org,
       job,
       url,
       time_for_job_start_assignment(job),
       time_for_job_end_assignment(job),
       can_reply?
     )
     |> Mailer.deliver_now()}
  end

  @doc """
  Deliver notification that a `TextingTool.Jobs.Job`’s reply window ends in 2 hours
  that a `TextingTool.Users.User` was assigned to with a formatted timestamp
  for when the `TextingTool.Jobs.Job` ends.
  """
  @spec deliver_reply_window_ends_2_hours_notification(
          User.t(),
          Organization.t(),
          Job.t(),
          DateTime.t(),
          String.t(),
          boolean()
        ) ::
          notifier_result
  def deliver_reply_window_ends_2_hours_notification(user, org, job, send_time, url, true) do
    %{
      email: "reply_window_ends_2_hours_notification",
      user_id: user.id,
      organization_id: org.id,
      job_id: job.id,
      url: url,
      end_time: time_for_reply_window_ends(job)
    }
    |> UserUniqueEmailWorker.new(scheduled_at: send_time)
    |> Oban.insert()
  end

  def deliver_reply_window_ends_2_hours_notification(user, org, job, _send_time, url, false) do
    {:ok,
     user
     |> UserEmail.reply_window_ends_2_hours_notification(
       org,
       job,
       url,
       time_for_job_end_assignment(job)
     )
     |> Mailer.deliver_now()}
  end

  @spec time_for_job_start_assignment(Job.t()) :: String.t()
  defp time_for_job_start_assignment(job) do
    {:ok, start_date_time} = DateTime.new(job.start_on, job.daily_start_time, job.timezone)
    format_timestamp(start_date_time, :time_of_day, zone_abbr: true)
  end

  @spec time_for_job_end_assignment(Job.t()) :: String.t()
  defp time_for_job_end_assignment(job) do
    {:ok, end_date_time} = DateTime.new(job.end_on, job.daily_end_time, job.timezone)
    format_timestamp(end_date_time, :time_of_day, zone_abbr: true)
  end

  @spec time_for_reply_window_ends(Job.t()) :: String.t()
  defp time_for_reply_window_ends(job) do
    reply_window_end = Jobs.reply_window_end(job)
    format_timestamp(reply_window_end, :time_of_day, zone_abbr: true)
  end
end
