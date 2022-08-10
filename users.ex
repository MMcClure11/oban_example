defmodule TextingTool.Users do
  @moduledoc """
  The Users context.
  """

  alias TextingTool.Jobs.Job
  alias TextingTool.Memberships
  alias TextingTool.Memberships.Membership
  alias TextingTool.Organizations.Organization
  alias TextingToolWeb.Router.Helpers, as: Routes
  alias TextingTool.Users.User
  alias TextingTool.Users.UserNotifier

  @doc """
  Delivers the texting job starts in 2 hours notification email to the given `TextingTool.Users.User`
  for the given `TextingTool.Organizations.Organization` and `TextingTool.Jobs.Job`.

  ## Examples

      iex> deliver_user_job_assignment_notifications(user, organization, job)
        {:ok, %Bamboo.Email{}}

  """
  @spec deliver_user_job_starts_2_hours_notifications(
          User.t(),
          Organization.t(),
          Job.t(),
          DateTime.t(),
          boolean
        ) ::
          UserNotifier.notifier_result()
  def deliver_user_job_starts_2_hours_notifications(
        user,
        org,
        job,
        send_time,
        async \\ true
      ) do
    url = Routes.organization_texting_index_path(TextingToolWeb.Endpoint, :index, org.id)

    UserNotifier.deliver_job_starts_2_hours_notification(
      user,
      org,
      job,
      send_time,
      url,
      async
    )
  end

  @doc """
  Delivers the texting job ends in 2 hours notification email to the given `TextingTool.Users.User`
  for the given `TextingTool.Organizations.Organization` and `TextingTool.Jobs.Job`.

  ## Examples

      iex> deliver_user_job_ends_2_hours_notifications(user, organization, job)
        {:ok, %Bamboo.Email{}}

  """
  @spec deliver_user_job_ends_2_hours_notifications(
          User.t(),
          Organization.t(),
          Job.t(),
          DateTime.t(),
          boolean()
        ) ::
          UserNotifier.notifier_result()
  def deliver_user_job_ends_2_hours_notifications(
        user,
        org,
        job,
        send_time,
        async \\ true
      ) do
    url = Routes.organization_texting_send_path(TextingToolWeb.Endpoint, :send, org.id, job.id)

    can_reply? =
      [user_id: user.id]
      |> Memberships.get_membership_by()
      |> user_can_reply?()

    UserNotifier.deliver_job_ends_2_hours_notification(
      user,
      org,
      job,
      send_time,
      url,
      can_reply?,
      async
    )
  end

  @doc """
  Delivers the texting job reply window ends in 2 hours notification email to the given
  `TextingTool.Users.User` for the given `TextingTool.Organizations.Organization` and
  `TextingTool.Jobs.Job`.

  ## Examples

      iex> deliver_user_reply_window_ends_2_hours_notifications(user, organization, job)
        {:ok, %Bamboo.Email{}}
  """
  @spec deliver_user_reply_window_ends_2_hours_notifications(
          User.t(),
          Organization.t(),
          Job.t(),
          DateTime.t(),
          boolean()
        ) ::
          UserNotifier.notifier_result()
  def deliver_user_reply_window_ends_2_hours_notifications(
        user,
        org,
        job,
        send_time,
        async \\ true
      ) do
    url = Routes.organization_texting_send_path(TextingToolWeb.Endpoint, :send, org.id, job.id)

    UserNotifier.deliver_reply_window_ends_2_hours_notification(
      user,
      org,
      job,
      send_time,
      url,
      async
    )
  end

  @doc """
  Indicates whether the given `TextingTool.Memberships.Membership` has
  permission to send custom or recommended replies.
  """
  @spec user_can_reply?(Membership.t()) :: boolean
  def user_can_reply?(%Membership{} = current_membership) do
    TextingTool.Memberships.permitted?(current_membership, "jobs.send_recommended_reply") ||
      TextingTool.Memberships.permitted?(current_membership, "jobs.send_custom_reply") ||
      Enum.member?([:member, :owner, :manager], current_membership.role.name)
  end
end
