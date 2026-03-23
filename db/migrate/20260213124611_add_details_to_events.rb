class AddDetailsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :location_url, :string
    add_column :events, :address, :string
    add_column :events, :maps_url, :string
    add_column :events, :time_description, :string
    add_column :events, :attire, :string
    add_column :events, :attire_description, :text
    add_column :events, :subtitle, :string
    add_column :events, :sort_order, :integer
  end
end
