defmodule TextingTool.JobsTest do
  use TextingTool.DataCase

  alias TextingTool.Jobs
  alias TextingTool.Workers

  describe "maybe_reschedule_emails/2" do
    test "inserts RescheduleEmailsWorker for an active, p2p, queued job" do
      job =
        job_fixture(%{
          status: :active,
          sending_stage: :queued,
          job_type: :p2p,
          start_on: ~D[2098-08-17],
          end_on: ~D[2098-08-20],
          daily_start_time: ~T[08:00:00],
          daily_end_time: ~T[20:00:00],
          timezone: "US/Arizona"
        })

      updated_job = Jobs.update_job!(job, %{start_on: ~D[2098-08-16]})

      Jobs.maybe_reschedule_emails(updated_job, job)

      assert 1 == length(all_enqueued())

      assert_enqueued(
        worker: Workers.RescheduleEmailsWorker,
        args: %{job_id: job.id}
      )
    end

    test "inserts RescheduleEmailsWorker for an active, p2p, initial_send job" do
      job =
        job_fixture(%{
          status: :active,
          sending_stage: :initial_send,
          job_type: :p2p,
          start_on: ~D[2098-08-17],
          end_on: ~D[2098-08-20],
          daily_start_time: ~T[08:00:00],
          daily_end_time: ~T[20:00:00],
          timezone: "US/Arizona"
        })

      updated_job = Jobs.update_job!(job, %{end_on: ~D[2098-08-25]})

      Jobs.maybe_reschedule_emails(updated_job, job)

      assert 1 == length(all_enqueued())

      assert_enqueued(
        worker: Workers.RescheduleEmailsWorker,
        args: %{job_id: job.id}
      )
    end

    test "does not insert RescheduleEmailsWorker for an inactive, p2p, queued job" do
      job =
        job_fixture(%{
          status: :inactive,
          sending_stage: :queued,
          job_type: :p2p,
          start_on: ~D[2098-08-17],
          end_on: ~D[2098-08-20],
          daily_start_time: ~T[08:00:00],
          daily_end_time: ~T[20:00:00],
          timezone: "US/Arizona"
        })

      updated_job = Jobs.update_job!(job, %{start_on: ~D[2098-08-16]})

      Jobs.maybe_reschedule_emails(updated_job, job)

      refute_enqueued(
        worker: Workers.RescheduleEmailsWorker,
        args: %{job_id: job.id}
      )
    end
  end

  describe "reschedule_workers?/2" do
    setup do
      queued_job =
        job_fixture(%{
          status: :active,
          sending_stage: :queued,
          start_on: ~D[2098-08-18],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[09:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Central"
        })

      initial_job =
        job_fixture(%{
          status: :active,
          sending_stage: :initial_send,
          start_on: ~D[2098-08-18],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[09:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Central"
        })

      %{queued_job: queued_job, initial_job: initial_job}
    end

    test "returns true if start_on is different for :queued job", %{queued_job: job} do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :queued,
          start_on: ~D[2098-09-18],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[09:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Central"
        })

      assert true == Jobs.reschedule_workers?(updated_job, job)
    end

    test "returns true if daily_start_time is different for :queued job", %{queued_job: job} do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :queued,
          start_on: ~D[2098-08-18],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[10:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Central"
        })

      assert true == Jobs.reschedule_workers?(updated_job, job)
    end

    test "returns true if timezone is different for :queued job", %{queued_job: job} do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :queued,
          start_on: ~D[2098-08-18],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[09:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Arizona"
        })

      assert true == Jobs.reschedule_workers?(updated_job, job)
    end

    test "returns true if all relevant fields are different for :queued job", %{queued_job: job} do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :queued,
          start_on: ~D[2098-08-19],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[07:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Arizona"
        })

      assert true == Jobs.reschedule_workers?(updated_job, job)
    end

    test "returns false if no difference for a :queued job", %{queued_job: job} do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :queued,
          start_on: ~D[2098-08-18],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[09:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Central"
        })

      assert false == Jobs.reschedule_workers?(updated_job, job)
    end

    test "returns true if end_on is different for :initial_send job", %{initial_job: job} do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :initial_send,
          start_on: ~D[2098-08-18],
          end_on: ~D[2099-08-19],
          daily_start_time: ~T[09:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Central"
        })

      assert true == Jobs.reschedule_workers?(updated_job, job)
    end

    test "returns true if daily_end_time is different for :initial_send job", %{initial_job: job} do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :initial_send,
          start_on: ~D[2098-08-18],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[09:00:00],
          daily_end_time: ~T[18:00:00],
          timezone: "US/Central"
        })

      assert true == Jobs.reschedule_workers?(updated_job, job)
    end

    test "returns true if timezone is different for an :initial_send job", %{initial_job: job} do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :initial_send,
          start_on: ~D[2098-08-18],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[09:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Arizona"
        })

      assert true == Jobs.reschedule_workers?(updated_job, job)
    end

    test "returns true if all relevant fields are different for an :initial_send job", %{
      initial_job: job
    } do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :initial_send,
          start_on: ~D[2098-08-18],
          end_on: ~D[2099-08-17],
          daily_start_time: ~T[09:00:00],
          daily_end_time: ~T[18:00:00],
          timezone: "US/Arizona"
        })

      assert true == Jobs.reschedule_workers?(updated_job, job)
    end

    test "returns false if no difference for :initial_send job", %{initial_job: job} do
      updated_job =
        job_fixture(%{
          status: :active,
          sending_stage: :initial_send,
          start_on: ~D[2098-08-16],
          end_on: ~D[2099-08-18],
          daily_start_time: ~T[10:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Central"
        })

      assert false == Jobs.reschedule_workers?(updated_job, job)
    end
  end

  describe "maybe_reschedule_emails/2" do
    test "inserts RescheduleEmailsWorker for an active, p2p, queued job" do
      job =
        job_fixture(%{
          status: :active,
          sending_stage: :queued,
          job_type: :p2p,
          start_on: ~D[2098-08-17],
          end_on: ~D[2098-08-20],
          daily_start_time: ~T[08:00:00],
          daily_end_time: ~T[20:00:00],
          timezone: "US/Arizona"
        })

      updated_job = Jobs.update_job!(job, %{start_on: ~D[2098-08-16]})

      Jobs.maybe_reschedule_emails(updated_job, job)

      assert 1 == length(all_enqueued())

      assert_enqueued(
        worker: Workers.RescheduleEmailsWorker,
        args: %{job_id: job.id}
      )
    end

    test "inserts RescheduleEmailsWorker for an active, p2p, initial_send job" do
      job =
        job_fixture(%{
          status: :active,
          sending_stage: :initial_send,
          job_type: :p2p,
          start_on: ~D[2098-08-17],
          end_on: ~D[2098-08-20],
          daily_start_time: ~T[08:00:00],
          daily_end_time: ~T[20:00:00],
          timezone: "US/Arizona"
        })

      updated_job = Jobs.update_job!(job, %{end_on: ~D[2098-08-25]})

      Jobs.maybe_reschedule_emails(updated_job, job)

      assert 1 == length(all_enqueued())

      assert_enqueued(
        worker: Workers.RescheduleEmailsWorker,
        args: %{job_id: job.id}
      )
    end

    test "does not insert RescheduleEmailsWorker for an inactive, p2p, queued job" do
      job =
        job_fixture(%{
          status: :inactive,
          sending_stage: :queued,
          job_type: :p2p,
          start_on: ~D[2098-08-17],
          end_on: ~D[2098-08-20],
          daily_start_time: ~T[08:00:00],
          daily_end_time: ~T[20:00:00],
          timezone: "US/Arizona"
        })

      updated_job = Jobs.update_job!(job, %{start_on: ~D[2098-08-16]})

      Jobs.maybe_reschedule_emails(updated_job, job)

      refute_enqueued(
        worker: Workers.RescheduleEmailsWorker,
        args: %{job_id: job.id}
      )
    end
  end

  test "cancel_job_starts_2_hours_email/2 cancels the given job" do
    job =
      job_fixture(%{
        job_type: :p2p,
        status: :active,
        sending_stage: :queued,
        start_on: ~D[2020-08-17],
        end_on: ~D[2020-08-20],
        daily_start_time: ~T[08:00:00],
        daily_end_time: ~T[20:00:00],
        timezone: "US/Central"
      })

    user = user_fixture()
    user_2 = user_fixture()

    Oban.insert!(
      Oban.Job.new(%{job_id: job.id, user_id: user.id, email: "job_starts_2_hours_notification"},
        worker: Workers.UserUniqueEmailWorker
      )
    )

    Oban.insert!(
      Oban.Job.new(
        %{job_id: job.id, user_id: user_2.id, email: "job_starts_2_hours_notification"},
        worker: Workers.UserUniqueEmailWorker
      )
    )

    Oban.insert!(
      Oban.Job.new(%{job_id: job.id, user_id: user.id, email: "job_starts_2_hours_notification"},
        worker: Workers.UserUniqueEmailWorker
      )
    )

    assert 3 == length(all_enqueued(worker: Workers.UserUniqueEmailWorker))

    Jobs.cancel_job_starts_2_hours_email(job.id, user.id)

    refute_enqueued(
      worker: Workers.UserUniqueEmailWorker,
      args: %{job_id: job.id, user_id: user.id, email: "job_starts_2_hours_notification"}
    )

    assert 1 == length(all_enqueued(worker: Workers.UserUniqueEmailWorker))

    assert_enqueued(
      worker: Workers.UserUniqueEmailWorker,
      args: %{job_id: job.id, user_id: user_2.id, email: "job_starts_2_hours_notification"}
    )
  end

  test "cancel_job_ends_2_hours_email/2 cancels the given job" do
    job =
      job_fixture(%{
        job_type: :p2p,
        status: :active,
        sending_stage: :initial_send,
        start_on: ~D[2020-08-17],
        end_on: ~D[2020-08-20],
        daily_start_time: ~T[08:00:00],
        daily_end_time: ~T[20:00:00],
        timezone: "US/Central"
      })

    user = user_fixture()
    user_2 = user_fixture()

    Oban.insert!(
      Oban.Job.new(%{job_id: job.id, user_id: user.id, email: "job_ends_2_hours_notification"},
        worker: Workers.UserUniqueEmailWorker
      )
    )

    Oban.insert!(
      Oban.Job.new(
        %{job_id: job.id, user_id: user_2.id, email: "job_ends_2_hours_notification"},
        worker: Workers.UserUniqueEmailWorker
      )
    )

    Oban.insert!(
      Oban.Job.new(%{job_id: job.id, user_id: user.id, email: "job_ends_2_hours_notification"},
        worker: Workers.UserUniqueEmailWorker
      )
    )

    assert 3 == length(all_enqueued(worker: Workers.UserUniqueEmailWorker))

    Jobs.cancel_job_ends_2_hours_email(job.id, user.id)

    refute_enqueued(
      worker: Workers.UserUniqueEmailWorker,
      args: %{job_id: job.id, user_id: user.id, email: "job_ends_2_hours_notification"}
    )

    assert 1 == length(all_enqueued(worker: Workers.UserUniqueEmailWorker))

    assert_enqueued(
      worker: Workers.UserUniqueEmailWorker,
      args: %{job_id: job.id, user_id: user_2.id, email: "job_ends_2_hours_notification"}
    )
  end

  test "cancel_reply_window_ends_2_hours_email/2 cancels the email for given job_id and user_id" do
    job =
      job_fixture(%{
        job_type: :p2p,
        status: :active,
        sending_stage: :reply_window,
        start_on: ~D[2020-08-17],
        end_on: ~D[2020-08-20],
        daily_start_time: ~T[08:00:00],
        daily_end_time: ~T[20:00:00],
        timezone: "US/Central"
      })

    user = user_fixture()
    user_2 = user_fixture()
    email_type = "reply_window_ends_2_hours_notification"

    Oban.insert!(
      Oban.Job.new(%{job_id: job.id, user_id: user.id, email: email_type},
        worker: Workers.UserUniqueEmailWorker
      )
    )

    Oban.insert!(
      Oban.Job.new(
        %{job_id: job.id, user_id: user_2.id, email: email_type},
        worker: Workers.UserUniqueEmailWorker
      )
    )

    Oban.insert!(
      Oban.Job.new(%{job_id: job.id, user_id: user.id, email: email_type},
        worker: Workers.UserUniqueEmailWorker
      )
    )

    assert 3 == length(all_enqueued(worker: Workers.UserUniqueEmailWorker))

    Jobs.cancel_reply_window_ends_2_hours_email(job.id, user.id)

    refute_enqueued(
      worker: Workers.UserUniqueEmailWorker,
      args: %{job_id: job.id, user_id: user.id, email: email_type}
    )

    assert 1 == length(all_enqueued(worker: Workers.UserUniqueEmailWorker))

    assert_enqueued(
      worker: Workers.UserUniqueEmailWorker,
      args: %{job_id: job.id, user_id: user_2.id, email: email_type}
    )
  end

  describe "maybe_schedule_job_starts_2_hours_notif_for_user/3" do
    test "queues the email worker" do
      org = organization_fixture()
      user = user_fixture()
      membership_fixture(%{user_id: user.id, organization_id: org.id})

      job =
        job_fixture(%{
          organization_id: org.id,
          job_type: :p2p,
          status: :active,
          sending_stage: :queued,
          start_on: ~D[2098-02-25],
          end_on: ~D[2098-03-23],
          daily_start_time: ~T[10:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Arizona"
        })

      texter_assignment_fixture(%{user_id: user.id, job_id: job.id})

      Jobs.maybe_schedule_job_starts_2_hours_notif_for_user(job, user,
        now: ~U[2098-02-24T15:00:00Z]
      )

      assert_enqueued(
        worker: Workers.UserUniqueEmailWorker,
        args: %{
          "email" => "job_starts_2_hours_notification",
          "job_id" => job.id,
          "organization_id" => org.id,
          "time" => "10:00 AM MST",
          "url" => "/organizations/#{org.id}/texting",
          "user_id" => user.id
        },
        scheduled_at: ~U[2098-02-25T15:00:00Z]
      )
    end

    test "does not queue the email worker when past the send time" do
      org = organization_fixture()
      user = user_fixture()
      membership_fixture(%{user_id: user.id, organization_id: org.id})

      job =
        job_fixture(%{
          organization_id: org.id,
          job_type: :p2p,
          status: :active,
          sending_stage: :queued,
          start_on: ~D[2020-02-25],
          end_on: ~D[2020-03-23],
          daily_start_time: ~T[10:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Arizona"
        })

      texter_assignment_fixture(%{user_id: user.id, job_id: job.id})

      Jobs.maybe_schedule_job_starts_2_hours_notif_for_user(job, user,
        now: ~U[2020-02-26T15:00:00Z]
      )

      refute_enqueued(worker: Workers.UserUniqueEmailWorker)
    end

    test "does not queue the email worker when the job starts in less than 2 hours" do
      org = organization_fixture()
      user = user_fixture()
      membership_fixture(%{user_id: user.id, organization_id: org.id})

      job =
        job_fixture(%{
          organization_id: org.id,
          job_type: :p2p,
          status: :active,
          sending_stage: :initial_send,
          start_on: ~D[2020-02-25],
          end_on: ~D[2020-03-23],
          daily_start_time: ~T[10:00:00],
          daily_end_time: ~T[17:00:00],
          timezone: "US/Arizona"
        })

      texter_assignment_fixture(%{user_id: user.id, job_id: job.id})

      # now is 60 min before start time
      Jobs.maybe_schedule_job_starts_2_hours_notif_for_user(job, user,
        now: ~U[2020-02-25T16:00:00Z]
      )

      refute_enqueued(worker: Workers.UserUniqueEmailWorker)
    end
  end
end
