module Api
  module V1
    module Public
      class ContactsController < ApplicationController
        def create
          payload = params.require(:contact).permit(:name, :email, :message, :company).to_h
          ContactMailer.lead_email(payload).deliver_later
          render json: { ok: true }, status: :created
        end
      end
    end
  end
end
