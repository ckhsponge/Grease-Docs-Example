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
  
  #push data to google and display the editor
  def edit_people
    @exam.grease_doc.open
  end
  
  #save data and close editor access
  def save_people
    @exam.grease_doc.save
    redirect_to exam_people_path(@exam)
  end
  
  #save data and refresh display
  def save_people_continue
    @exam.grease_doc.retrieve #get data from google and set any missing ids
    @exam = Exam.find(@exam.id) #refresh object
    @exam.grease_doc.send #send data back to object to update ids or other bad data
    render :partial => "success"
  end
  
  #send data to google to undo any changes made there
  def revert_people
    @exam.grease_doc.send
    render :partial => "success"
  end
  
  #close editor access without saving changes
  def cancel_edit_people
    @exam.grease_doc.delete_authkey
    redirect_to exam_people_path(@exam)
  end
  
  private
  
  def find_exam
    @exam = Exam.find(params[:id]) if params[:id]
  end
  
end
