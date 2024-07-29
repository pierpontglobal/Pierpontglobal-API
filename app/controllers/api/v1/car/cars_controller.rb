# frozen_string_literal: true

module Api
  module V1
    module Car
      # Allow the caller to administer the cars on the database
      class CarsController < Api::V1::UserBaseController

        def save_vehicle
          if params[:vin].present?
            # TODO: Verify if the car is not saved already
            vehicle = ::Car.sanitized.find_by_vin(params[:vin]).create_structure
            if vehicle.present?
              ::UserSavedCar.create!(user_id: current_user.id, car_id: vehicle[:car_information][:id])
              # ::User.cars.create(user_id: current_user.id, car_id: vehicle[:id])
              render json: { car: vehicle }, :status => :ok
            else
              render json: {
                  message: "Car not found"
              }, :status => :not_found
            end

          else
            render json: { message: 'Please, provide a car vin' }, :status => :bad_request
          end
        end

        def remove_user_vehicle
          if params[:vin].present?
            # TODO: Verify if the car is saved
            vehicle = ::Car.find_by(:vin => params[:vin])
            if vehicle
              result = ::UserSavedCar.find_by(:user_id => current_user[:id], :car_id => vehicle[:id]).destroy!
              render json: {
                  removed_car: vehicle,
                  result: result,
              }, :status => :ok
            else
              render json: {
                  message: "Couldn't find a car with vin = #{params[:vin]}"
              }, :status => :not_found
            end

          else
            render json: { message: 'Please, provide a car vin' }, :status => :bad_request
          end
        end

        # QUERY SYSTEM

        def show
          render json: ::Car.sanitized.find_by_vin(params[:vin]).create_structure, status: :ok
        end

        def latest
          render json: ::Car.limit(params[:limit]).offset(params[:offset]).sanitized,
                 status: :ok
        end

        def all
          render json: ::Car.limit_search(params[:offset], params[:limit])
                            .sanitized,
                 status: :ok
        end

        def price_request
          render json: { status: 'sent' }, status: :ok
          driver = ::PriceWorker::Instance::Driver
          driver.look_for_vin(params['vin'], current_user.id)
        end

        def query
          params[:limit] ||= 20
          params[:offset] ||= 0
          params[:q] ||= '*'

          release = GeneralConfiguration.find_by(key: 'pull_release').value.to_i

          selector_params = {}
          selector_params[:doors] = clean_array(params[:doors]) if params[:doors].present?
          selector_params[:car_type] = clean_array(params[:car_type]) if params[:car_type].present?
          selector_params[:maker_name] = clean_array(params[:maker]) if params[:maker].present?
          selector_params[:model_name] = clean_array(params[:model]) if params[:model].present?
          selector_params[:body_type] = clean_array(params[:body_type]) if params[:body_type].present?
          selector_params[:engine] = clean_array(params[:engine]) if params[:engine].present?
          selector_params[:fuel] = clean_array(params[:fuel]) if params[:fuel].present?
          if params[:transmission].present?
            selector_params[:transmission] = (clean_array(params[:transmission])
                                                  .map { |tr| binary_selector('automatic', tr) })
          end
          selector_params[:odometer] = clean_range(params[:odometer]) if params[:odometer].present?
          selector_params[:color] = clean_array(params[:color]) if params[:color].present?
          selector_params[:trim] = clean_array(params[:trim]) if params[:trim].present?
          selector_params[:year] = clean_array(params[:year]) if params[:year].present?
          selector_params[:release] = { gte: (release - 7), lte: release }
          # selector_params[:sale_date] = { gt: Time.now }

          search_results = ::Car.search(params[:q],
                              fields: [:car_search_identifiers],
                              limit: params[:limit],
                              boost_by: { condition_report: { factor: 5 }, release: { factor: 10 } },
                              order: { _score: :desc, _id: :desc },
                              offset: params[:offset],
                              operator: 'or',
                              scope_results: ->(r) { r.sanitized },
                              aggs: %i[engine doors car_type maker_name model_name body_type fuel transmission odometer color trim year release],
                              where: selector_params
                            )

          car_ids = search_results.map(&:id)
          cars = ::Car.sanitized.where(id: car_ids)

          render json: { size: search_results.total_count,
                         available_arguments: search_results.aggs ,
                         cars: cars.map(&:create_structure)}, status: :ok
        end

        # CAR STATE HISTORY CONTROLLER

        def log_state_change; end

        private

        def clean_array(arr_string)
          arr_string.split(',').map { |s| s == 'null' ? nil : s }
        end

        def clean_range(arr_string)
          arr = arr_string.split(',').map { |s| s == 'null' ? nil : s.to_i }
          { gte: arr[0], lte: arr[1] }
        rescue StandardError
          { gte: 0, lte: 9_999_999 }
        end

        def binary_selector(true_value, value)
          true_value == value
        end
      end
    end
  end
end
