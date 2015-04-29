require 'spec_helper'

describe BatchTemplateUpdateRunnerService do
  let(:runner) { described_class.new(batch) }
  describe '#create_jobs' do
    let(:batch) { FactoryGirl.build(:batch_template_update, id: 10, pids: ['tufts:1', 'tufts:2', 'tufts:3']) }
    let(:attrs) { { filesize: ['57 MB'] } }

    it 'queues one job for each record' do
      args = { user_id: batch.creator_id, attributes: attrs, batch_id: 10 }
      expect(Job::ApplyTemplate).to receive(:create).with(args.merge(record_id: "draft:1"))
      expect(Job::ApplyTemplate).to receive(:create).with(args.merge(record_id: "draft:2"))
      expect(Job::ApplyTemplate).to receive(:create).with(args.merge(record_id: "draft:3"))

      runner.send(:create_jobs, attrs)
    end

    it "returns a list of job ids" do
      allow(Job::ApplyTemplate).to receive(:create).and_return(:a, :b, :c)

      expect(runner.send(:create_jobs, attrs)).to eq [:a, :b, :c]
    end
  end

  describe '#run' do
    subject { runner.run }

    context "when the batch is not valid" do
      let(:batch) { BatchTemplateUpdate.new }
      it { is_expected.to be false }
    end

    context "with multiple pids" do
      let(:batch) { BatchTemplateUpdate.new(id: '222', pids: ['draft:7', 'tufts:8'], template_id: '999', creator: user) }
      let(:user) { FactoryGirl.create(:user) }
      let(:template) { TuftsTemplate.new(title: title) }
      let(:title) { 'Foo' }
      before { allow(TuftsTemplate).to receive(:find).with('999').and_return(template) }

      it 'queues a job for each pid and saves the job ids' do
        expect(Job::ApplyTemplate).to receive(:create).with(user_id: batch.creator.id, batch_id: batch.id, record_id: 'draft:7', attributes: { title: "Foo" }) { :a }
        expect(Job::ApplyTemplate).to receive(:create).with(user_id: batch.creator.id, batch_id: batch.id, record_id: 'draft:8', attributes: { title: "Foo" }) { :b }
        expect(subject).to be true
        expect(batch.job_ids).to eq [:a, :b]
      end

      context "when there is nothing to update" do
        let(:title) { nil }
        it "doesn't queue any jobs" do
          expect(Job::ApplyTemplate).not_to receive(:create)
          expect(subject).to be false
        end
      end
    end
  end
end
