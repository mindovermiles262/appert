class BatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_user_privledges
  
  def index
    @batches = Batch.all
  end
  
  def show
    @batch = Batch.find(params[:id])
  end

  def new
    @available_methods = Batch.available_methods
    @batch = Batch.new
    @batch.tests.build
  end
  
  def create
    @batch = Batch.new(new_batch_params)
    if @batch.save
      flash[:info] = "Select Tests"
      redirect_to edit_batch_path(@batch)
    else
      flash[:danger] = "Unable to create Batch"
      render :new
    end
  end

  def edit
    @batch = Batch.find(params[:id])
    if @batch.tests.count > 0
      @batch.tests
      @tests_available_to_add = Test.where('batched=?', false)
                              .or(Test.where('batch_id=?', 0))
                              .where('test_method_id=?', @batch.test_method_id)
    else
      @batch.tests << Test.where( 'test_method_id=? AND batched=? OR batch_id=?', 
                                  @batch.test_method_id, false, '0')
    end
  end

  def update
    @batch = Batch.find(params[:id])
    if @batch.update_attributes(new_batch_params)
      # raise
      flash[:success] = "Batch Updated"
      redirect_to @batch
    end
  end

  def destroy
    Batch.find(params[:id]).destroy
    flash[:success] = "Batch Deleted"
    redirect_to batches_path
  end

  private

  def new_batch_params
    params.require(:batch).permit(:test_method_id, :tests_attributes => [
      :id, :batch_id])
  end
  
  def check_user_privledges
    unless current_user && (current_user.admin? || current_user.analyst?)
      flash[:danger] = "Unauthorized"
      redirect_to root_path
    end
  end
end