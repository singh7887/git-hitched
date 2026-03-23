class AddImageToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :image, :string
  end
end
