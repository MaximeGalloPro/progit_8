class CreateHikeHistories < ActiveRecord::Migration[8.0]
    def change
        unless table_exists?(:hike_histories)
            create_table :hike_histories do |t|
                t.date :hiking_date
                t.string :departure_time
                t.string :day_type
                t.decimal :carpooling_cost, precision: 5, scale: 2
                t.integer :hike_id
                t.string :openrunner_ref
                t.integer :member_id

                t.timestamps
            end
        end

        add_index :hike_histories, :hike_id unless index_exists?(:hike_histories, :hike_id)
        add_index :hike_histories, [ :hiking_date, :hike_id ], unique: true unless index_exists?(:hike_histories, [ :hiking_date, :hike_id ], unique: true)
    end
end
