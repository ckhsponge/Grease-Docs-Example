class GreaseDoc < ActiveRecord::Base
  has_many :people
  
  attr_accessor :google_doclist_api
  attr_accessor :google_spreadsheets_api
  before_create :set_key
  before_create :set_authkey
  
  def url_share
    return "https://spreadsheets.google.com/ccc?key=#{self.key}&authkey=#{self.authkey}"
  end
  
  def url_csv
    "https://spreadsheets.google.com/feeds/download/spreadsheets/Export?key=#{self.key}&exportFormat=csv"
  end
  
  def to_csv
    result = ""
    columns = Person::CSV_HEADER.size
    CSV.generate_row(Person::CSV_HEADER, columns, result)
    self.people.each do |person|
      CSV.generate_row(person.csv_row, columns, result)
    end
    return result
  end
  
  def people_to_google
    data = self.to_csv
    @google_doclist_api.headers["Content-Type"] = "text/csv"
    @google_doclist_api.headers["If-Match"] = "*"
    @google_doclist_api.version = "3.0"
    response = @google_doclist_api.put("https://docs.google.com/feeds/default/media/document%3A#{self.key}", data)
    puts response.inspect
  end
  
  def people_from_google
    puts self.url_csv
    #response = HTTParty.get( self.url_csv )
    api = @google_spreadsheets_api
    api.version = "3.0"
    #api.headers["Content-Type"] = "text/html"
    response = api.get( self.url_csv )
    data = response.body
    puts data
    google_header = nil
    existing_ids = self.people.collect{|p| p.id}
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
    Person.transaction do
      google_rows.each do |row|
        puts row.inspect
        if existing_ids.include?(row[0])
          person = Person.find_by_id(row[0])
        else
          person = Person.new(:grease_doc => self)
        end
        for i in 1...(google_header.size)
          #puts "#{i} #{row[i]}"
          person.send( "#{Person::CSV_COLUMNS[i]}=", row[i])
        end
        person.save!
      end
      missing_ids = existing_ids - google_ids
      puts "missing: #{missing_ids.inspect}"
      self.people.each do |person|
        person.delete if missing_ids.include?(person.id)
      end
    end
  end
  
  private
  def set_key
    raise "google_doclist_api not set" unless @google_doclist_api
      
    xm = Builder::XmlMarkup.new(:indent => 2)
    xm.instruct!
    xm.entry(:xmlns => "http://www.w3.org/2005/Atom") do
      xm.category(:scheme => "http://schemas.google.com/g/2005#kind", :term => "http://schemas.google.com/docs/2007#spreadsheet")
      xm.title self.name
    end
    data = xm.target!
    @google_doclist_api.version = "2"
    response = @google_doclist_api.post("https://docs.google.com/feeds/documents/private/full", data)
    
    feed = response.to_xml    
    feed.elements.each do |entry|
      if entry.text && (k = entry.text[/full\/spreadsheet%3A(.*)/, 1])
        self.key = k
      end
    end
  end
  
  def set_authkey
    raise "google_doclist_api not set" unless @google_doclist_api
    raise "key not set" unless self.key
      
    data = <<-EOF
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gAcl='http://schemas.google.com/acl/2007'>
  <category scheme='http://schemas.google.com/g/2005#kind'
    term='http://schemas.google.com/acl/2007#accessRule'/>
  <gAcl:withKey key='[ACL KEY]'><gAcl:role value='writer' /></gAcl:withKey>
  <gAcl:scope type='default' />
</entry>
EOF
    @google_doclist_api.version = "3.0"
    response = @google_doclist_api.post("https://docs.google.com/feeds/default/private/full/#{self.key}/acl", data)
    
    feed = response.to_xml
    feed.elements.each("gAcl:withKey") do |entry|
      self.authkey = entry.attributes["key"]
    end
  end
end
