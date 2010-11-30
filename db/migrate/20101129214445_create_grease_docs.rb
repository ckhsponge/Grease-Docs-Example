class CreateGreaseDocs < ActiveRecord::Migration
  def self.up
    create_table :grease_docs do |t|
      t.string :name
      t.string :key
      t.string :authkey

      t.timestamps
    end
  end

  def self.down
    drop_table :grease_docs
  end
end
