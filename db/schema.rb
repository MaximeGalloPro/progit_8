# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_15_173105) do
  create_table "hike_histories", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.decimal "carpooling_cost", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.string "day_type"
    t.string "departure_time"
    t.integer "hike_id"
    t.date "hiking_date"
    t.string "openrunner_ref"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["hike_id"], name: "index_hike_histories_on_hike_id"
    t.index ["hiking_date", "hike_id"], name: "index_hike_histories_on_hiking_date_and_hike_id", unique: true
  end

  create_table "hike_paths", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.text "coordinates"
    t.datetime "created_at", null: false
    t.integer "hike_id"
    t.datetime "updated_at", null: false
  end

  create_table "hikes", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.integer "altitude_max"
    t.integer "altitude_min"
    t.float "carpooling_cost"
    t.datetime "created_at", null: false
    t.integer "day"
    t.integer "difficulty"
    t.float "distance_km"
    t.float "elevation_gain"
    t.integer "elevation_loss"
    t.datetime "last_update_attempt"
    t.integer "number"
    t.string "openrunner_ref"
    t.string "starting_point"
    t.string "trail_name"
    t.datetime "updated_at", null: false
    t.boolean "updating", default: false
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "nickname"
    t.string "password_digest"
    t.string "provider"
    t.integer "role", default: 0, null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "sessions", "users"
end
