require 'spec_helper'

describe Job::CreateDerivatives do

  it 'uses the "derivatives" queue' do
    Job::CreateDerivatives.queue.should == :derivatives
  end


  describe '::create' do
    it 'requires the record id' do
      expect{Job::CreateDerivatives.create({})}.to raise_exception(ArgumentError)
    end
  end


  describe '#perform' do
    it 'raises an error if it fails to find the object' do
      obj_id = 'tufts:1'
      TuftsPdf.find(obj_id).destroy if TuftsPdf.exists?(obj_id)

      job = Job::CreateDerivatives.new('uuid', 'record_id' => obj_id)
      expect{job.perform}.to raise_error(ActiveFedora::ObjectNotFoundError)
    end

    it 'raises an error if it the archival PDF doesn''t exist' do
      object = TuftsPdf.new(title: 'test create derivative', displays: ['dl'])
      object.inner_object.pid = 'tufts:MISS.ISS.IPPI'
      object.datastreams["Archival.pdf"].dsLocation = "http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MISS/archival_pdf/MISS.ISS.IPPI.archival.pdf"  # a PDF with 3 pages
      object.datastreams["Archival.pdf"].mimeType = "application/pdf"
      object.save!

      job = Job::CreateDerivatives.new('uuid', 'record_id' => object.id)

      pdf_path = object.local_path_for('Archival.pdf')
      hidden_pdf_path = pdf_path + '.hide'
      FileUtils.mv(pdf_path, hidden_pdf_path)
      expect{job.perform}.to raise_error(Magick::ImageMagickError)
      FileUtils.mv(hidden_pdf_path, pdf_path)
    end

    it 'raises an error if it doesn''t have write permission to the derivatives folder' do
      object = TuftsPdf.new(title: 'test create derivative', displays: ['dl'])
      object.inner_object.pid = 'tufts:MISS.ISS.IPPI'
      object.datastreams["Archival.pdf"].dsLocation = "http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MISS/archival_pdf/MISS.ISS.IPPI.archival.pdf"  # a PDF with 3 pages
      object.datastreams["Archival.pdf"].mimeType = "application/pdf"
      object.save!

      job = Job::CreateDerivatives.new('uuid', 'record_id' => object.id)

			derivatives_path = object.local_path_for_pdf_derivatives()
      FileUtils.mkdir_p(derivatives_path)  # in case the derivatives folder doesn't already exist
      FileUtils.chmod(0444, derivatives_path)
      expect{job.perform}.to raise_error(Errno::EACCES)
      FileUtils.chmod(0755, derivatives_path)
    end

    it 'creates derivatives' do
      object = TuftsPdf.new(title: 'test create derivative', displays: ['dl'])
      object.inner_object.pid = 'tufts:MISS.ISS.IPPI'
      object.datastreams["Archival.pdf"].dsLocation = "http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MISS/archival_pdf/MISS.ISS.IPPI.archival.pdf"  # a PDF with 3 pages
      object.datastreams["Archival.pdf"].mimeType = "application/pdf"
      object.save!

      job = Job::CreateDerivatives.new('uuid', 'record_id' => object.id)

      # remove previously generated derivatives, if any
      FileUtils.remove_dir(object.local_path_for_pdf_derivatives(), true)

      job.perform

      expect(File.exists?(object.local_path_for_book_meta())).to be_truthy
      expect(File.exists?(object.local_path_for_readme())).to be_truthy
      expect(File.exists?(object.local_path_for_png(0))).to be_truthy
    end

    it 'puts derivatives in the right places' do
      object = TuftsPdf.new(title: 'test create derivative', displays: ['dl'])
      object.inner_object.pid = 'tufts:MISS.ISS.IPPI'
      object.datastreams["Archival.pdf"].dsLocation = "http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MISS/archival_pdf/MISS.ISS.IPPI.archival.pdf"  # a PDF with 3 pages
      object.datastreams["Archival.pdf"].mimeType = "application/pdf"
      object.save!

      object.datastreams["Archival.pdf"].dsLocation = "http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MS083/archival_pdf/MS083.001.001.00013.archival.pdf"
      expect(object.local_path_for_pdf_derivatives()).to end_with "/dcadata02/tufts/central/dca/MS083/access_pdf_pageimages/MS083.001.001.00013"

      object.datastreams["Archival.pdf"].dsLocation = "http://bucket01.lib.tufts.edu/data01/tufts/facpubs/mpokras-2007/archival_pdf/nriagu-1983.00001.archival.pdf"
      expect(object.local_path_for_pdf_derivatives()).to end_with "/dcadata02/tufts/facpubs/mpokras-2007/access_pdf_pageimages/facpubs.nriagu-1983.00001"

      object.datastreams["Archival.pdf"].dsLocation = "http://bucket01.lib.tufts.edu/data05/tufts/central/dca/MS001/archival_pdf/MS001.008.001.00002.archival.pdf"
      expect(object.local_path_for_pdf_derivatives()).to end_with "/dcadata02/tufts/central/dca/MS001/access_pdf_pageimages/MS001.008.001.00002"

      object.datastreams["Archival.pdf"].dsLocation = "http://bucket01.lib.tufts.edu/ase_data/tisch01/archival_pdf/12385.archival.pdf"
      expect(object.local_path_for_pdf_derivatives()).to end_with "/ase_data/tisch01/access_pdf_pageimages/12385"
    end
  end

end
