class CreateRecommendations < ActiveRecord::Migration[8.1]
  def change
    create_table :recommendations do |t|
      t.string :name, null: false
      t.string :category
      t.string :location
      t.text :note
      t.string :url
      t.integer :sort_order, default: 0, null: false
      t.boolean :published, default: true, null: false

      t.timestamps
    end
  end
end
