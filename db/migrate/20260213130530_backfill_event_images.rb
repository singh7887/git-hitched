class BackfillEventImages < ActiveRecord::Migration[8.0]
  def up
    mapping = {
      1 => "venue4.jpg",
      2 => "venue6.jpg",
      3 => "reception.png",
      4 => "venue5.jpg"
    }

    mapping.each do |id, image|
      execute "UPDATE events SET image = '#{image}' WHERE id = #{id}"
    end
  end

  def down
    execute "UPDATE events SET image = NULL WHERE id IN (1, 2, 3, 4)"
  end
end
