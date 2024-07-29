# frozen_string_literal: true

require 'faker'

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#

# ADD Initial Issues
#
# #TODO: Add custom ID when creating issue

# 1. Card information NOT added issue
card_issue = Issue.where(
    {title: "Card information is missing",
     description: "In order to process any payment or transaction you'll need this information added in your account.",
     custom_id: 1
    }).first_or_create!

solutions = [
    {description: "Go to your profile settings, click on add payment method. Then, introduce your credit/debit card information and click on Save card", velocity: "FASTEST", issue_id: card_issue[:id]},
    {description: "Send and email to support@pierpontglobal.com requesting to add a new credit/debit card information.", velocity: "FAST", issue_id: card_issue[:id]}
]

to_add_solutions = []
solutions.each do |s|
  existing = IssueSolution.find_by(:description => s[:description], :velocity => s[:velocity], :issue_id => s[:issue_id])
  if !existing.present?
    to_add_solutions.append(IssueSolution.create!(s))
  else
    to_add_solutions.append(existing)
  end
end

card_issue.issue_solutions = to_add_solutions

# 2. Release handler seed
GeneralConfiguration.first_or_create!([{key: 'pull_release', value: '1'},{key: 'heavy_vehicle_price_percentage', value: '0.2'}])
if ::GeneralConfiguration.count == 1
  GeneralConfiguration.create!(key: 'heavy_vehicle_price_percentage', value: '0.2')
end

# 3. Create Admin user
unless User.find_by_username('admin')
  admin_user = User.new(
      email: 'support@pierpontglobal.com',
      username: 'admin',
      password: ENV['ADMIN_PASSWORD'],
      phone_number: ENV['ADMIN_CONTACT']
  )
  admin_user.skip_confirmation_notification!
  admin_user.save!
  admin_user.add_role(:admin)
  admin_user.add_role(:super_admin)
end

# 4. Adding predefined locations
locations = [
    { "name": 'Manheim Fort Lauderdale', "mh_id": 162 },
    { "name": 'Manheim Palm Beach', "mh_id": 205 },
    { "name": 'Manheim Orlando', "mh_id": 139 },
    { "name": 'Manheim Tampa', "mh_id": 151 },
    { "name": 'Manheim St Pete', "mh_id": 197 },
    { "name": 'Manheim Central Florida', "mh_id": 126 }
]

locations.each do |location|
  ::Location.where(location).first_or_create!
end

# 5. Test cars

# Create colors
colors = %w[Red Blue Green Black White Silver Gray]
colors.each { |color| Color.where(name: color).first_or_create! }

# Create fuel types
fuel_types = %w[Gasoline Diesel Electric Hybrid]
fuel_types.each { |fuel| FuelType.where(name: fuel).first_or_create! }

# Create body styles
body_styles = %w[Sedan Coupe Hatchback SUV Truck Van Convertible]
body_styles.each { |style| BodyStyle.where(name: style).first_or_create! }

# Create vehicle types
vehicle_types = %w[Car Truck Motorcycle SUV]
vehicle_types.each { |type| VehicleType.where(type_code: type).first_or_create! }

# Create sellers
seller_types = %w[Dealer Private Auction]
seller_types.each { |seller| SellerType.where(title: seller).first_or_create! }

# Create makers and models
makers = %w[Toyota Honda Ford Chevrolet Nissan BMW Mercedes Audi Volkswagen Hyundai]
models = %w[Accord Civic Camry Corolla Mustang Explorer F-150 Silverado Altima Jetta]

makers.each do |maker|
  maker_record = Maker.where(name: maker).first_or_create!
  models.each do |model|
    model_record = Model.where(name: model).first_or_create!
    maker_record.models << model_record unless maker_record.models.include?(model_record)
  end
end

# Helper method to ensure sample doesn't return nil
def safe_sample(collection)
  collection.sample || safe_sample(collection)
end

car_image_base_path = 'public/images'
images = []
makers_models_images = Dir.glob("#{car_image_base_path}/*").each_with_object({}) do |maker_path, hash|
  Dir.glob("#{maker_path}/*").map do |model_path|
    images << model_path
  end
end

# Create cars
1000.times do
  maker = safe_sample(Maker.all)
  model = safe_sample(Model.all)
  color = safe_sample(Color.all)
  fuel = safe_sample(FuelType.all)
  body_style = safe_sample(BodyStyle.all)
  vehicle_type = safe_sample(VehicleType.all)
  seller_type = safe_sample(SellerType.all)

  car = Car.create!(
    vin: Faker::Vehicle.vin,
    year: Faker::Vehicle.year,
    odometer: Faker::Vehicle.mileage,
    doors: rand(2..5),
    odometer_unit: 'miles',
    vehicle_type: vehicle_type,
    engine: Faker::Vehicle.engine,
    model: model,
    fuel_type: fuel,
    interior_color: color,
    exterior_color: color,
    body_style: body_style,
    cr_url: Faker::Internet.url,
    transmission: Faker::Vehicle.transmission == 'Automatic',
    trim: Faker::Vehicle.car_options.sample,
    condition_report: rand(1..9),
    release: rand(1..9)
  )

  SaleInformation.create!(
    car_id: car.id,
    current_bid: rand(1000.0..50000.0),
    channel: Faker::Company.name,
    sale_date: Time.now + rand(1..30).days,
    auction_id: rand(10**(5-1)...10**5),
    auction_start_date: Time.now - rand(1..30).days,
    auction_end_date: Time.now + rand(1..30).days
  )

  FileDirection.create!(
    car_id: car.id,
    route: safe_sample(images),
    order: 0,
    description: Faker::Vehicle.standard_specs.sample
  )

  car.seller_types << seller_type unless car.seller_types.include?(seller_type)
end


puts "Seeded 1000 cars with related data"

