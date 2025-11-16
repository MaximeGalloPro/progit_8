# Migration
class AddUpdatingToHikes < ActiveRecord::Migration[8.0]
    def change
        if table_exists?(:hikes)
            add_column :hikes, :updating, :boolean, default: false unless column_exists?(:hikes, :updating)
            add_column :hikes, :last_update_attempt, :datetime unless column_exists?(:hikes, :last_update_attempt)
        end
    end
end
