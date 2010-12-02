require "csv"

class ExamsController < ApplicationController
  #before_filter :google_spreadsheets_api
  before_filter :find_exam
  before_filter :google_doclist_api, :only => [:create, :edit_people, :revert_people, :save_people, :save_people_continue]
  before_filter :google_spreadsheets_api, :only => [:save_people, :save_people_continue]
  
  # GET /exams
  # GET /exams.xml
  def index
    @exams = Exam.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @exams }
    end
  end

  # GET /exams/1
  # GET /exams/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @exam }
    end
  end

  # GET /exams/new
  # GET /exams/new.xml
  def new
    @exam = Exam.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @exam }
    end
  end

  # GET /exams/1/edit
  def edit
  end

  # POST /exams
  # POST /exams.xml
  def create
    @exam = Exam.new(params[:exam])
    @exam.google_doclist_api = @google_doclist_api

    respond_to do |format|
      if @exam.save
        flash[:notice] = 'Exam was successfully created.'
        format.html { redirect_to(@exam) }
        format.xml  { render :xml => @exam, :status => :created, :location => @exam }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @exam.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /exams/1
  # PUT /exams/1.xml
  def update
    respond_to do |format|
      if @exam.update_attributes(params[:exam])
        flash[:notice] = 'Exam was successfully updated.'
        format.html { redirect_to(@exam) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @exam.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /exams/1
  # DELETE /exams/1.xml
  def destroy
    @exam.destroy

    respond_to do |format|
      format.html { redirect_to(exams_url) }
      format.xml  { head :ok }
    end
  end
  
  def edit_people
    @exam.people_to_google
  end
  
  def refresh_people
    @exam.people_from_google
    render :action => "edit_people"
  end
  
  def save_people
    @exam.people_from_google
    redirect_to exam_people_path(@exam)
  end
  
  def save_people_continue
    @exam.people_from_google
    @exam = Exam.find(@exam.id)
    @exam.google_doclist_api = @google_doclist_api
    @exam.people_to_google
    render :partial => "success"
  end
  
  def revert_people
    @exam.people_to_google
    render :partial => "success"
  end
  
  private
  
  def find_exam
    @exam = Exam.find(params[:id]) if params[:id]
  end
  
  def google_spreadsheets_api
    unless @google_spreadsheets_api
      @google_spreadsheets_api = ::GData::Client::Spreadsheets.new
      @google_spreadsheets_api.clientlogin(ENV['GOOGLE_EMAIL'], ENV['GOOGLE_PASSWORD'], nil, nil, nil, "GOOGLE")
    end
    @exam.google_spreadsheets_api = @google_spreadsheets_api if @exam
    return @google_spreadsheets_api
  end
  
  def google_doclist_api
    unless @google_doclist_api
      @google_doclist_api = ::GData::Client::DocList.new
      @google_doclist_api.clientlogin(ENV['GOOGLE_EMAIL'], ENV['GOOGLE_PASSWORD'], nil, nil, nil, "GOOGLE")
    end
    @exam.google_doclist_api = @google_doclist_api if @exam
    return @google_doclist_api
  end
end
