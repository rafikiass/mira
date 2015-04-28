require 'spec_helper'

describe RecordsController do

  describe "an admin" do
    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user
    end

    describe 'reviews a record - happy path:' do
      before do
        @record = FactoryGirl.create(:tufts_pdf)
        put :review, id: @record
      end
      after { @record.delete }

      it 'assigns @record' do
        expect(assigns(:record)).to eq @record
      end

      it 'redirects to the record show page' do
        response.should redirect_to catalog_path(@record)
      end

      it 'marks the record as reviewed' do
        expect(@record.reload.reviewed?).to be_truthy
      end

      it 'sets the flash' do
        expect(flash[:notice]).to eq "\"#{@record.title}\" has been marked as reviewed."
      end
    end

    describe 'reviews a record - when it fails to save:' do
      before do
        @record = FactoryGirl.create(:tufts_pdf)
        TuftsPdf.any_instance.should_receive(:save) { false }
        put :review, id: @record
      end
      after { @record.delete }

      it 'sets the flash' do
        expect(flash[:error]).to eq "Unable to mark \"#{@record.title}\" as reviewed."
      end
    end

    describe "reviews a record - when it's not a reviewable record :" do
      before do
        @record = FactoryGirl.create(:tufts_template)
        put :review, id: @record
      end
      after { @record.delete }

      it 'does not mark the record as reviewed' do
        expect(flash[:error]).to eq "Unable to mark \"#{@record.title}\" as reviewed."
      end
    end

    describe "who goes to the new page" do
      routes { HydraEditor::Engine.routes }

      it "should be successful" do
        get :new
        response.should be_successful
        response.should render_template(:choose_type)
      end

      it "should be successful without a pid" do
        get :new, :type=>'TuftsAudio'
        assigns[:record].should be_kind_of TuftsAudio
        assigns[:record].should_not be_new_record
        response.should redirect_to Tufts::Application.routes.url_helpers.record_attachments_path(assigns[:record])
      end

      describe 'with type TuftsTemplate' do
        before { get :new, :type=>'TuftsTemplate' }

        it 'creates a new template' do
          assigns[:record].should be_kind_of TuftsTemplate
        end

        it 'redirects to allow you to edit the new template' do
          response.should redirect_to HydraEditor::Engine.routes.url_helpers.edit_record_path(assigns[:record])
        end
      end

      describe "with a pid" do
        let(:pid) { 'tufts:123.1231' }
        let(:draft_pid) { 'draft:123.1231' }

        before do
          begin
            a = TuftsAudio.find(pid)
            a.destroy
          rescue ActiveFedora::ObjectNotFoundError
          end
        end

        it "should assign a draft pid" do
          get :new, :type=>'TuftsAudio', :pid=>pid
          assigns[:record].should be_kind_of TuftsAudio
          assigns[:record].should_not be_new_record
          response.should redirect_to Tufts::Application.routes.url_helpers.record_attachments_path(assigns[:record])
          assigns[:record].pid.should == draft_pid
        end
      end

      describe "with the pid of an existing object" do
        let(:record) { TuftsAudio.create(title: "existing", displays: ['dl']) }
        it "should redirect to the edit page and give a warning" do
          get :new, :type=>'TuftsAudio', :pid=>record.id
          response.should redirect_to HydraEditor::Engine.routes.url_helpers.edit_record_path(record.id)
          flash[:alert].should == "A record with the pid \"#{record.id}\" already exists."
        end
      end

      it "should be an error with an invalid pid" do
        get :new, :type=>'TuftsAudio', :pid => 'demo:FLORA:01.01'
        response.should be_successful
        response.should render_template(:choose_type)
        flash[:error].should == "You have specified an invalid pid. Pids must be in this format: tufts:1231"
      end
    end

    describe "creating a new record" do
      before { @routes = HydraEditor::Engine.routes }

      it "should be successful" do
        post :create, :type=>'TuftsAudio', :tufts_audio=>{:title=>"My title", displays: ['dl']}
        response.should redirect_to("/catalog/#{assigns[:record].pid}")
        assigns[:record].title.should == 'My title'
      end
    end

    describe "editing a record" do
      before do
        @routes = HydraEditor::Engine.routes
        @audio = TuftsAudio.new(title: 'My title2', displays: ['dl'])
        @audio.edit_users = [@user.email]
        @audio.save!

        @draft = TuftsAudio.build_draft_version(@audio.attributes.except('id').merge(pid: @audio.pid))
        @draft.edit_users = [@user.email]
        @draft.save!
      end

      after do
        @audio.destroy
      end

      context 'when editing the draft version' do
        it "should be successful" do
          get :edit, id: @draft.pid
          expect(response).to be_successful
          expect(response).to render_template(:edit)
          expect(assigns[:record]).to eq @draft
        end
      end

      context 'when editing the non-draft version' do
        it 'redirects to edit form for draft version' do
          get :edit, id: @audio.pid
          expect(response).to redirect_to(HydraEditor::Engine.routes.url_helpers.edit_record_path(@draft))
        end
      end
    end

    describe 'cancel' do
      describe "on an object with no existing versions of DCA-META" do
        before do
          @audio = TuftsAudio.new()
          @audio.edit_users = [@user.email]
          @audio.save(validate: false)
        end
        it "should remove the record" do
          expect { delete :cancel, id: @audio}.to change{TuftsAudio.count}.by(-1)
        end
      end

      describe "on an object with an existing version of DCA-META" do
        before do
          @audio = TuftsAudio.new(title: "My title2", displays: ['dl'])
          @audio.edit_users = [@user.email]
          @audio.save!
        end
        it "should not remove the record" do
          expect { delete :cancel, id: @audio}.to_not change{TuftsAudio.count}
        end
      end

      describe "for a template" do
        before do
          @template = TuftsTemplate.new(template_name: 'My Template', title:'Populate DCA-META')
          @template.save!
        end
        after do
          @template.destroy
        end
        it "redirects back to the template index" do
         delete :cancel, id: @template
         response.should redirect_to(Tufts::Application.routes.url_helpers.templates_path)
        end
      end

      it "should not remove the record if there are no existing versions of the dca-META" do
      end
    end

    describe "updating a record" do
      before { @routes = HydraEditor::Engine.routes }

      describe "for a template" do
        before do
          @template = TuftsTemplate.new(template_name: 'My Template')
          @template.save!
        end
        after do
          @template.destroy
        end
        it "redirects back to the template index" do
          put :update, id: @template, tufts_template: {template_name: "My Updated Template"}
          response.should redirect_to(Tufts::Application.routes.url_helpers.templates_path)
          expect(@template.reload.template_name).to eq "My Updated Template"
        end
      end

      describe "with an audio" do
        before do
          @audio = TuftsAudio.new(title: 'My title2', displays: ['dl'])
          @audio.edit_users = [@user.email]
          @audio.save!

          @draft = TuftsAudio.build_draft_version(@audio.attributes.except('id').merge(pid: @audio.pid))
          @draft.save!
        end

        after do
          @audio.destroy
          @draft.destroy
        end

        it "successfully updates draft version of object" do
          put :update, :id=>@audio, :tufts_audio=>{:title=>"My title 3"}
          expect(response).to redirect_to("/catalog/#{assigns[:record].pid}")
          expect(assigns[:record]).to eq @draft
          expect(assigns[:record].title).to eq 'My title 3'
        end

        it "should update external datastream paths" do
          put :update, :id=>@audio, :tufts_audio=>{:datastreams=>{"ACCESS_MP3"=>"http://example.com/access.mp3", "ARCHIVAL_WAV"=>"http://example.com/archival.wav"} }
          expect(response).to redirect_to("/catalog/#{assigns[:record].pid}")
          expect(assigns[:record].datastreams['ACCESS_MP3'].dsLocation).to eq 'http://example.com/access.mp3'
          expect(assigns[:record].datastreams['ARCHIVAL_WAV'].dsLocation).to eq 'http://example.com/archival.wav'
        end

        it 'should update the collection id' do
          put :update, :id=>@audio, :tufts_audio=>{:stored_collection_id=>["updated_id"]}
          expect(assigns[:record].stored_collection_id).to eq 'updated_id'
        end
      end

      describe "with an image" do
        before do
          @image = TuftsImage.new(title: "test image", displays: ['dl'])
          @image.edit_users = [@user.email]
          @image.save!

          @draft = TuftsImage.build_draft_version(@image.attributes.except('id').merge(pid: @image.pid))
          @draft.save!
        end

        after do
          @image.destroy
          @draft.destroy
        end

        it "should update external datastream paths" do
          put :update, :id=>@image, :tufts_image=>{:datastreams=>{"Advanced.jpg"=>"http://example.com/advanced.jpg", "Basic.jpg"=>"http://example.com/basic.jpg", "Archival.tif"=>"http://example.com/archival.tif", "Thumbnail.png"=>"http://example.com/thumb.png"} }
          expect(response).to redirect_to("/catalog/#{assigns[:record].pid}")
          expect(assigns[:record].datastreams['Advanced.jpg'].dsLocation).to eq 'http://example.com/advanced.jpg'
          expect(assigns[:record].datastreams['Basic.jpg'].dsLocation).to eq 'http://example.com/basic.jpg'
          expect(assigns[:record].datastreams['Archival.tif'].dsLocation).to eq 'http://example.com/archival.tif'
          expect(assigns[:record].datastreams['Thumbnail.png'].dsLocation).to eq 'http://example.com/thumb.png'

        end
      end
    end

    describe "publish a record" do
      before do
        @audio = TuftsAudio.new(title: 'My title2', displays: ['dl'])
        @audio.edit_users = [@user.email]
        @audio.save!
      end

      after do
        @audio.destroy
      end

      it "should be successful" do
        expect_any_instance_of(PublishService).to receive(:run).once

        post :publish, id: @audio

        response.should redirect_to("/catalog/#{assigns[:record].pid}")
        flash[:notice].should == '"My title2" has been pushed to production'
      end
    end

    describe "unpublish a record" do
      let(:audio) do
        TuftsAudio.build_draft_version(title: 'My title2', displays: ['dl']).tap do |audio|
          audio.edit_users = [@user.email]
          audio.save!
        end
      end

      after { audio.destroy }

      before { PublishService.new(audio).run }

      it "should be successful" do
        expect_any_instance_of(UnpublishService).to receive(:run).once

        post :unpublish, id: audio
        expect(response).to redirect_to catalog_path(audio)
        expect(flash[:notice]).to eq '"My title2" has been unpublished'
      end
    end

    describe "reverting a record" do
      before do
        @audio = TuftsAudio.new(title: 'My title2', displays: ['dl'])
        @audio.edit_users = [@user.email]
        @audio.save!

        @draft = TuftsAudio.build_draft_version(@audio.attributes.except('id').merge(pid: @audio.pid))
        @draft.save!
      end

      context "when the record has not been published" do
        it "should be successful with a pid" do
          expect(@audio).to_not be_published

          TuftsAudio.any_instance.should_receive(:revert!).once

          post :revert, id: @draft
          response.should redirect_to(catalog_path(@draft))
        end

      end

      context "when the record is published" do
        before do
          @audio.publish!
        end
        it "should be successful with a pid" do
          expect(@audio).to be_published

          TuftsAudio.any_instance.should_receive(:revert!).once

          post :revert, id: @draft
          response.should redirect_to(catalog_path(@draft))
        end
      end
    end

    describe "destroying a record" do
      before do
        @audio = TuftsAudio.new(title: 'My title2', displays: ['dl'])
        @audio.edit_users = [@user.email]
        @audio.save!
      end

      context "when the record has not been published" do

        it "should be successful with a pid" do
          expect(@audio).to_not be_published
          expect_any_instance_of(PurgeService).to receive(:run).never

          delete :destroy, id: @audio

          response.should redirect_to(Tufts::Application.routes.url_helpers.root_path)
          @audio.reload.state.should == 'D'
        end

      end

      context "when the record has been published" do
        before do
          PublishService.new(@audio).run
          expect(@audio).to be_published
        end

        it "should be successful with a pid" do
          expect_any_instance_of(PurgeService).to receive(:run).once

          delete :destroy, id: @audio

          expect(response).to redirect_to(Tufts::Application.routes.url_helpers.root_path)
          expect(@audio.reload.state).to eq 'D'
        end
      end

    end

    describe "destroying a template" do
      before do
        @template = TuftsTemplate.new(template_name: 'My Template')
        @template.save!
      end
      it "routes back to the template index" do
        delete :destroy, :id=>@template
        response.should redirect_to(Tufts::Application.routes.url_helpers.templates_path)
      end
    end
  end



  describe "a non-admin" do
    before do
      sign_in FactoryGirl.create(:user)
    end

    describe "who goes to the new page" do
      routes { HydraEditor::Engine.routes }

      it "should not be allowed" do
        get :new
        expect(response).to be_redirect
        response.should redirect_to Tufts::Application.routes.url_helpers.root_path
        flash[:alert].should =~ /You are not authorized to access this page/i
      end
    end

    describe "who goes to the edit page" do
      routes { HydraEditor::Engine.routes }
      before do
        @audio = TuftsAudio.create!(title: 'My title2', displays: ['dl'])
      end
      after do
        @audio.destroy
      end
      it "should not be allowed" do
        get :edit, id: @audio
        expect(response).to redirect_to Tufts::Application.routes.url_helpers.contributions_path
        expect(flash[:alert]).to match /You do not have sufficient privileges to edit this document/i
      end
    end

    describe 'reviews a record' do
      before do
        @record = FactoryGirl.create(:tufts_pdf)
        put :review, id: @record
      end
      after { @record.delete }

      it 'should not be allowed' do
        response.status.should == 302
        response.should redirect_to Tufts::Application.routes.url_helpers.root_path
        flash[:alert].should =~ /You are not authorized to access this page/i
      end
    end
  end

end
