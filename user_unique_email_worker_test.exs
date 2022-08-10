defmodule TextingTool.Workers.UserUniqueEmailWorkerTest do
  use TextingTool.DataCase

  alias TextingTool.Workers.UserUniqueEmailWorker

  describe "perform/1" do
    test "sends job assignment notification email" do
      org = organization_fixture()
      %{user: user} = membership_fixture(%{organization_id: org.id})

      assert {:ok, %Bamboo.Email{}} =
               UserUniqueEmailWorker.perform(%Oban.Job{
                 args: %{
                   "email" => "job_assignment_notification",
                   "user_id" => user.id,
                   "organization_id" => org.id,
                   "job_id" => job_fixture().id,
                   "date" => "October 1, 2021",
                   "time" => "11:00 AM CDT "
                 }
               })
    end

    test "sends job starts in 2 hours notification email" do
      org = organization_fixture()
      %{user: user} = membership_fixture(%{organization_id: org.id})

      assert {:ok, %Bamboo.Email{}} =
               UserUniqueEmailWorker.perform(%Oban.Job{
                 args: %{
                   "email" => "job_starts_2_hours_notification",
                   "user_id" => user.id,
                   "organization_id" => org.id,
                   "job_id" => job_fixture().id,
                   "url" => "https://example.com",
                   "time" => "11:00 AM CDT "
                 }
               })
    end

    test "sends job ends in 2 hours notification email" do
      org = organization_fixture()
      %{user: user} = membership_fixture(%{organization_id: org.id})

      assert {:ok, %Bamboo.Email{}} =
               UserUniqueEmailWorker.perform(%Oban.Job{
                 args: %{
                   "email" => "job_ends_2_hours_notification",
                   "user_id" => user.id,
                   "organization_id" => org.id,
                   "job_id" => job_fixture().id,
                   "url" => "https://example.com",
                   "start_time" => "11:00 AM CDT ",
                   "end_time" => "11:00 PM CDT ",
                   "can_reply?" => "true"
                 }
               })
    end

    test "sends reply window ends in 2 hours notification email" do
      org = organization_fixture()
      %{user: user} = membership_fixture(%{organization_id: org.id})

      assert {:ok, %Bamboo.Email{}} =
               UserUniqueEmailWorker.perform(%Oban.Job{
                 args: %{
                   "email" => "reply_window_ends_2_hours_notification",
                   "user_id" => user.id,
                   "organization_id" => org.id,
                   "job_id" => job_fixture().id,
                   "url" => "https://example.com",
                   "end_time" => "11:00 PM CDT "
                 }
               })
    end

    test "discards job if email isn't available" do
      assert {:discard, :invalid_email} =
               UserUniqueEmailWorker.perform(%Oban.Job{args: %{"email" => "foobar"}})
    end
  end
end
