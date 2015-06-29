require 'spec_helper'

describe RecordsController do

  describe "an admin" do
    before do
      @user = create(:admin)
      sign_in @user
    end

    describe 'reviews a record - happy path:' do
      before do
        @record = create(:tufts_pdf)
        put :review, id: @record
      end
      after { @record.delete }

      it 'marks the record as reviewed' do
        expect(response).to redirect_to catalog_path(@record)
        expect(assigns(:record)).to eq @record
        expect(@record.reload).to be_reviewed
        expect(flash[:notice]).to eq "\"#{@record.title}\" has been marked as reviewed."
      end
    end

    describe 'reviews a record - when it fails to save:' do
      before do
        @record = create(:tufts_pdf)
        allow_any_instance_of(TuftsPdf).to receive(:save) { false }
        put :review, id: @record
      end
      after { @record.delete }

      it 'sets the flash' do
        expect(flash[:error]).to eq "Unable to mark \"#{@record.title}\" as reviewed."
      end
    end

    describe "reviews a record - when it's not a reviewable record :" do
      before do
        @record = create(:tufts_template)
        put :review, id: @record
      end
      after { @record.delete }

      it 'does not mark the record as reviewed' do
        expect(flash[:error]).to eq "Unable to mark \"#{@record.title}\" as reviewed."
      end
    end

    context "who goes to the new page" do
      routes { HydraEditor::Engine.routes }

      it "is successful" do
        get :new
        expect(response).to be_successful
        expect(response).to render_template(:choose_type)
      end

      it "is successful without a pid" do
        get :new, type: 'TuftsAudio', title: 'An audiophile', displays: 'dl', pid: ''
        expect(assigns[:record]).to be_kind_of TuftsAudio
        expect(assigns[:record]).to be_persisted
        expect(assigns[:record].title).to eq 'An audiophile'
        expect(assigns[:record].displays).to eq ['dl']
        expect(response).to redirect_to Tufts::Application.routes.url_helpers.record_attachments_path(assigns[:record])
      end

      context 'with type TuftsTemplate' do
        it 'creates a new template' do
          get :new, type: 'TuftsTemplate', title: 'A template', displays: 'dl'
          expect(assigns[:record]).to be_kind_of TuftsTemplate
          expect(response).to redirect_to HydraEditor::Engine.routes.url_helpers.edit_record_path(assigns[:record])
        end
      end

      context "with a pid" do
        let(:pid) { 'tufts:123.1231' }
        let(:draft_pid) { 'draft:123.1231' }

        before do
          begin
            a = TuftsAudio.find(pid)
            a.destroy
          rescue ActiveFedora::ObjectNotFoundError
          end
        end

        it "assigns a draft pid" do
          get :new, type: 'TuftsAudio', pid: pid, title: 'An audiophile', displays: 'perseus'
          expect(assigns[:record]).to be_kind_of TuftsAudio
          expect(assigns[:record]).to be_persisted
          expect(response).to redirect_to Tufts::Application.routes.url_helpers.record_attachments_path(assigns[:record])
          expect(assigns[:record].pid).to eq draft_pid
        end
      end

      context "with the pid of an existing object" do
        let(:record) { TuftsAudio.create(title: "existing", displays: ['dl']) }
        it "redirects to the edit page and give a warning" do
          get :new, :type=>'TuftsAudio', :pid=>record.id
          expect(response).to redirect_to HydraEditor::Engine.routes.url_helpers.edit_record_path(record.id)
          expect(flash[:alert]).to eq "A record with the pid \"#{record.id}\" already exists."
        end
      end

      it "has an error with an invalid pid" do
        get :new, :type=>'TuftsAudio', :pid => 'demo:FLORA:01.01'
        expect(response).to be_successful
        expect(response).to render_template(:choose_type)
        expect(flash[:error]).to eq "You have specified an invalid pid. Pids must be in this format: tufts:1231"
      end
    end

    describe "creating a new record" do
      routes { HydraEditor::Engine.routes }

      it "is successful" do
        post :create, :type=>'TuftsAudio', :tufts_audio=>{:title=>"My title", displays: ['dl']}
        expect(response).to redirect_to("/catalog/#{assigns[:record].pid}")
        expect(assigns[:record].title).to eq 'My title'
      end
    end

    describe "editing a record" do
      routes { HydraEditor::Engine.routes }

      let(:draft) do
        TuftsAudio.build_draft_version(title: 'My title2', displays: ['dl']).tap do |d|
          d.edit_users = [@user.email]
          d.save!
        end
      end

      before { PublishService.new(draft).run }

      let(:audio) { draft.find_published }

      context 'when editing the draft version' do
        it "is successful" do
          get :edit, id: draft
          expect(response).to be_successful
          expect(response).to render_template(:edit)
          expect(assigns[:record]).to eq draft
        end
      end

      context 'when editing the non-draft version' do
        it 'redirects to edit form for draft version' do
          get :edit, id: audio
          expect(response).to redirect_to(HydraEditor::Engine.routes.url_helpers.edit_record_path(draft))
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
        it "removes the record" do
          expect { delete :cancel, id: @audio}.to change{TuftsAudio.count}.by(-1)
        end
      end

      describe "on an object with an existing version of DCA-META" do
        before do
          @audio = TuftsAudio.new(title: "My title2", displays: ['dl'])
          @audio.edit_users = [@user.email]
          @audio.save!
        end
        it "doesn't remove the record" do
          expect { delete :cancel, id: @audio }.to_not change { TuftsAudio.count }
        end
      end

      describe "for a template" do
        let(:template) { TuftsTemplate.create!(template_name: 'My Template', title:'Populate DCA-META') }
        after do
          template.destroy
        end
        it "redirects back to the template index" do
         delete :cancel, id: template
         expect(response).to redirect_to(Tufts::Application.routes.url_helpers.templates_path)
        end
      end

      it "doesn't remove the record if there are no existing versions of the dca-META"
    end

    describe "updating a record" do
      routes { HydraEditor::Engine.routes }

      describe "for a template" do
        let(:template) { TuftsTemplate.create!(template_name: 'My Template') }
        after do
          template.destroy
        end
        it "redirects back to the template index" do
          put :update, id: template, tufts_template: {template_name: "My Updated Template"}
          expect(response).to redirect_to(Tufts::Application.routes.url_helpers.templates_path)
          expect(template.reload.template_name).to eq "My Updated Template"
        end
      end

      describe "with an audio" do
        let(:draft) do
          TuftsAudio.build_draft_version(title: 'My title2', displays: ['dl']).tap do |d|
            d.edit_users = [@user.email]
            d.save!
          end
        end

        before { PublishService.new(draft).run }

        let(:audio) { draft.find_published }

        it "successfully updates draft version of object" do
          put :update, id: audio, tufts_audio: { title: "My title 3" }
          expect(response).to redirect_to("/catalog/#{assigns[:record].pid}")
          expect(assigns[:record]).to eq draft
          expect(assigns[:record].title).to eq 'My title 3'
        end

        it "should update external datastream paths" do
          put :update, id: audio, :tufts_audio=>{:datastreams=>{"ACCESS_MP3"=>"http://example.com/access.mp3", "ARCHIVAL_WAV"=>"http://example.com/archival.wav"} }
          expect(response).to redirect_to("/catalog/#{assigns[:record].pid}")
          expect(assigns[:record].datastreams['ACCESS_MP3'].dsLocation).to eq 'http://example.com/access.mp3'
          expect(assigns[:record].datastreams['ARCHIVAL_WAV'].dsLocation).to eq 'http://example.com/archival.wav'
        end

        it 'should update the collection id' do
          put :update, id: audio, :tufts_audio=>{:stored_collection_id=>["updated_id"]}
          expect(assigns[:record].stored_collection_id).to eq 'updated_id'
        end

        it "removes blanks and duplicates" do
          put :update, id: audio, tufts_audio: { displays: ["dl", "", "trove", "dl"] }
          expect(assigns[:record].displays).to eq ["dl", "trove"]
        end
      end

      describe "with an image" do
        let(:draft) do
          TuftsImage.build_draft_version(title: 'test image', displays: ['dl']).tap do |d|
            d.edit_users = [@user.email]
            d.save!
          end
        end

        before { PublishService.new(draft).run }

        let(:image) { draft.find_published }

        it "should update external datastream paths" do
          put :update, id: image, tufts_image: { datastreams: {
            "Advanced.jpg"=>"http://example.com/advanced.jpg",
            "Basic.jpg"=>"http://example.com/basic.jpg",
            "Archival.tif"=>"http://example.com/archival.tif",
            "Thumbnail.png"=>"http://example.com/thumb.png" } }

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

      it "should be successful" do
        expect_any_instance_of(PublishService).to receive(:run).once

        post :publish, id: @audio

        expect(response).to redirect_to("/catalog/#{assigns[:record].pid}")
        expect(flash[:notice]).to eq '"My title2" has been published'
      end
    end

    describe "unpublish a record" do
      let(:audio) do
        TuftsAudio.build_draft_version(title: 'My title2', displays: ['dl']).tap do |audio|
          audio.edit_users = [@user.email]
          audio.save!
        end
      end

      before { PublishService.new(audio).run }

      it "should be successful" do
        expect_any_instance_of(UnpublishService).to receive(:run).once

        post :unpublish, id: audio
        expect(response).to redirect_to catalog_path(audio)
        expect(flash[:notice]).to eq '"My title2" has been unpublished'
      end
    end

    describe "reverting a record" do
      context "when the record has not been published" do
        let(:draft) do
          TuftsAudio.build_draft_version(title: 'My title2', displays: ['dl']).tap do |d|
            d.edit_users = [@user.email]
            d.save!
          end
        end

        it "should be successful with a pid" do
          expect(draft).to_not be_published

          expect_any_instance_of(RevertService).to receive(:run).once

          post :revert, id: draft
          expect(response).to redirect_to(catalog_path(draft))
        end

      end

      context "when the record is published" do
        let(:draft) do
          TuftsAudio.build_draft_version(title: 'My title2', displays: ['dl']).tap do |d|
            d.edit_users = [@user.email]
            d.save!
          end
        end

        before { PublishService.new(draft).run }

        let(:audio) { draft.find_published }


        it "should be successful" do
          expect_any_instance_of(RevertService).to receive(:run).once

          post :revert, id: audio
          expect(response).to redirect_to(catalog_path(draft))
        end
      end
    end

    describe "destroying a record" do
      let(:audio) do
        TuftsAudio.build_draft_version(title: 'My title2', displays: ['dl']).tap do |a|
          a.edit_users = [@user.email]
          a.save!
        end
      end

      before { PublishService.new(audio).run }

      it "should be successful with a pid" do
        expect_any_instance_of(PurgeService).to receive(:run).once

        delete :destroy, id: audio

        expect(response).to redirect_to(Tufts::Application.routes.url_helpers.root_path)
        expect(flash[:notice]).to eq '"My title2" has been purged'
      end
    end
  end

  describe "a non-admin" do
    before do
      sign_in create(:user)
    end

    describe "who goes to the new page" do
      routes { HydraEditor::Engine.routes }

      it "should not be allowed" do
        get :new
        expect(response).to be_redirect
        expect(response).to redirect_to Tufts::Application.routes.url_helpers.root_path
        expect(flash[:alert]).to match /You are not authorized to access this page/i
      end
    end

    describe "who goes to the edit page" do
      routes { HydraEditor::Engine.routes }
      let(:audio) { TuftsAudio.create!(title: 'My title2', displays: ['dl']) }

      it "should not be allowed" do
        get :edit, id: audio
        expect(response).to redirect_to Tufts::Application.routes.url_helpers.contributions_path
        expect(flash[:alert]).to match /You do not have sufficient privileges to edit this document/i
      end
    end

    describe 'reviews a record' do
      let(:record) { create(:tufts_pdf) }

      it 'is not allowed' do
        put :review, id: record
        expect(response).to redirect_to Tufts::Application.routes.url_helpers.root_path
        expect(flash[:alert]).to match /You are not authorized to access this page/i
      end
    end
  end

end
