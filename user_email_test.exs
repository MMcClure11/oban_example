defmodule TextingTool.Users.UserEmailTest do
  use TextingTool.DataCase

  alias TextingTool.Users.UserEmail

  setup do
    %{user: user_fixture()}
  end

  test "job_starts_2_hours_notification/5", %{user: user} do
    org = organization_fixture(%{name: "Hogwarts"})
    job = job_fixture(%{name: "Hufflepuff Quidditch Tryouts"})
    url = "http://example.com/hufflepuff"

    email = UserEmail.job_starts_2_hours_notification(user, org, job, url, "11:00 AM CDT")

    assert email.to == user
    assert email.subject == "Hufflepuff Quidditch Tryouts starts in 2 hours"

    assert email.html_body =~ "which starts in 2 hours at 11:00 AM CDT"
    assert email.html_body =~ "Hogwarts"
    assert email.html_body =~ "Hufflepuff Quidditch Tryouts"
    assert email.html_body =~ url

    assert email.text_body =~ "which starts in 2 hours at 11:00 AM CDT"
    assert email.text_body =~ "Hogwarts"
    assert email.text_body =~ "Hufflepuff Quidditch Tryouts"
    assert email.text_body =~ url
  end

  describe "job_ends_2_hours_notification/6" do
    setup do
      org = organization_fixture(%{name: "Hogwarts"})
      job = job_fixture(%{name: "Hufflepuff Quidditch Tryouts"})
      url = "http://example.com/hufflepuff"

      %{org: org, job: job, url: url}
    end

    test "renders reply message", %{user: user, org: org, job: job, url: url} do
      can_reply? = true

      email =
        UserEmail.job_ends_2_hours_notification(
          user,
          org,
          job,
          url,
          "7:30 AM CDT",
          "11:00 PM CDT",
          can_reply?
        )

      assert email.to == user

      assert email.subject ==
               "Hufflepuff Quidditch Tryouts ends and reply window starts in 2 hours"

      assert email.html_body =~ "which ends in 2 hours at 11:00 PM CDT"
      assert email.html_body =~ "Hogwarts"
      assert email.html_body =~ "Hufflepuff Quidditch Tryouts"
      assert email.html_body =~ url

      assert email.html_body =~
               "you can reply to any responses from recipients for 72 hours during this job’s texting hours (7:30 AM CDT - 11:00 PM CDT)."

      assert email.text_body =~ "which ends in 2 hours at 11:00 PM CDT"
      assert email.text_body =~ "Hogwarts"
      assert email.text_body =~ "Hufflepuff Quidditch Tryouts"
      assert email.text_body =~ url

      assert email.text_body =~
               "After the job ends, you can reply to any responses from recipients for 72 hours during this job’s texting hours (7:30 AM CDT - 11:00 PM CDT)."
    end

    test "does not render reply message", %{user: user, org: org, job: job, url: url} do
      can_reply? = false

      email =
        UserEmail.job_ends_2_hours_notification(
          user,
          org,
          job,
          url,
          "7:30 AM CDT",
          "11:00 PM CDT",
          can_reply?
        )

      assert email.to == user

      assert email.subject ==
               "Hufflepuff Quidditch Tryouts ends in 2 hours"

      assert email.html_body =~ "which ends in 2 hours at 11:00 PM CDT"
      assert email.html_body =~ "Hogwarts"
      assert email.html_body =~ "Hufflepuff Quidditch Tryouts"
      assert email.html_body =~ url

      refute email.html_body =~
               "you can reply to any responses from recipients for 72 hours"

      assert email.text_body =~ "which ends in 2 hours at 11:00 PM CDT"
      assert email.text_body =~ "Hogwarts"
      assert email.text_body =~ "Hufflepuff Quidditch Tryouts"
      assert email.text_body =~ url

      refute email.text_body =~
               "After the job ends, you can reply to any responses from recipients for 72 hours"
    end
  end

  test "reply_window_ends_hours_notification/5", %{user: user} do
    org = organization_fixture(%{name: "Hogwarts"})
    job = job_fixture(%{name: "Hufflepuff Quidditch Tryouts"})
    url = "http://example.com/hufflepuff"

    email = UserEmail.reply_window_ends_2_hours_notification(user, org, job, url, "5:00 PM CDT")

    assert email.to == user
    assert email.subject == "Hufflepuff Quidditch Tryouts’s reply window ends in 2 hours"

    assert email.html_body =~
             "You can only reply to responses from recipients for another 2 hours before the job becomes inactive at 5:00 PM CDT."

    assert email.html_body =~ "Hogwarts"
    assert email.html_body =~ "Hufflepuff Quidditch Tryouts"
    assert email.html_body =~ url

    assert email.text_body =~
             "You can only reply to responses from recipients for another 2 hours before the job becomes inactive at 5:00 PM CDT."

    assert email.text_body =~ "Hogwarts"
    assert email.text_body =~ "Hufflepuff Quidditch Tryouts"
    assert email.text_body =~ url
  end
end
