class Exam < ActiveRecord::Base
  has_many :people
  
  include GreaseDocModel
  grease_doc_collection :people, :class => Person
  grease_doc_columns [:id, :name, :iq, :birthdate], :names => ["ID", "Name", "IQ", "Birthdate"]
end
