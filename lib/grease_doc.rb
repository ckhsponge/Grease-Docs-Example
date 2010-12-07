class GreaseDoc
  attr_accessor :key_field, :authkey_field
  
  def initialize(record, options = nil)
    @record = record
    options ||= record.class.grease_doc_options
    @column_fields = options[:column_fields]
    @csv_header = options[:csv_header]
    @collection_name = options[:collection_name]
    @collection_class = options[:collection_class]
    @association_name = options[:association_name]
    
    raise "no record set" unless @record
    raise "column fields not set" unless @column_fields
    raise "headers not set" unless @csv_header
    raise "collection name not set" unless @collection_name
    raise "collection class not set" unless @collection_class
    raise "association name not set" unless @association_name
    
    @key_field = options[:key_field] || :grease_doc_key
    @authkey_field = options[:authkey_field] || :grease_doc_authkey
  end
  
  def open
    self.send
    self.set_authkey
  end
  
  def save
    self.retrieve
    self.delete_authkey
  end
  
  def url
    return "https://spreadsheets.google.com/ccc?key=#{self.key}&authkey=#{self.authkey}"
  end
  
  def url_csv
    "https://spreadsheets.google.com/feeds/download/spreadsheets/Export?key=#{self.key}&exportFormat=csv"
  end
  
  def collection
    @record.send(@collection_name)
  end
  
  def csv
    result = ""
    column_count = @csv_header.size
    CSV.generate_row(@csv_header, column_count, result)
    self.collection.each do |object|
      csv_row = @column_fields.collect {|c| object.send(c)}
      CSV.generate_row(csv_row, column_count, result)
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
  end
  
  def retrieve
    #response = HTTParty.get( self.url_csv )
    api = self.authentication.google_spreadsheets_api
    api.version = "3.0"
    #api.headers["Content-Type"] = "text/html"
    response = api.get( self.url_csv )
    data = response.body
    google_header = nil
    existing_ids = self.collection.collect{|p| p.id}
    google_rows = []
    CSV::Reader.parse(data) do |row|
      unless google_header
        google_header = row
        next
      end
      row[0] = (row[0] && !row[0].blank?) ? row[0].to_i : nil
      google_rows << row if row && row.inject(false){|s,r| s || !r.blank?}
    end
    google_ids = google_rows.collect{|r| r[0]}.delete_if{|r| r.blank?}
    #puts "existing: #{existing_ids.inspect}"
    #puts "google: #{google_ids.inspect}"
    #puts "google rows: #{google_rows.inspect}"
    @record.class.transaction do
      google_rows.each do |row|
        if existing_ids.include?(row[0])
          object = @collection_class.find_by_id(row[0])
        else
          object = @collection_class.new
          object.send("#{@association_name.to_s}=", @record)
        end
        for i in 1...(google_header.size)
          object.send( "#{@column_fields[i]}=", row[i])
        end
        object.save!
      end
      missing_ids = existing_ids - google_ids
      #puts "missing: #{missing_ids.inspect}"
      self.collection.each do |object|
        object.delete if missing_ids.include?(object.id)
      end
    end
  end
  
  def exists?
    return !!self.key
  end
  
  def editing?
    return !!self.authkey
  end
  
  def key
    @record.send( @key_field )
  end
  
  def key=(k)
    @record.send( "#{@key_field}=", k )
    @record.save!
  end
  
  def authkey
    @record.send( @authkey_field )
  end
  
  def authkey=(k)
    @record.send( "#{@authkey_field}=", k )
    @record.save!
  end
  
  def set_key
    xm = Builder::XmlMarkup.new(:indent => 2)
    xm.instruct!
    xm.entry(:xmlns => "http://www.w3.org/2005/Atom") do
      xm.category(:scheme => "http://schemas.google.com/g/2005#kind", :term => "http://schemas.google.com/docs/2007#spreadsheet")
      xm.title "#{@record.class.to_s} #{@record.id}"
    end
    data = xm.target!
    api = self.authentication.google_doclist_api
    api.version = "2"
    response = api.post("https://docs.google.com/feeds/documents/private/full", data)
    
    feed = response.to_xml    
    feed.elements.each do |entry|
      if entry.text && (k = entry.text[/full\/spreadsheet%3A(.*)/, 1])
       self.key = k
      end
    end
  end
  
  def set_authkey
    response = update_acl( :writer )
    
    feed = response.to_xml
    feed.elements.each("gAcl:withKey") do |entry|
      self.authkey = entry.attributes["key"]
    end
  end
  
  def delete_authkey
    response = update_acl( :none )
    self.authkey = nil
  end
  
  def update_acl( permission )
    raise "invalid permission" unless [:none, :writer].include?(permission)
    raise "key not set" unless self.key
    
    data = <<-EOF
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gAcl='http://schemas.google.com/acl/2007'>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/acl/2007#accessRule'/>
  <gAcl:withKey key='[ACL KEY]'><gAcl:role value='#{permission}' /></gAcl:withKey>
  <gAcl:scope type='default' />
</entry>
EOF
    api = self.authentication.google_doclist_api
    api.version = "3.0"
    
    return api.put("https://docs.google.com/feeds/default/private/full/#{self.key}/acl/default", data)
  end
  
  def authentication
    @authentication ||= GreaseDocAuthentication.new
  end
end