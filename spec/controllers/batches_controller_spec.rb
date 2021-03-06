require 'rails_helper'

RSpec.describe BatchesController, type: :controller do
  before :each do
    @batch = FactoryGirl.create(:batch)
  end

  it 'has a valid factory' do
    expect(@batch).to be_valid
    expect(FactoryGirl.create(:test)).to be_valid
    expect(FactoryGirl.create(:alternate_test_method)).to be_valid
  end

  describe 'before_actions' do
    it 'authenticates user' do
      sign_out :all
      get :index
      expect(response).to redirect_to new_user_session_path
    end
    it 'checks user is admin or analyst' do
      sign_out :all
      sign_in(FactoryGirl.create(:user))
      get :index
      expect(response).to redirect_to root_path
      sign_out :user
      sign_in(FactoryGirl.create(:analyst))
      get :index
      expect(response).to render_template :index
      sign_out :analyst
      sign_in(FactoryGirl.create(:admin))
      get :index
      expect(response).to render_template :index
    end
    it 'checks for cancel' do
      sign_in(FactoryGirl.create(:analyst))
      post :create, params: { test_method: TestMethod.first, commit: "Cancel" }
      expect(response).to redirect_to batches_path
      expect{response}.to change{Batch.count}.by (0)
    end
  end

  describe '#index' do
    it 'finds all batches' do
      sign_in(FactoryGirl.create(:analyst))
      get :index
      expect(assigns(:batches).count).to eql(1) 
    end
  end

  describe '#show' do
    before :each do
      sign_in(FactoryGirl.create(:analyst))
    end
    it 'finds the batch' do
      get :show, params: { id: @batch.id }
      expect(assigns(:batch)).to eql(@batch)
    end
    it 'populates the pipets' do
      @pipet = FactoryGirl.create(:pipet)
      @batch.pipets = [@pipet]
      get :show, params: { id: @batch.id }
      expect(assigns(:pipets)).to eql("P#{@pipet.id}")
    end
  end

  describe '#new' do
    before :each do
      sign_in(FactoryGirl.create(:analyst))
    end
    it 'sets available methods' do
      @test = FactoryGirl.create(:test)
      @test2 = FactoryGirl.create(:test)
      @test3 = FactoryGirl.create(:test, test_method_id: @test.test_method_id)
      get :new
      expect(assigns(:available_methods)).to eql([
        [@test.test_method.name, @test.test_method_id], [@test2.test_method.name, @test2.test_method_id]
      ])
    end
    it 'sets batch' do
      get :new
      expect(assigns(:batch)).to be_a_new(Batch)
    end
    it 'builds batch with tests' do
      @test = FactoryGirl.create(:test)
      @batch.tests = [@test]
      expect(@batch.tests.count).to eql(1)
    end
  end

  describe '#create' do
    before :each do
      sign_in(FactoryGirl.create(:analyst))
    end
    context 'with valid parameters' do
      it 'creates new batch' do
        expect {
          post :create, params: { batch: @batch.attributes }
        }.to change { Batch.count }.by(1)
      end
      it 'renders flash' do
        post :create, params: { batch: @batch.attributes }
        expect(flash[:info]).to be_present
      end
      it 'redirects to edit batch' do
        post :create, params: { batch: @batch.attributes }
        expect(response).to redirect_to edit_batch_path(assigns(:batch))
      end
    end

    context 'with invalid parameters' do
      before :each do
        @invalid_batch = Batch.create()
      end
      it 'does not save new batch' do
        expect {
          post :create, params: { batch: @invalid_batch.attributes }
        }.to change{ Batch.count }.by(0)
      end
      it 'flashes danger' do
        post :create, params: { batch: @invalid_batch.attributes }
        expect(flash[:danger]).to be_present
      end
      it 'renders new template' do
        post :create, params: { batch: @invalid_batch.attributes }
        expect(response).to render_template :new
      end
    end
  end

  describe '#add' do
    before :each do
      sign_in(FactoryGirl.create(:analyst))
      @batch = FactoryGirl.create(:batch)
      @test = FactoryGirl.create(:test, batch: @batch)
    end
    it 'finds the test' do
      get :add, :params => {batch_id: @batch.id, id: @test.id}
      expect(assigns(:test)).to eql(@test)
    end
    it 'finds the batch' do
      get :add, :params => {batch_id: @batch.id, id: @test.id}
      expect(assigns(:batch)).to eql(@batch)
    end
    it 'add test with valid parameters' do
      test = Test.create!(test_method: @batch.test_method, sample: Sample.first)
      expect {
        post :add, :params =>{batch_id: @batch.id, id: test.id}
      }.to change { @batch.tests.count }.by(1)
    end
    it 'flashes danger with invalid params' do
      alt_test_method = FactoryGirl.create(:alternate_test_method)
      test = Test.create!(test_method: alt_test_method, sample: Sample.first)
      post :add, :params => { batch_id: @batch.id, id: test.id }

      expect(flash[:danger]).to be_present
    end
    it 'redirects with invalid params' do
      alt_test_method = FactoryGirl.create(:alternate_test_method)
      test = Test.create!(test_method: alt_test_method, sample: Sample.first)
      post :add, :params => { batch_id: @batch.id, id: test.id }

      expect(response).to redirect_to edit_batch_path(@batch)
    end
  end

  describe "#edit" do
    before :each do
      sign_in(FactoryGirl.create(:analyst))
    end
    it 'finds the batch' do
      get :edit, :params => { id: @batch }
      expect(assigns(:batch)).to eql(@batch)
    end
    it 'adds previous pipets to @selected' do
      @expected = @batch.pipets.map{|p| p.id}
      get :edit, :params => { id: @batch }
      expect(assigns(:selected)).to eql(@expected)
    end
    it 'clears the pipets' do
      get :edit, :params => {id: @batch}
      expect(@batch.pipets.count).to eql(0)
    end
    it 'rebuilds pipets' do
      FactoryGirl.create(:pipet)
      get :edit, :params => {id: @batch}
      expect(assigns(:pipets).length).to eql(2)
    end
    it 'populates unbatched table if batch has no tests' do
      get :edit, :params => {id: @batch}
      @batch.tests.delete_all
      expect(assigns(:tests_available_to_add)).to eql(Test.unbatched(@batch.test_method_id))
    end
    it 'populates batch with all unbatched tests' do
      FactoryGirl.create(:test, test_method_id: @batch.test_method_id)
      @new_batch = Batch.create!(test_method: @batch.test_method)
      get :edit, :params => {id: @new_batch}
      expect(assigns(:batch).tests.count).to eql(Test.unbatched(@new_batch.test_method_id).count)
    end
  end

  describe "#results" do
    it 'finds the batch' do
      sign_in(FactoryGirl.create(:admin))
      get :results, :params => {batch_id: @batch}
      expect(assigns(:batch)).to eql(@batch)
    end
  end

  describe "#update" do
    before :each do
      sign_in(FactoryGirl.create(:analyst))
      @batch = FactoryGirl.create(:batch)
      @new_test_method = FactoryGirl.create(:test_method)
    end

    context 'with valid params' do
      before :each do 
        @batch.test_method = @new_test_method
      end

      it 'updates batch' do
        put :update, :params => { batch: @batch.attributes, id: @batch.id }
        @batch.reload
        expect(@batch.test_method).to eql(@new_test_method)
      end
      it 'flashes success' do
        put :update, :params => { batch: @batch.attributes, id: @batch.id }
        @batch.reload
        expect(flash[:success]).to be_present
      end
      it 'redirects to batch' do
        put :update, :params => { batch: @batch.attributes, id: @batch.id }
        @batch.reload
        expect(response).to redirect_to batch_path(@batch)
      end
    end

    context 'with invalid params' do
      it 'does not update' do
        @batch.test_method = nil
        put :update, :params => { batch: @batch.attributes, id: @batch.id }
        @batch.reload
        expect(@batch.test_method).to_not eql(nil)
      end
      it 'flashes warning' do
        @batch.test_method = nil
        put :update, :params => { batch: @batch.attributes, id: @batch.id }
        @batch.reload
        expect(flash[:warning]).to be_present
      end
      it 'renders edit' do
        @batch.test_method = nil
        put :update, :params => { batch: @batch.attributes, id: @batch.id }
        @batch.reload
        expect(response).to render_template :edit
      end
    end
  end

  describe "#destroy" do

    before :each do
      sign_in(FactoryGirl.create(:analyst))
    end

    it 'deletes batch' do
      expect{
        delete :destroy, :params => { id: @batch.id }        
      }.to change(Batch, :count).by(-1)
    end
    it 'flashes success' do
      delete :destroy, :params => { id: @batch.id }
      expect(flash[:success]).to be_present
    end
    it 'redirects to batches path' do
      delete :destroy, :params => { id: @batch.id }
      expect(response).to redirect_to batches_path
    end
  end
end