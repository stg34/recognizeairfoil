# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151215101350) do

  create_table "airfoils", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "data_raw",    limit: 65535
    t.text     "file_name",   limit: 65535
    t.float    "thickness",   limit: 24
    t.text     "top",         limit: 65535
    t.text     "bottom",      limit: 65535
    t.text     "comment",     limit: 65535
    t.integer  "foil_type",   limit: 4
    t.text     "data_fixes",  limit: 65535
    t.text     "data_errors", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

end
