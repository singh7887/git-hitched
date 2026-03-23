class AddChildcareFields < ActiveRecord::Migration[8.0]
  def change
    add_column :guests, :is_child, :boolean, default: false, null: false
    add_column :guests, :needs_childcare, :boolean, default: false, null: false
    add_column :invites, :children_attending, :boolean, default: false, null: false
  end
end
