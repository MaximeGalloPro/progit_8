class CreateHikePaths < ActiveRecord::Migration[8.0]
    def change
        unless table_exists?(:hike_paths)
            create_table :hike_paths do |t|
                t.integer :hike_id
                t.text :coordinates

                t.timestamps
            end
        end
    end
end
