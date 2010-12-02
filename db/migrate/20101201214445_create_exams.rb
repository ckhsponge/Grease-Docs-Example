class CreateExams < ActiveRecord::Migration
  def self.up
    create_table :exams do |t|
      t.string :name
      t.string :grease_doc_key
      t.string :grease_doc_authkey

      t.timestamps
    end
  end

  def self.down
    drop_table :exams
  end
end
