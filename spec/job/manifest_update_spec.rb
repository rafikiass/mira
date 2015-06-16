require 'spec_helper'

describe Job::ManifestUpdate do
  let(:pid) { 'tufts:123' }
  let(:job) { described_class.new('uuid', 'pid' => pid, 'link' => 'http://bucket.tufts.edu/foo/bar/hello.pdf', 'mime_type' => 'application/pdf', 'filename' => 'hello.pdf') }
  let(:record) { TuftsGenericObject.new }
  let(:datastream) { record.datastreams['GENERIC-CONTENT'] }

  before do
    allow(TuftsGenericObject).to receive(:find).with(pid).and_return(record)
  end

  context "when there is no manifest" do
    it 'creates the manifest' do
      expect(datastream).to receive(:save)
      job.perform
      expect(datastream.item.link).to eq ['http://bucket.tufts.edu/foo/bar/hello.pdf']
      expect(datastream.item.mimeType).to eq ['application/pdf']
      expect(datastream.item.fileName).to eq ['hello.pdf']
    end
  end

  context "when a manifest exists" do
    before do
      datastream.item.link = ['foo']
      datastream.item.mimeType = ['bar']
      datastream.item.fileName = ['baz']
    end

    it 'appends items' do
      expect(datastream).to receive(:save)
      job.perform
      expect(datastream.item.link).to eq ["foo", "http://bucket.tufts.edu/foo/bar/hello.pdf"]
      expect(datastream.item.mimeType).to eq ['bar', 'application/pdf']
      expect(datastream.item.fileName).to eq ['baz', 'hello.pdf']
    end
  end
end

