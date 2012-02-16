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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120210015643) do

  create_table "data", :force => true do |t|
    t.string   "param1"
    t.string   "param2"
    t.string   "param3"
    t.string   "param4"
    t.string   "param5"
    t.string   "param6"
    t.string   "param7"
    t.string   "param8"
    t.string   "param9"
    t.string   "param10"
    t.integer  "metadatum_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_column_ints", :force => true do |t|
    t.integer  "val"
    t.integer  "datum_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metadata", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
