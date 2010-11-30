require "csv"

class GreaseDocsController < ApplicationController
  #before_filter :google_spreadsheets_api
  before_filter :find_grease_doc
  before_filter :google_doclist_api, :only => [:create, :edit_people, :refresh_people]
  before_filter :google_spreadsheets_api, :only => [:refresh_people]
  
  # GET /grease_docs
  # GET /grease_docs.xml
  def index
    @grease_docs = GreaseDoc.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grease_docs }
    end
  end

  # GET /grease_docs/1
  # GET /grease_docs/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @grease_doc }
    end
  end

  # GET /grease_docs/new
  # GET /grease_docs/new.xml
  def new
    @grease_doc = GreaseDoc.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @grease_doc }
    end
  end

  # GET /grease_docs/1/edit
  def edit
  end

  # POST /grease_docs
  # POST /grease_docs.xml
  def create
    @grease_doc = GreaseDoc.new(params[:grease_doc])
    @grease_doc.google_doclist_api = @google_doclist_api

    respond_to do |format|
      if @grease_doc.save
        flash[:notice] = 'GreaseDoc was successfully created.'
        format.html { redirect_to(@grease_doc) }
        format.xml  { render :xml => @grease_doc, :status => :created, :location => @grease_doc }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @grease_doc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /grease_docs/1
  # PUT /grease_docs/1.xml
  def update
    respond_to do |format|
      if @grease_doc.update_attributes(params[:grease_doc])
        flash[:notice] = 'GreaseDoc was successfully updated.'
        format.html { redirect_to(@grease_doc) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @grease_doc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /grease_docs/1
  # DELETE /grease_docs/1.xml
  def destroy
    @grease_doc.destroy

    respond_to do |format|
      format.html { redirect_to(grease_docs_url) }
      format.xml  { head :ok }
    end
  end
  
  def edit_people
    @grease_doc.people_to_google
  end
  
  def refresh_people
    @grease_doc.people_from_google
    render :action => "edit_people"
  end
  
  private
  
  def find_grease_doc
    @grease_doc = GreaseDoc.find(params[:id]) if params[:id]
  end
  
  def google_spreadsheets_api
    unless @google_spreadsheets_api
      @google_spreadsheets_api = ::GData::Client::Spreadsheets.new
      @google_spreadsheets_api.clientlogin(ENV['GOOGLE_EMAIL'], ENV['GOOGLE_PASSWORD'], nil, nil, nil, "GOOGLE")
    end
    @grease_doc.google_spreadsheets_api = @google_spreadsheets_api if @grease_doc
    return @google_spreadsheets_api
  end
  
  def google_doclist_api
    unless @google_doclist_api
      @google_doclist_api = ::GData::Client::DocList.new
      @google_doclist_api.clientlogin(ENV['GOOGLE_EMAIL'], ENV['GOOGLE_PASSWORD'], nil, nil, nil, "GOOGLE")
    end
    @grease_doc.google_doclist_api = @google_doclist_api if @grease_doc
    return @google_doclist_api
  end
end
