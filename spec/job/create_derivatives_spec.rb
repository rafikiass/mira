require 'spec_helper'

describe Job::CreateDerivatives do

  it 'uses the "derivatives" queue' do
    expect(Job::CreateDerivatives.queue).to eq :derivatives
  end

  describe '::create' do
    it 'requires the record id' do
      expect{Job::CreateDerivatives.create({})}.to raise_exception(ArgumentError)
    end
  end

  describe '#perform for video' do

    subject { FactoryGirl.create(:tufts_video) }

    before(:all) do
      TuftsVideo.find('tufts:v1').destroy if TuftsVideo.exists?('tufts:v1')
    end

    before(:each) do
      subject.datastreams["Archival.video"].dsLocation = "file://#{Rails.root}/spec/fixtures/local_object_store/data01/tufts/central/dca/MISS/archival_video/sample.mp4"
      subject.datastreams["Archival.video"].mimeType = "video/mp4"
      subject.save
    end

    it 'creates derivatives' do
      mock_video = double('tufts-video').as_null_object
      expect(mock_video).to receive(:create_derivatives).once { true }

      allow(ActiveFedora::Base).to receive(:find).with(subject.id, cast: true) { mock_video }

      Job::CreateDerivatives.new('uuid', 'record_id' => subject.id).perform
    end

    context "errors" do
      it "raises EACCES when the video's derivative generation raises it" do
        mock_video = double('tufts-video').as_null_object
        expect(mock_video).to receive(:create_derivatives).once.and_raise(Errno::EACCES)

        allow(ActiveFedora::Base).to receive(:find).with(subject.id, cast: true) { mock_video }

        expect { Job::CreateDerivatives.new('uuid', 'record_id' => subject.id).perform }.to raise_error(Errno::EACCES)

      end

      it "raises Errno::ENOENT when the video's derivative generation raises it" do
        mock_video = double('tufts-video').as_null_object
        expect(mock_video).to receive(:create_derivatives).once.and_raise(Errno::ENOENT)

        allow(ActiveFedora::Base).to receive(:find).with(subject.id, cast: true) { mock_video }

        expect { Job::CreateDerivatives.new('uuid', 'record_id' => subject.id).perform }.to raise_error(Errno::ENOENT)

      end
    end

  end

  describe '#perform for pdf' do
    subject { FactoryGirl.create(:tufts_pdf) }

    before(:all) do
      TuftsPdf.find('tufts:1').destroy if TuftsPdf.exists?('tufts:1')
    end

    before(:each) do
      subject.datastreams["Archival.pdf"].dsLocation = "file://#{Rails.root}/spec/fixtures/local_object_store/data01/tufts/central/dca/MISS/archival_pdf/MISS.ISS.IPPI.archival.pdf"  # a PDF with 3 pages
      subject.datastreams["Archival.pdf"].mimeType = "application/pdf"
      subject.save
    end

    it 'raises an error if it fails to find the object' do
      job = Job::CreateDerivatives.new('uuid', 'record_id' => 'tufts:1')
      expect{job.perform}.to raise_error(ActiveFedora::ObjectNotFoundError)
    end

    it 'raises an error if it the archival PDF doesn''t exist' do
      job = Job::CreateDerivatives.new('uuid', 'record_id' => subject.id)
      subject.datastreams['Archival.pdf'].dsLocation = 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MISS/archival_pdf/non-existant.pdf'
      subject.save
      expect{job.perform}.to raise_error(Magick::ImageMagickError)
    end

    it 'raises an error if it doesn''t have write permission to the derivatives folder' do
      job = Job::CreateDerivatives.new('uuid', 'record_id' => subject.id)
      derivatives_path = subject.local_path_for_pdf_derivatives
      FileUtils.mkdir_p(derivatives_path)  # in case the derivatives folder doesn't already exist
      FileUtils.chmod(0444, derivatives_path)

      expect{job.perform}.to raise_error(Errno::EACCES)

      FileUtils.chmod(0755, derivatives_path)
    end

    it 'creates derivatives' do
      job = Job::CreateDerivatives.new('uuid', 'record_id' => subject.id)

      # remove previously generated derivatives, if any
      FileUtils.remove_dir(subject.local_path_for_pdf_derivatives(), true)

      job.perform

      expect(File.exists?(subject.local_path_for_book_meta)).to be_truthy
      expect(File.exists?(subject.local_path_for_readme)).to be_truthy
      expect(File.exists?(subject.local_path_for_png(0))).to be_truthy
    end

    it 'puts derivatives in the right places' do

      subject.datastreams['Archival.pdf'].dsLocation = 'http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MS083/archival_pdf/MS083.001.001.00013.archival.pdf'
      expect(subject.local_path_for_pdf_derivatives).to end_with '/dcadata02/tufts/central/dca/MS083/access_pdf_pageimages/MS083.001.001.00013'

      subject.datastreams['Archival.pdf'].dsLocation = 'http://bucket01.lib.tufts.edu/data01/tufts/facpubs/mpokras-2007/archival_pdf/nriagu-1983.00001.archival.pdf'
      expect(subject.local_path_for_pdf_derivatives).to end_with '/dcadata02/tufts/facpubs/mpokras-2007/access_pdf_pageimages/facpubs.nriagu-1983.00001'

      subject.datastreams['Archival.pdf'].dsLocation = 'http://bucket01.lib.tufts.edu/data05/tufts/central/dca/MS001/archival_pdf/MS001.008.001.00002.archival.pdf'
      expect(subject.local_path_for_pdf_derivatives).to end_with '/dcadata02/tufts/central/dca/MS001/access_pdf_pageimages/MS001.008.001.00002'

      subject.datastreams['Archival.pdf'].dsLocation = 'http://bucket01.lib.tufts.edu/ase_data/tisch01/archival_pdf/12385.archival.pdf'
      expect(subject.local_path_for_pdf_derivatives).to end_with '/ase_data/tisch01/access_pdf_pageimages/12385'
    end
  end

end
