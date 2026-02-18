module Api
  module V1
    module Admin
      class AvailabilityRulesController < BaseController
        def index
          render json: AvailabilityRule.order(:weekday, :start_time)
        end

        def show
          render json: rule
        end

        def create
          item = AvailabilityRule.new(rule_params)
          if item.save
            render json: item, status: :created
          else
            render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if rule.update(rule_params)
            render json: rule
          else
            render json: { errors: rule.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          rule.destroy!
          head :no_content
        end

        private

        def rule
          @rule ||= AvailabilityRule.find(params[:id])
        end

        def rule_params
          params.require(:availability_rule).permit(:weekday, :timezone, :start_time, :end_time, :active)
        end
      end
    end
  end
end
