module GreaseDocModel
  
  def self.included(base)
    base.extend(ClassMethods)
    base.after_create :init_grease_doc
    #base.after_initialize :set_grease_doc
  end
  
  module ClassMethods
    def grease_doc_collection(collection, args = {})
      puts "set_grease_doc_collection #{collection.inspect}"
      @@grease_doc_collection_name = collection
      raise "No class set. Must include :class" unless args[:class]
      @@grease_doc_collection_class = args[:class]
      @@grease_doc_association_name = args[:association_name]
    end
    
    def grease_doc_columns(columns, args = {})
      @@grease_doc_column_fields = columns
      @@grease_doc_headers = args[:names]
      @@grease_doc_headers ||= columns.collect{|c| c.to_s}
    end
    
    def grease_doc_collection_name
      @@grease_doc_collection_name
    end
    
    def grease_doc_association_name
      @@grease_doc_association_name
    end
    
    def grease_doc_collection_class
      @@grease_doc_collection_class
    end
    
    def grease_doc_column_fields
      @@grease_doc_column_fields
    end
    
    def grease_doc_headers
      @@grease_doc_headers
    end
  end
  
  def init_grease_doc
    self.grease_doc.set_key
    self.grease_doc.set_authkey
    self.save!
  end
  
  def grease_doc
    @grease_doc ||= GreaseDoc.new(self)
  end
end
