class ContactMailer < ApplicationMailer
  default to: -> { ENV.fetch("CONTACT_INBOX_EMAIL", "inbox@example.com") }

  def lead_email(payload)
    @name = payload["name"]
    @company = payload["company"]
    @email = payload["email"]
    @message = payload["message"]

    mail(
      subject: "New portfolio contact from #{@name.presence || 'visitor'}",
      body: <<~BODY
        Name: #{@name}
        Company: #{@company}
        Email: #{@email}

        Message:
        #{@message}
      BODY
    )
  end
end
