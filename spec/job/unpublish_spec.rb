require 'spec_helper'

describe Job::Unpublish do
  let(:record) { FactoryGirl.create(:tufts_pdf) }
  let(:user) { FactoryGirl.create(:user) }
  let(:batch) { FactoryGirl.create(:batch_unpublish, creator: user, pids: pid_list) }
  let(:pid_list) { [record.pid] }

  it 'uses the "unpublish" queue' do
    expect(Job::Unpublish.queue).to eq :unpublish
  end

  describe '::create' do
    let(:opts) do
      { record_id: '1',
        user_id: '1',
        batch_id: '1' }
    end

    it 'requires the user id' do
      opts.delete(:user_id)
      expect{Job::Unpublish.create(opts)}.to raise_exception(ArgumentError, /user_id/)
    end

    it 'requires the record id' do
      opts.delete(:record_id)
      expect{Job::Unpublish.create(opts)}.to raise_exception(ArgumentError, /record_id/)
    end

    it 'requires the batch id' do
      opts.delete(:batch_id)
      expect{Job::Unpublish.create(opts)}.to raise_exception(ArgumentError, /batch_id/)
    end
  end

  describe '#perform' do
    let(:user) { FactoryGirl.create(:user) }

    it 'raises an error if it fails to find the object' do
      obj_id = 'tufts:1'
      TuftsPdf.find(obj_id).destroy if TuftsPdf.exists?(obj_id)

      job = Job::Unpublish.new('uuid', 'user_id' => 1, 'record_id' => obj_id, 'batch_id' => batch.id)
      expect{job.perform}.to raise_error(ActiveFedora::ObjectNotFoundError)
    end

    it 'unpublishes the record' do
      record = TuftsPdf.build_draft_version(FactoryGirl.attributes_for(:tufts_pdf))
      record.save!

      expect(ActiveFedora::Base).to receive(:find).with(record.id, cast: true).and_return(record)
      job = Job::Unpublish.new('uuid', 'user_id' => user.id, 'record_id' => record.id, 'batch_id' => batch.id)
      expect_any_instance_of(UnpublishService).to receive(:run).once
      job.perform
      record.delete
    end

    it 'can be killed' do
      job = Job::Unpublish.new('uuid', 'user_id' => 1, 'record_id' => record.id)
      allow(job).to receive(:tick).and_raise(Resque::Plugins::Status::Killed)
      expect{job.perform}.to raise_exception(Resque::Plugins::Status::Killed)
    end

    it 'runs the job as a batch item' do
      pdf = TuftsPdf.build_draft_version(FactoryGirl.attributes_for(:tufts_pdf))
      pdf.save!

      job = Job::Unpublish.new('uuid', 'record_id' => pdf.id, 'user_id' => user.id, 'batch_id' => batch.id)

      job.perform
      pdf.reload
      expect(pdf.batch_id).to eq [batch.id.to_s]

      pdf.delete
    end
  end

end
