class GreaseDoc
  def initialize(record)
    @record = record
  end
  
  def open
    self.send
    self.set_authkey
    @record.save!
  end
  
  def save
    self.retrieve
    self.delete_authkey
    @record.save!
  end
  
  def url
    return "https://spreadsheets.google.com/ccc?key=#{self.key}&authkey=#{self.authkey}"
  end
  
  def url_csv
    "https://spreadsheets.google.com/feeds/download/spreadsheets/Export?key=#{self.key}&exportFormat=csv"
  end
  
  def collection
    @record.send(@record.class.grease_doc_collection_name)
  end
  
  def csv
    raise "headers not set" unless @record.class.grease_doc_headers
    result = ""
    columns = @record.class.grease_doc_headers.size
    CSV.generate_row(@record.class.grease_doc_headers, columns, result)
    self.collection.each do |object|
      csv_row = @record.class.grease_doc_column_fields.collect {|c| object.send(c)}
      CSV.generate_row(csv_row, columns, result)
    end
    return result
  end
  
  def send
    data = self.csv
    api = self.authentication.google_doclist_api
    api.headers["Content-Type"] = "text/csv"
    api.headers["If-Match"] = "*"
    api.version = "3.0"
    response = api.put("https://docs.google.com/feeds/default/media/document%3A#{self.key}", data)
    puts response.inspect
  end
  
  def retrieve
    puts self.csv
    #response = HTTParty.get( self.url_csv )
    api = self.authentication.google_spreadsheets_api
    api.version = "3.0"
    #api.headers["Content-Type"] = "text/html"
    response = api.get( self.url_csv )
    data = response.body
    puts data
    google_header = nil
    existing_ids = self.collection.collect{|p| p.id}
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
    @record.class.transaction do
      google_rows.each do |row|
        puts row.inspect
        if existing_ids.include?(row[0])
          object = @record.class.grease_doc_collection_class.find_by_id(row[0])
        else
          object = @record.class.grease_doc_collection_class.new
          object.send("#{@record.class.grease_doc_association_name}=", @record)
        end
        for i in 1...(google_header.size)
          #puts "#{i} #{row[i]}"
          object.send( "#{@record.class.grease_doc_column_fields[i]}=", row[i])
        end
        object.save!
      end
      missing_ids = existing_ids - google_ids
      puts "missing: #{missing_ids.inspect}"
      self.collection.each do |object|
        object.delete if missing_ids.include?(object.id)
      end
    end
  end
  
  def exists?
    return @record.grease_doc_key && @record.grease_doc_authkey
  end
  
  def key
    @record.grease_doc_key
  end
  
  def authkey
    @record.grease_doc_authkey
  end
  
  def set_key
    xm = Builder::XmlMarkup.new(:indent => 2)
    xm.instruct!
    xm.entry(:xmlns => "http://www.w3.org/2005/Atom") do
      xm.category(:scheme => "http://schemas.google.com/g/2005#kind", :term => "http://schemas.google.com/docs/2007#spreadsheet")
      xm.title "#{self.class.to_s} #{self.id}"
    end
    data = xm.target!
    api = self.authentication.google_doclist_api
    api.version = "2"
    response = api.post("https://docs.google.com/feeds/documents/private/full", data)
    
    feed = response.to_xml    
    feed.elements.each do |entry|
      if entry.text && (k = entry.text[/full\/spreadsheet%3A(.*)/, 1])
        @record.grease_doc_key = k
      end
    end
  end
  
  def set_authkey
    raise "key not set" unless self.key
      
    data = <<-EOF
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gAcl='http://schemas.google.com/acl/2007'>
  <category scheme='http://schemas.google.com/g/2005#kind'
    term='http://schemas.google.com/acl/2007#accessRule'/>
  <gAcl:withKey key='[ACL KEY]'><gAcl:role value='writer' /></gAcl:withKey>
  <gAcl:scope type='default' />
</entry>
EOF
    api = self.authentication.google_doclist_api
    api.version = "3.0"
    response = api.put("https://docs.google.com/feeds/default/private/full/#{self.key}/acl/default", data)
    
    feed = response.to_xml
    feed.elements.each("gAcl:withKey") do |entry|
      @record.grease_doc_authkey = entry.attributes["key"]
    end
  end
  
  def delete_grease_doc_authkey
    raise "key not set" unless self.key
      
    data = <<-EOF
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gAcl='http://schemas.google.com/acl/2007'>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/acl/2007#accessRule'/>
  <gAcl:withKey key='[ACL KEY]'><gAcl:role value='none' /></gAcl:withKey>
  <gAcl:scope type='default' />
</entry>
EOF
    api = self.authentication.google_doclist_api
    api.version = "3.0"
    
    response = api.put("https://docs.google.com/feeds/default/private/full/#{self.key}/acl/default", data)
    #puts response.inspect
    
    self.grease_doc_authkey = nil
  end
  
  def authentication
    @authentication ||= GreaseDocAuthentication.new
  end
end