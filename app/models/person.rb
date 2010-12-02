class Person < ActiveRecord::Base
  belongs_to :exam
  
  CSV_HEADER = ["ID", "Name", "IQ", "Birthdate"]
  CSV_COLUMNS = [:id, :name, :iq, :birthdate]
  
  def csv_row
    CSV_COLUMNS.collect {|c| self.send(c)}
  end
end
