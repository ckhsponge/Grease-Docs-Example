module GreaseDocModel
  
  def self.included(base)
    base.extend(ClassMethods)
    base.after_create :init_grease_doc
  end
  
  module ClassMethods
    def grease_doc_collection(collection, args = {})
      raise "no collection set" unless collection
      @@grease_doc_options ||= {}
      @@grease_doc_options[:collection_name] = collection
      raise "No class set. Must include :class" unless args[:class]
      @@grease_doc_options[:collection_class] = args[:class]
      @@grease_doc_options[:association_name] = args[:association_name] || self.to_s.underscore.to_sym
    end
    
    def grease_doc_columns(columns, args = {})
      @@grease_doc_options ||= {}
      raise "no columns set" unless columns
      @@grease_doc_options[:column_fields] = columns
      @@grease_doc_options[:csv_header] = args[:names] || columns.collect{|c| c.to_s}
    end
    
    def grease_doc_options
      @@grease_doc_options
    end
  end
  
  def init_grease_doc
    self.grease_doc.set_key
  end
  
  def grease_doc
    @grease_doc ||= GreaseDoc.new(self)
  end
end
