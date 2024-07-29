# frozen_string_literal: true

# Defines the cars model
class Car < ApplicationRecord
  searchkick word_middle: [:car_search_identifiers], callbacks: :async

  def search_data
    {
      color: exterior_color.try(:name),
      model_name: model.try(:name),
      maker_name: model.try(:maker).try(:name),
      car_type: vehicle_type.try(:type_code),
      body_type: body_style.try(:name),
      year: year.to_s,
      doors: doors,
      engine: engine,
      fuel: fuel_type.try(:name),
      transmission: transmission,
      odometer: odometer.to_i,
      trim: trim,
      vin: vin,
      condition_report: condition_report,
      car_search_identifiers: "#{exterior_color.try(:name)} #{year} #{model.try(:maker).try(:name)} #{model.try(:name)} #{vehicle_type.try(:type_code)} #{vin} #{trim}",
      timestamp: Time.now,
      sale_date: sale_date,
      release: release,
      fielddata: true
    }
  end

  belongs_to :model, optional: true
  belongs_to :fuel_type, optional: true
  belongs_to :exterior_color, class_name: 'Color', optional: true
  belongs_to :interior_color, class_name: 'Color', optional: true
  belongs_to :body_style, optional: true
  belongs_to :vehicle_type, optional: true
  has_and_belongs_to_many :seller_types, dependent: :destroy
  has_one :sale_information, dependent: :destroy
  has_many :file_attachments
  has_many :file_directions, dependent: :destroy

  has_many :user_saved_cars
  has_many :users, through: :user_saved_cars

  scope :sanitized, lambda {
    select(:id,
           :year,
           :odometer,
           :odometer_unit,
           :displacement,
           :transmission,
           :condition_report,
           :vin,
           :doors,
           :sale_date,
           :condition,
           :whole_price,
           :engine,
           :trim,
           :release,
           :channel,
           :auction_id,
           :auction_start_date,
           :auction_end_date,
           :action_location,
           :cr_url,
           :current_bid)
      .left_joins(:model).merge(Model.sanitized)
      .left_joins(:fuel_type).merge(FuelType.sanitized)
      .left_joins(:interior_color).merge(Color.sanitized('colors', 'interior'))
      .left_joins(:exterior_color).merge(Color.sanitized('exterior_colors_cars',
                                                         'exterior'))
      .left_joins(:body_style).merge(BodyStyle.sanitized)
      .left_joins(:vehicle_type).merge(VehicleType.sanitized)
      .left_joins(:seller_types).merge(SellerType.sanitized)
      .left_joins(:file_directions).merge(FileDirection.sanitized)
      .joins('INNER JOIN sale_informations ON cars.id = sale_informations.car_id')
      .group(
        'cars.id',
        :car_model,
        :car_maker,
        :car_fuel,
        :release,
        :condition_report,
        :color_name_interior,
        :whole_price,
        :channel,
        :color_hex_interior,
        :sale_date,
        :color_name_exterior,
        :auction_id,
        :color_hex_exterior,
        :auction_start_date,
        :car_body_style,
        :auction_end_date,
        :cr_url,
        :car_vehicle_type,
        :action_location,
        :car_type_code,
        :current_bid
      )
  }

  def create_structure
    {
      car_information: {
        id: id,
        year: year,
        odometer: odometer,
        odometer_unit: odometer_unit,
        displacement: displacement,
        transmission: transmission,
        vin: vin,
        doors: doors,
        sale_date: sale_date,
        condition: condition,
        engine: engine,
        trim: trim,
        color_name_exterior: color_name_exterior,
        car_model: car_model,
        car_maker: car_maker,
        car_fuel: car_fuel,
        color_name_interior: color_name_interior,
        color_hex_interior: color_hex_interior,
        color_hex_exterior: color_hex_exterior,
        car_body_style: car_body_style,
        car_vehicle_type: car_vehicle_type,
        car_type_code: car_type_code,
        images: car_images,
        cr: condition_report,
        cr_url: cr_url,
        release: release
      },
      sale_information: {
        whole_price: whole_price,
        current_bid: current_bid,
        channel: channel,
        auction_id: auction_id,
        auction_start_date: auction_start_date,
        auction_end_date: auction_end_date,
        action_location: action_location
      }
    }
  end

  def create_simple_structure
    {
        id: id,
        year: year,
        odometer: odometer,
        odometer_unit: odometer_unit,
        displacement: displacement,
        transmission: transmission,
        vin: vin,
        doors: doors,
        sale_date: sale_date,
        condition: condition,
        engine: engine,
        trim: trim,
        model: ::Model.where(:id => model_id).map(&:sanitazed_info)[0]
    }
  end
end
