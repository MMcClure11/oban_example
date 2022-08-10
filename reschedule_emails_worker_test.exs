defmodule TextingTool.Workers.RescheduleEmailsWorkerTest do
  use TextingTool.DataCase

  alias TextingTool.Workers
  alias TextingTool.Workers.RescheduleEmailsWorker

  describe "perform/1" do
    test "cancels and schedules 2 hour notif email for :active, :queued, :p2p job" do
      org = organization_fixture()

      job =
        job_fixture(%{
          job_type: :p2p,
          status: :active,
          sending_stage: :queued,
          start_on: ~D[2098-08-17],
          end_on: ~D[2098-08-20],
          daily_start_time: ~T[08:00:00],
          daily_end_time: ~T[20:00:00],
          timezone: "US/Arizona",
          organization_id: org.id
        })

      user = user_fixture()
      membership_fixture(%{user_id: user.id, organization_id: org.id})
      texter_assignment_fixture(%{user_id: user.id, job_id: job.id})

      user_2 = user_fixture()
      membership_fixture(%{user_id: user_2.id, organization_id: org.id})
      texter_assignment_fixture(%{user_id: user_2.id, job_id: job.id})

      Oban.insert!(
        Oban.Job.new(
          %{
            "email" => "job_starts_2_hours_notification",
            "job_id" => job.id,
            "organization_id" => org.id,
            "time" => "10:00 AM MST",
            "url" => "/organizations/#{org.id}/texting",
            "user_id" => user.id
          },
          worker: Workers.UserUniqueEmailWorker,
          scheduled_at: ~U[2098-08-18T15:00:00Z]
        )
      )

      Oban.insert!(
        Oban.Job.new(
          %{
            "email" => "job_starts_2_hours_notification",
            "job_id" => job.id,
            "organization_id" => org.id,
            "time" => "10:00 AM MST",
            "url" => "/organizations/#{org.id}/texting",
            "user_id" => user_2.id
          },
          worker: Workers.UserUniqueEmailWorker,
          scheduled_at: ~U[2098-08-18T15:00:00Z]
        )
      )

      assert 2 == length(all_enqueued(worker: TextingTool.Workers.UserUniqueEmailWorker))

      assert {:ok, _job} =
               RescheduleEmailsWorker.perform(%Oban.Job{
                 args: %{
                   "job_id" => job.id
                 }
               })

      assert 2 == length(all_enqueued(worker: TextingTool.Workers.UserUniqueEmailWorker))

      assert_enqueued(
        worker: Workers.UserUniqueEmailWorker,
        args: %{
          "email" => "job_starts_2_hours_notification",
          "job_id" => job.id,
          "organization_id" => org.id,
          "time" => "8:00 AM MST",
          "url" => "/organizations/#{org.id}/texting",
          "user_id" => user.id
        },
        scheduled_at: ~U[2098-08-17 13:00:00Z]
      )

      assert_enqueued(
        worker: Workers.UserUniqueEmailWorker,
        args: %{
          "email" => "job_starts_2_hours_notification",
          "job_id" => job.id,
          "organization_id" => org.id,
          "time" => "8:00 AM MST",
          "url" => "/organizations/#{org.id}/texting",
          "user_id" => user_2.id
        },
        scheduled_at: ~U[2098-08-17 13:00:00Z]
      )
    end

    test "cancels and schedules 2 hour notif email for :active, :initial_send, :p2p job" do
      org = organization_fixture()

      job =
        job_fixture(%{
          job_type: :p2p,
          status: :active,
          sending_stage: :initial_send,
          start_on: ~D[2098-08-17],
          end_on: ~D[2098-08-20],
          daily_start_time: ~T[08:00:00],
          daily_end_time: ~T[17:30:00],
          timezone: "US/Arizona",
          organization_id: org.id
        })

      user = user_fixture()
      membership_fixture(%{user_id: user.id, organization_id: org.id})
      texter_assignment_fixture(%{user_id: user.id, job_id: job.id})

      user_2 = user_fixture()
      membership_fixture(%{user_id: user_2.id, organization_id: org.id})
      texter_assignment_fixture(%{user_id: user_2.id, job_id: job.id})

      Oban.insert!(
        Oban.Job.new(
          %{
            "email" => "job_ends_2_hours_notification",
            "job_id" => job.id,
            "organization_id" => org.id,
            "user_id" => user.id
          },
          worker: Workers.UserUniqueEmailWorker,
          scheduled_at: ~U[2098-08-18T15:00:00Z]
        )
      )

      Oban.insert!(
        Oban.Job.new(
          %{
            "email" => "job_ends_2_hours_notification",
            "job_id" => job.id,
            "organization_id" => org.id,
            "user_id" => user_2.id
          },
          worker: Workers.UserUniqueEmailWorker,
          scheduled_at: ~U[2098-08-18T15:00:00Z]
        )
      )

      assert 2 == length(all_enqueued(worker: TextingTool.Workers.UserUniqueEmailWorker))

      assert {:ok, _job} =
               RescheduleEmailsWorker.perform(%Oban.Job{
                 args: %{
                   "job_id" => job.id
                 }
               })

      assert 2 == length(all_enqueued(worker: TextingTool.Workers.UserUniqueEmailWorker))

      assert_enqueued(
        worker: Workers.UserUniqueEmailWorker,
        args: %{
          can_reply?: false,
          email: "job_ends_2_hours_notification",
          job_id: job.id,
          organization_id: org.id,
          end_time: "5:30 PM MST",
          start_time: "8:00 AM MST",
          url: "/organizations/#{org.id}/texting/#{job.id}",
          user_id: user.id
        },
        scheduled_at: ~U[2098-08-20 22:30:00Z]
      )

      assert_enqueued(
        worker: Workers.UserUniqueEmailWorker,
        args: %{
          can_reply?: false,
          email: "job_ends_2_hours_notification",
          job_id: job.id,
          organization_id: org.id,
          end_time: "5:30 PM MST",
          start_time: "8:00 AM MST",
          url: "/organizations/#{org.id}/texting/#{job.id}",
          user_id: user_2.id
        },
        scheduled_at: ~U[2098-08-20 22:30:00Z]
      )
    end

    test "discards job if args are invalid" do
      job = job_fixture()

      assert {:discard, :invalid_args} =
               RescheduleEmailsWorker.perform(%Oban.Job{args: %{"bad_id" => job.id}})
    end
  end
end
