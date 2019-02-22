class CreateActivityLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :activity_logs do |t|
      t.references :user, foreign_key: true
      t.string :browser
      t.string :ip_address
      t.string :controller
      t.string :action
      t.string :params
      t.string :note

      t.timestamps
    end
  end
end
