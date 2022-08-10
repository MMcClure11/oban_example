defmodule TextingTool.Workers.RescheduleEmailsWorker do
  @moduledoc """
  Reschedules the 2 hour email notification emails for
  a given `TextingTool.Jobs.Job`.
  """
  use Oban.Worker, queue: :default, tags: ["reschedule-email-workers"]

  alias TextingTool.Jobs
  alias TextingTool.Jobs.Job
  alias TextingTool.Repo
  alias TextingTool.Users

  @impl true
  @spec perform(Oban.Job.t()) :: Oban.Worker.result()
  def perform(%Oban.Job{args: %{"job_id" => job_id}}) do
    job = Jobs.get_job!(job_id)
    reschedule_workers(job)

    {:ok, job}
  end

  def perform(_job), do: {:discard, :invalid_args}

  @spec reschedule_workers(Job.t()) :: Oban.Worker.result()
  defp reschedule_workers(%{job_type: :p2p, status: :active, sending_stage: :queued} = job) do
    job = Repo.preload(job, [:texter_assignments])

    for texter_assignment <- job.texter_assignments do
      Jobs.cancel_job_starts_2_hours_email(job.id, texter_assignment.user_id)
      user = Users.get_user!(texter_assignment.user_id)
      Jobs.maybe_schedule_job_starts_2_hours_notif_for_user(job, user)
    end

    {:ok, job}
  end

  defp reschedule_workers(%{job_type: :p2p, status: :active, sending_stage: :initial_send} = job) do
    job = Repo.preload(job, [:texter_assignments])

    for texter_assignment <- job.texter_assignments do
      Jobs.cancel_job_ends_2_hours_email(job.id, texter_assignment.user_id)
      user = Users.get_user!(texter_assignment.user_id)
      Jobs.maybe_schedule_job_ends_2_hours_notif_for_user(job, user)
    end

    {:ok, job}
  end

  defp reschedule_workers(job), do: {:ok, job}
end
