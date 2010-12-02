#20101129220100
class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string :name
      t.integer :iq
      t.date :birthdate
      t.integer :exam_id

      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end
