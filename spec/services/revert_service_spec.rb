require 'spec_helper'

describe RevertService do
  describe '#run' do
    let!(:draft) do
      obj = TuftsImage.build_draft_version(title: 'My title', displays: ['dl'])
      obj.save!
      obj
    end

    subject { draft }

    let(:user) { FactoryGirl.create(:user) }
    let(:draft_pid) { PidUtils.to_draft(subject.pid) }
    let(:published_pid) { PidUtils.to_published(subject.pid) }

    context "when the draft and published version exists" do
      let!(:published) do
        PublishService.new(subject).run
        subject.find_published
      end

      before do
        draft.title = 'new title'
        draft.save!
      end

      it "reverts the draft to the published version" do
        RevertService.new(subject).run
        expect(subject.reload.title).to eq("My title")
      end

      it "ensures the solr index is updated afterwards" do
        expect(subject).to receive(:update_index).once { true }
        RevertService.new(subject).run
      end

      context 'when you pass it the published object' do

        it 'updates the solr index of the draft object' do
          doc = ActiveFedora::SolrService.query("id:\"#{draft_pid}\"").first
          expect(doc['title_tesim']).to eq ['new title']

          RevertService.new(published).run
          doc = ActiveFedora::SolrService.query("id:\"#{draft_pid}\"").first
          expect(doc['title_tesim']).to eq ['My title']
        end
      end
    end
  end
end
