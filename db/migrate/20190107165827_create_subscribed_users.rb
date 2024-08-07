class CreateSubscribedUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :subscribed_users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone_number
      t.string :token, index: true

      t.timestamps
    end
  end
end
