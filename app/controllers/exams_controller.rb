require "csv"

class ExamsController < ApplicationController
  before_filter :find_exam
  
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
    @exam.grease_doc_open
  end
  
  def save_people
    @exam.grease_doc_save
    redirect_to exam_people_path(@exam)
  end
  
  def save_people_continue
    @exam.retrieve_grease_doc
    @exam = Exam.find(@exam.id)
    @exam.send_grease_doc
    render :partial => "success"
  end
  
  def revert_people
    @exam.send_grease_doc
    render :partial => "success"
  end
  
  def cancel_edit_people
    @exam.delete_grease_doc_authkey
    @exam.save!
    redirect_to exam_people_path(@exam)
  end
  
  private
  
  def find_exam
    @exam = Exam.find(params[:id]) if params[:id]
  end
  
end
