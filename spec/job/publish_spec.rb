require 'spec_helper'

describe Job::Publish do
  let(:record) { FactoryGirl.create(:tufts_pdf) }
  let(:user) { FactoryGirl.create(:user) }
  let(:batch) { FactoryGirl.create(:batch_publish, creator: user, pids: pid_list) }
  let(:pid_list) { [record.pid] }

  it 'uses the "publish" queue' do
    expect(Job::Publish.queue).to eq :publish
  end

  describe '::create' do
    let(:opts) do
      {record_id: '1',
        user_id: '1',
        batch_id: '1'}
    end

    it 'requires the user id' do
      opts.delete(:user_id)
      expect{Job::Publish.create(opts)}.to raise_exception(ArgumentError, /user_id/)
    end

    it 'requires the record id' do
      opts.delete(:record_id)
      expect{Job::Publish.create(opts)}.to raise_exception(ArgumentError, /record_id/)
    end

    it 'requires the batch id' do
      opts.delete(:batch_id)
      expect{Job::Publish.create(opts)}.to raise_exception(ArgumentError, /batch_id/)
    end
  end

  describe '#perform' do
    context 'when it fails to find the object' do
      let(:obj_id) { 'tufts:1' }
      let(:pid_list) { [obj_id] }

      before do
        TuftsPdf.find(obj_id).destroy if TuftsPdf.exists?(obj_id)
      end

      it 'raises an error' do
        job = Job::Publish.new('uuid', 'user_id' => user.id, 'record_id' => obj_id, 'batch_id' => batch.id)
        expect{job.perform}.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end

    it 'publishes the record' do
      expect(ActiveFedora::Base).to receive(:find).with(record.id, cast: true).and_return(record)
      job = Job::Publish.new('uuid', 'user_id' => user.id, 'record_id' => record.id, 'batch_id' => batch.id)
      expect_any_instance_of(PublishService).to receive(:run).once
      job.perform
      record.delete
    end

    it 'can be killed' do
      job = Job::Publish.new('uuid', 'user_id' => user.id, 'record_id' => record.id)
      allow(job).to receive(:tick).and_raise(Resque::Plugins::Status::Killed)
      expect{job.perform}.to raise_exception(Resque::Plugins::Status::Killed)
    end

    it 'runs the job as a batch item' do
      pdf = FactoryGirl.create(:tufts_pdf)
      job = Job::Publish.new('uuid', 'record_id' => pdf.id, 'user_id' => user.id, 'batch_id' => batch.id)

      job.perform
      pdf.reload
      expect(pdf.batch_id).to eq [batch.id.to_s]

      pdf.delete
    end

  end
end
