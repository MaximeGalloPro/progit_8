class AddColumsToHikes < ActiveRecord::Migration[8.0]
  def change
      if table_exists?(:hikes)
          add_column :hikes, :elevation_loss, :integer unless column_exists?(:hikes, :elevation_loss)
          add_column :hikes, :altitude_min, :integer unless column_exists?(:hikes, :altitude_min)
          add_column :hikes, :altitude_max, :integer unless column_exists?(:hikes, :altitude_max)
      end
  end
end
