class AddingBasicUserInformation < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :city, :string
    add_column :users, :street_address, :string
    add_column :users, :phone_number, :string
  end
end
