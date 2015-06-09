require 'spec_helper'

describe PurgeService do
  describe '#run' do
    before do
      ActiveFedora::Base.find(draft_pid).delete if ActiveFedora::Base.exists?(draft_pid)
      ActiveFedora::Base.find(published_pid).delete if ActiveFedora::Base.exists?(published_pid)
    end

    let(:draft) { TuftsImage.new(pid: draft_pid, title: 'My title', displays: ['dl']) }

    let(:user) { create(:user) }
    let(:draft_pid) { 'draft:123' }
    let(:published_pid) { 'tufts:123' }

    context "when only the published version exists" do
      # not a very likely scenario
      before do
        draft.save!
        PublishService.new(draft).run
        draft.destroy
      end

      it "hard-deletes the published version" do
        expect(AuditLogService).to receive(:log).with(user.user_key, draft.id, "Purged published version | []")
        expect(AuditLogService).not_to receive(:log).with(user.user_key, draft.id, "Purged draft version | []")
        expect {
          PurgeService.new(draft, user).run
        }.to change { TuftsImage.exists?(published_pid) }.from(true).to(false)
      end
    end

    context "when only the draft version exists" do
      before do
        draft.save!
      end

      it "hard-deletes the draft version" do
        expect(AuditLogService).not_to receive(:log).with(user.user_key, draft.id, "Purged published version | []")
        expect(AuditLogService).to receive(:log).with(user.user_key, draft.id, "Purged draft version | []")

        expect {
          PurgeService.new(draft, user).run
        }.to change { TuftsImage.exists?(draft_pid) }.from(true).to(false)
      end
    end

    context "when both versions exist and files are attached" do
      before do
        draft.datastreams['Archival.tif'].dsLocation = 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MISS/archival_pdf/123.tif'
        draft.datastreams['Thumbnail.png'].dsLocation = 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MISS/archival_pdf/123.png'
        draft.save!
        PublishService.new(draft).run
        allow(LocalPathService).to receive(:new).and_return(path_service)
        allow(path_service).to receive(:local_path).and_return('foo.png', 'bar.tif')
      end

      let(:path_service) { double }


      it "hard-deletes both versions" do
        expect(AuditLogService).to receive(:log).with(user.user_key, draft.id, "Purged published version | [\"foo.png\", \"bar.tif\"]")
        expect(AuditLogService).to receive(:log).with(user.user_key, draft.id, "Purged draft version | [\"foo.png\", \"bar.tif\"]")

        expect {
          PurgeService.new(draft, user).run
        }.to change { TuftsImage.exists?(draft_pid) }.from(true).to(false).
        and change { TuftsImage.exists?(published_pid) }.from(true).to(false)
      end

    end
  end
end

