class CreateSellerTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :seller_types do |t|
      t.string :title

      t.timestamps
    end
  end
end
