require 'spec_helper'

describe PurgeService do
  describe '#run' do
    let(:draft) { TuftsImage.build_draft_version(title: 'My title', displays: ['dl']) }

    let(:user) { create(:user) }
    let(:draft_pid) { PidUtils.to_draft(draft.pid) }
    let(:published_pid) { PidUtils.to_published(draft.pid) }

    context "when only the published version exists" do
      # not a very likely scenario
      before do
        draft.save!
        PublishService.new(draft).run
        draft.destroy
      end

      it "hard-deletes the published version" do
        expect(AuditLogService).to receive(:log).with(user.user_key, draft.id, "Purged published version")
        expect(AuditLogService).not_to receive(:log).with(user.user_key, draft.id, "Purged draft version")
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
        expect(AuditLogService).not_to receive(:log).with(user.user_key, draft.id, "Purged published version")
        expect(AuditLogService).to receive(:log).with(user.user_key, draft.id, "Purged draft version")

        expect {
          PurgeService.new(draft, user).run
        }.to change { TuftsImage.exists?(draft_pid) }.from(true).to(false)
      end
    end

    context "when both versions exist" do
      before do
        draft.save!
        PublishService.new(draft).run
      end

      it "hard-deletes both versions" do
        expect(AuditLogService).to receive(:log).with(user.user_key, draft.id, "Purged published version")
        expect(AuditLogService).to receive(:log).with(user.user_key, draft.id, "Purged draft version")

        expect {
          PurgeService.new(draft, user).run
        }.to change { TuftsImage.exists?(draft_pid) }.from(true).to(false).
        and change { TuftsImage.exists?(published_pid) }.from(true).to(false)
      end

    end
  end
end

