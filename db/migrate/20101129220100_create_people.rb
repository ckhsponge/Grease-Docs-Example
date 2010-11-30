class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string :name
      t.integer :iq
      t.date :birthdate
      t.integer :grease_doc_id

      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end
