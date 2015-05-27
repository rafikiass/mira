require 'spec_helper'

describe Job::Revert do
  let(:user) { FactoryGirl.create(:user) }
  let(:batch) { FactoryGirl.create(:batch_revert, creator: user, pids: pid_list) }
  let(:pid_list) { [record.pid] }

  it 'uses the "revert" queue' do
    expect(Job::Revert.queue).to eq :revert
  end

  describe '::create' do
    let(:opts) do
      {record_id: '1',
        user_id: '1',
        batch_id: '1'}
    end

    it 'requires the user id' do
      opts.delete(:user_id)
      expect{Job::Revert.create(opts)}.to raise_exception(ArgumentError, /user_id/)
    end

    it 'requires the record id' do
      opts.delete(:record_id)
      expect{Job::Revert.create(opts)}.to raise_exception(ArgumentError, /record_id/)
    end

    it 'requires the batch id' do
      opts.delete(:batch_id)
      expect{Job::Revert.create(opts)}.to raise_exception(ArgumentError, /batch_id/)
    end
  end

  describe '#perform' do

    context 'both draft and published versions of the record exist' do
      let!(:record) {
        r = TuftsPdf.build_draft_version(displays: ['dl'], title: "orig title")
        r.save!
        PublishService.new(r).run
        r
      }

      let!(:published_record) {
        TuftsPdf.find(PidUtils.to_published(record.pid))
      }

      it 'runs the job as a batch item' do
        job = Job::Revert.new('uuid', 'record_id' => record.id, 'user_id' => user.id, 'batch_id' => batch.id)

        job.perform
        record.reload
        expect(record.batch_id).to eq [batch.id.to_s]

        record.delete
      end

      it 'copies the published version back to the draft' do
        # make sure it reverts
        record.title = "changed title"
        record.save!
        Job::Revert.new('uuid', 'record_id' => record.pid, 'batch_id' => batch.id).perform
        expect(record.reload.title).to eq "orig title"
      end

      it 'passes user_id so that the audit will record the user' do
        attrs = { 'record_id' => record.id, 'user_id' => user.id, 'batch_id' => batch.id }
        job = Job::Revert.new(attrs)
        job.instance_variable_set(:@options, attrs)

        expect(RevertService).to receive(:new).with(published_record, user.id) { double(run: nil) }
        job.perform
      end
    end

    context 'draft record exists, missing published record' do
      let(:record) do
        TuftsPdf.build_draft_version(displays: ['dl'], title: "orig title").tap do |r|
          r.save!
        end
      end
      let(:pid) { record.pid }
      let(:published_pid) { PidUtils.to_published(pid) }

      before do
        begin
          TuftsPdf.find(published_pid).destroy
        rescue ActiveFedora::ObjectNotFoundError
        end
      end

      it 'hard deletes' do
        Job::Revert.new('uuid', 'record_id' => pid, 'batch_id' => batch.id).perform
        expect(TuftsPdf).not_to exist(published_pid)
        expect(TuftsPdf).to exist(pid)
      end
    end

    context 'draft record missing, published record exists' do
      let(:record) {
        record = TuftsPdf.build_draft_version(displays: ['dl'], title: "orig title")
        record.save!
        record
      }

      let!(:pid) { record.pid }
      let(:pid_list) { [pid] }

      it 'copies from published' do
        # published record exists
        PublishService.new(record).run

        # missing draft
        record.destroy

        # make sure it reverts
        Job::Revert.new('uuid', 'record_id' => pid, 'batch_id' => batch.id).perform

        draft_pid = PidUtils.to_draft(pid)
        published_pid = PidUtils.to_published(pid)

        expect(TuftsPdf.exists?(published_pid)).to be_truthy
        expect(TuftsPdf.exists?(draft_pid)).to be_truthy
      end
    end

    context 'both draft and published record missing' do
      let(:pid) { 'draft:1' }
      let(:pid_list) { [pid] }

      it 'succeeds and does nothing' do
        # published record missing
        published_pid = PidUtils.to_published(pid)
        TuftsPdf.find(published_pid).destroy if TuftsPdf.exists?(published_pid)

        # draft record missing
        TuftsPdf.find(pid).destroy if TuftsPdf.exists?(pid)

        # make sure it does nothing
        Job::Revert.new('uuid', 'record_id' => pid, 'batch_id' => batch.id).perform
        expect(TuftsPdf.exists?(pid)).to be_falsey
      end
    end

    it 'can be killed' do
      record = FactoryGirl.create(:tufts_pdf)
      job = Job::Revert.new('uuid', 'user_id' => 1, 'record_id' => record.id)
      allow(job).to receive(:tick).and_raise(Resque::Plugins::Status::Killed)
      expect{job.perform}.to raise_exception(Resque::Plugins::Status::Killed)
    end

  end
end
