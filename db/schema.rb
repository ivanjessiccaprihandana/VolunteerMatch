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

ActiveRecord::Schema[7.0].define(version: 2026_11_17_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "organization_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "organization_name", null: false
    t.string "phone"
    t.string "city"
    t.text "description"
    t.string "website"
    t.boolean "verified", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_organization_profiles_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "volunteer_events", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "category", null: false
    t.string "location", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.datetime "registration_deadline", null: false
    t.integer "capacity", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_volunteer_events_on_organization_id"
    t.index ["status", "starts_at"], name: "index_volunteer_events_on_status_and_starts_at"
  end

  create_table "volunteer_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "phone"
    t.string "city"
    t.text "bio"
    t.text "skills"
    t.string "availability"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_volunteer_profiles_on_user_id", unique: true
  end

  add_foreign_key "organization_profiles", "users"
  add_foreign_key "volunteer_events", "users", column: "organization_id"
  add_foreign_key "volunteer_profiles", "users"
end
