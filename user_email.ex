defmodule TextingTool.Users.UserEmail do
  @moduledoc """
  Emails various notifications to `TextingTool.Users.User`s.
  """
  use TextingTool.Email
  use Bamboo.Phoenix, view: TextingToolWeb.UserEmailView

  alias TextingTool.Jobs.Job
  alias TextingTool.Organizations.Organization
  alias TextingTool.Users.User

  alias TextingToolWeb.LayoutView

  @spec job_starts_2_hours_notification(
          User.t(),
          Organization.t(),
          Job.t(),
          String.t(),
          String.t()
        ) ::
          Bamboo.Email.t()
  def job_starts_2_hours_notification(user, org, job, url, time) do
    user
    |> base_email()
    |> subject(gettext("%{job_name} starts in 2 hours", job_name: job.name))
    |> assign(:user, user)
    |> assign(:organization, org)
    |> assign(:job, job)
    |> assign(:url, url)
    |> assign(:time, time)
    |> render(:job_starts_2_hours_notification)
  end

  @spec job_ends_2_hours_notification(
          User.t(),
          Organization.t(),
          Job.t(),
          String.t(),
          String.t(),
          String.t(),
          boolean()
        ) ::
          Bamboo.Email.t()
  def job_ends_2_hours_notification(user, org, job, url, start_time, end_time, can_reply?) do
    subject =
      if can_reply? do
        gettext("%{job_name} ends and reply window starts in 2 hours", job_name: job.name)
      else
        gettext("%{job_name} ends in 2 hours", job_name: job.name)
      end

    user
    |> base_email()
    |> subject(subject)
    |> assign(:user, user)
    |> assign(:organization, org)
    |> assign(:job, job)
    |> assign(:url, url)
    |> assign(:start_time, start_time)
    |> assign(:end_time, end_time)
    |> assign(:can_reply?, can_reply?)
    |> render(:job_ends_2_hours_notification)
  end

  @spec reply_window_ends_2_hours_notification(
          User.t(),
          Organization.t(),
          Job.t(),
          String.t(),
          String.t()
        ) ::
          Bamboo.Email.t()
  def reply_window_ends_2_hours_notification(user, org, job, url, end_time) do
    user
    |> base_email()
    |> subject(gettext("%{job_name}’s reply window ends in 2 hours", job_name: job.name))
    |> assign(:user, user)
    |> assign(:organization, org)
    |> assign(:job, job)
    |> assign(:url, url)
    |> assign(:end_time, end_time)
    |> render(:reply_window_ends_2_hours_notification)
  end
end
