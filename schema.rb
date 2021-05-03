ActiveRecord::Schema.define(version: 2021_04_29_143800) do
  create_table "books", force: :cascade do |t|
    t.string "title"
  end
  
  create_table "chapters", force: :cascade do |t|
    t.bigint "book_id", force: :cascade
    t.string "title"
  end
end