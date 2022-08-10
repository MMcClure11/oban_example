defmodule TextingTool.UsersTest do
  use TextingTool.DataCase

  alias TextingTool.Memberships
  alias TextingTool.Organizations
  alias TextingTool.Users
  alias TextingTool.Users.User
  alias TextingTool.Workers


  test "deliver_user_job_starts_2_hours_notifications/5 sends notification in the background" do
    user = user_fixture()
    org = organization_fixture()
    job = job_fixture(%{organization_id: org.id, job_type: :p2p})

    Users.deliver_user_job_starts_2_hours_notifications(
      user,
      org,
      job,
      ~U[2029-02-25 14:00:00Z],
      true
    )

    assert_enqueued(
      worker: Workers.UserUniqueEmailWorker,
      scheduled_at: ~U[2029-02-25T14:00:00Z]
    )
  end

  test "deliver_user_job_ends_2_hours_notifications/5 sends notification in the background" do
    user = user_fixture()
    org = organization_fixture()
    job = job_fixture(%{organization_id: org.id, job_type: :p2p})

    membership_fixture(%{
      role: :texter,
      organization_id: org.id,
      user_id: user.id,
      permissions: ["jobs.send_recommended_reply"]
    })

    Users.deliver_user_job_ends_2_hours_notifications(
      user,
      org,
      job,
      ~U[2029-02-25 14:00:00Z],
      true
    )

    assert_enqueued(
      worker: Workers.UserUniqueEmailWorker,
      scheduled_at: ~U[2029-02-25T14:00:00Z]
    )
  end

  test "deliver_user_reply_window_ends_2_hours_notifications/5 sends notification in the background" do
    user = user_fixture()
    org = organization_fixture()
    job = job_fixture(%{organization_id: org.id, job_type: :p2p})

    Users.deliver_user_reply_window_ends_2_hours_notifications(
      user,
      org,
      job,
      ~U[2029-02-25 14:00:00Z],
      true
    )

    assert_enqueued(
      worker: Workers.UserUniqueEmailWorker,
      scheduled_at: ~U[2029-02-25T14:00:00Z]
    )
  end

  describe "user_can_reply?/1" do
    test "returns true for members, managers and owners" do
      org = organization_fixture()

      for role <- [:member, :manager, :owner] do
        membership =
          membership_fixture(%{
            role: role,
            organization_id: org.id
          })

        assert Users.user_can_reply?(membership) == true
      end
    end

    test "returns true for texters with recommended reply permissions" do
      org = organization_fixture()

      membership =
        membership_fixture(%{
          role: :texter,
          organization_id: org.id,
          permissions: ["jobs.send_recommended_reply"]
        })

      assert Users.user_can_reply?(membership) == true
    end

    test "returns true for texters with custom reply permissions" do
      org = organization_fixture()

      membership =
        membership_fixture(%{
          role: :texter,
          organization_id: org.id,
          permissions: ["jobs.send_custom_reply"]
        })

      assert Users.user_can_reply?(membership) == true
    end

    test "returns true for texters with recommended and custom reply permissions" do
      org = organization_fixture()

      membership =
        membership_fixture(%{
          role: :texter,
          organization_id: org.id,
          permissions: ["jobs.send_recommended_reply", "jobs.send_custom_reply"]
        })

      assert Users.user_can_reply?(membership) == true
    end

    test "returns false for texters without reply permissions" do
      org = organization_fixture()

      membership =
        membership_fixture(%{
          role: :texter,
          organization_id: org.id
        })

      assert Users.user_can_reply?(membership) == false
    end
  end
end
