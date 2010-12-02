class GreaseDocAuthentication
  def self.google_spreadsheets_api
    #unless @@google_spreadsheets_api
      google_spreadsheets_api = ::GData::Client::Spreadsheets.new
      google_spreadsheets_api.clientlogin(ENV['GOOGLE_EMAIL'], ENV['GOOGLE_PASSWORD'], nil, nil, nil, "GOOGLE")
    #end
    return google_spreadsheets_api
  end
  
  def self.google_doclist_api
    #unless @@google_doclist_api
      google_doclist_api = ::GData::Client::DocList.new
      google_doclist_api.clientlogin(ENV['GOOGLE_EMAIL'], ENV['GOOGLE_PASSWORD'], nil, nil, nil, "GOOGLE")
    #end
    return google_doclist_api
  end
end