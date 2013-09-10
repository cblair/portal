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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130904210634) do

  create_table "charts", :force => true do |t|
    t.string   "title"
    t.string   "x_column"
    t.string   "y_column"
    t.string   "xlab"
    t.string   "ylab"
    t.string   "chart_type"
    t.text     "options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "document_id"
    t.string   "share_token"
    t.boolean  "streaming"
    t.integer  "numdraw"
    t.integer  "source_doc"
  end

  create_table "collaborators", :force => true do |t|
    t.integer  "project_id"
    t.string   "project_name"
    t.integer  "user_id"
    t.string   "user_email"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.boolean  "editor"
  end

  create_table "collections", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "users_id"
    t.integer  "collection_id"
    t.integer  "user_id"
    t.boolean  "validated"
    t.string   "ancestry"
    t.integer  "project_id"
  end

  add_index "collections", ["ancestry"], :name => "index_collections_on_ancestry"

  create_table "collections_projects", :id => false, :force => true do |t|
    t.integer "collection_id"
    t.integer "project_id"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.integer  "job_id"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "documents", :force => true do |t|
    t.string   "name"
    t.integer  "collection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "validated"
    t.boolean  "public"
    t.integer  "project_id"
    t.integer  "job_id"
  end

  create_table "documents_users", :id => false, :force => true do |t|
    t.integer "document_id"
    t.integer "user_id"
  end

  create_table "feeds", :force => true do |t|
    t.string   "name"
    t.string   "feed_url"
    t.integer  "interval_val"
    t.string   "interval_unit"
    t.integer  "document_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "jid"
  end

  create_table "ifilters", :force => true do |t|
    t.string   "name"
    t.string   "regex"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jobs", :force => true do |t|
    t.text     "description"
    t.integer  "user_id"
    t.boolean  "finished"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.boolean  "waiting"
    t.string   "ar_name"
    t.integer  "ar_id"
    t.boolean  "started"
  end

  create_table "metadata", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notifications", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.boolean  "emailed"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "posts", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.text     "pdesc"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "collection_id"
    t.boolean  "public"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "searches", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "uploads", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "upfile_file_name"
    t.string   "upfile_content_type"
    t.integer  "upfile_file_size"
    t.datetime "upfile_updated_at"
    t.integer  "user_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_documents", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "document_id"
  end

end
