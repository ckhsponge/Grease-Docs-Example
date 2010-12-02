module GreaseDocModel
  
  def self.included(base)
    base.extend(ClassMethods)
    base.after_create :init_grease_doc
  end
  
  module ClassMethods
    def grease_doc_collection(collection, args = {})
      puts "set_grease_doc_collection #{collection.inspect}"
      @@grease_doc_collection_name = collection
      raise "No class set. Must include :class" unless args[:class]
      @@grease_doc_collection_class = args[:class]
    end
    
    def grease_doc_columns(columns, args = {})
      @@grease_doc_column_fields = columns
      @@grease_doc_headers = args[:names]
      @@grease_doc_headers ||= columns.collect{|c| c.to_s}
    end
    
    def grease_doc_collection_name
      @@grease_doc_collection_name
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
  
  def grease_doc_url
    return "https://spreadsheets.google.com/ccc?key=#{self.grease_doc_key}&authkey=#{self.grease_doc_authkey}"
  end
  
  def grease_doc_url_csv
    "https://spreadsheets.google.com/feeds/download/spreadsheets/Export?key=#{self.grease_doc_key}&exportFormat=csv"
  end
  
  def grease_doc_collection
    self.send(self.class.grease_doc_collection_name)
  end
  
  def grease_doc_csv
    raise "headers not set" unless self.class.grease_doc_headers
    result = ""
    columns = self.class.grease_doc_headers.size
    CSV.generate_row(self.class.grease_doc_headers, columns, result)
    self.grease_doc_collection.each do |object|
      csv_row = self.class.grease_doc_column_fields.collect {|c| object.send(c)}
      CSV.generate_row(csv_row, columns, result)
    end
    return result
  end
  
  def send_grease_doc
    data = self.grease_doc_csv
    api = GreaseDocAuthentication.google_doclist_api
    api.headers["Content-Type"] = "text/csv"
    api.headers["If-Match"] = "*"
    api.version = "3.0"
    response = api.put("https://docs.google.com/feeds/default/media/document%3A#{self.grease_doc_key}", data)
    puts response.inspect
  end
  
  def retrieve_grease_doc
    puts self.grease_doc_csv
    #response = HTTParty.get( self.url_csv )
    api = GreaseDocAuthentication.google_spreadsheets_api
    api.version = "3.0"
    #api.headers["Content-Type"] = "text/html"
    response = api.get( self.grease_doc_url_csv )
    data = response.body
    puts data
    google_header = nil
    existing_ids = self.grease_doc_collection.collect{|p| p.id}
    google_rows = []
    CSV::Reader.parse(data) do |row|
      unless google_header
        google_header = row
        puts google_header.inspect
        next
      end
      row[0] = (row[0] && !row[0].blank?) ? row[0].to_i : nil
      google_rows << row if row && row.inject(false){|s,r| s || !r.blank?}
    end
    google_ids = google_rows.collect{|r| r[0]}.delete_if{|r| r.blank?}
    puts "existing: #{existing_ids.inspect}"
    puts "google: #{google_ids.inspect}"
    puts "google rows: #{google_rows.inspect}"
    self.class.transaction do
      google_rows.each do |row|
        puts row.inspect
        if existing_ids.include?(row[0])
          object = self.class.grease_doc_collection_class.find_by_id(row[0])
        else
          object = self.class.grease_doc_collection_class.new(:exam => self)
        end
        for i in 1...(google_header.size)
          #puts "#{i} #{row[i]}"
          object.send( "#{self.class.grease_doc_column_fields[i]}=", row[i])
        end
        object.save!
      end
      missing_ids = existing_ids - google_ids
      puts "missing: #{missing_ids.inspect}"
      self.grease_doc_collection.each do |object|
        object.delete if missing_ids.include?(object.id)
      end
    end
  end
  
  def init_grease_doc
    self.set_grease_doc_key
    self.set_grease_doc_authkey
    self.save!
  end
  
  def has_grease_doc?
    return self.grease_doc_key && self.grease_doc_authkey
  end
  
  def set_grease_doc_key
    xm = Builder::XmlMarkup.new(:indent => 2)
    xm.instruct!
    xm.entry(:xmlns => "http://www.w3.org/2005/Atom") do
      xm.category(:scheme => "http://schemas.google.com/g/2005#kind", :term => "http://schemas.google.com/docs/2007#spreadsheet")
      xm.title "#{self.class.to_s} #{self.id}"
    end
    data = xm.target!
    api = GreaseDocAuthentication.google_doclist_api
    api.version = "2"
    response = api.post("https://docs.google.com/feeds/documents/private/full", data)
    
    feed = response.to_xml    
    feed.elements.each do |entry|
      if entry.text && (k = entry.text[/full\/spreadsheet%3A(.*)/, 1])
        self.grease_doc_key = k
      end
    end
  end
  
  def set_grease_doc_authkey
    raise "key not set" unless self.grease_doc_key
      
    data = <<-EOF
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gAcl='http://schemas.google.com/acl/2007'>
  <category scheme='http://schemas.google.com/g/2005#kind'
    term='http://schemas.google.com/acl/2007#accessRule'/>
  <gAcl:withKey key='[ACL KEY]'><gAcl:role value='writer' /></gAcl:withKey>
  <gAcl:scope type='default' />
</entry>
EOF
    api = GreaseDocAuthentication.google_doclist_api
    api.version = "3.0"
    response = api.post("https://docs.google.com/feeds/default/private/full/#{self.grease_doc_key}/acl", data)
    
    feed = response.to_xml
    feed.elements.each("gAcl:withKey") do |entry|
      self.grease_doc_authkey = entry.attributes["key"]
    end
  end
end
