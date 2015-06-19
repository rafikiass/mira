require 'spec_helper'


describe DownloadsController do
  describe "when not signed in" do
    let(:pdf) { create(:tufts_pdf) }
    it "should require sign-in" do
      get :show, id: pdf, datastream_id: "Archival.pdf"
      expect(response).to redirect_to new_user_session_path
    end
  end

  describe "when signed in" do
    before do
      sign_in FactoryGirl.create(:admin)
    end

    describe "downloading a pdf" do
      before do
        @pdf = TuftsPdf.new(title: 'test download', displays: ['dl'])
        @pdf.inner_object.pid = 'tufts:MISS.ISS.IPPI'
        @pdf.datastreams["Archival.pdf"].dsLocation = "http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MISS/archival_pdf/MISS.ISS.IPPI.archival.pdf"
        @pdf.datastreams["Archival.pdf"].mimeType = "application/pdf"

        @pdf.datastreams["Transfer.binary"].dsLocation = "http://bucket01.lib.tufts.edu/data01/tufts/central/dca/MISS/archival_pdf/MISS.ISS.IPPI.archival.pdf"
        @pdf.datastreams["Transfer.binary"].mimeType = "application/pdf"
        @pdf.datastreams["Transfer.binary"].dsLabel = "foo.pdf"

        @pdf.save!
      end

      context "downloading the archival PDF datastream" do
        it "has the filename of the local asset" do
          get :show, id: @pdf.pid, datastream_id: "Archival.pdf"

          expect(response.headers['Content-Disposition']).to eq("inline; filename=\"MISS.ISS.IPPI.archival.pdf\"")
          expect(response.headers['Content-Type']).to eq("application/pdf")
        end
      end

      context "downloading the transfer.binary datastream" do
        it "has the filename from the dsLabel" do
          get :show, id: @pdf.pid, datastream_id: "Transfer.binary"

          expect(response.headers['Content-Disposition']).to eq("inline; filename=\"foo.pdf\"")
          expect(response.headers['Content-Type']).to eq("application/pdf")
        end
      end
    end


    context "for a generic file" do
      let(:generic_object) { TuftsGenericObject.new(pid: 'tufts:99', displays: ['dl'], title: 'test 1') }
      let(:xml) {
        '<content xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.fedora.info/definitions/">
                        <item id="0">
                           <link>http://bucket01.lib.tufts.edu/data05/tufts/central/dca/MS115/generic/MS115.003.001.00001.zip</link>
                           <fileName>MS115.003.001.00001</fileName>
                           <mimeType>application/zip</mimeType>
                        </item>
                    </content>' }
      before do
        generic_object.datastreams['GENERIC-CONTENT'].content = xml
        generic_object.save!
      end

      it "has a filename" do
        expect(controller).to receive(:send_file).with(fixture_path + "/local_object_store/data05/tufts/central/dca/MS115/generic/MS115.003.001.00001.zip") { controller.render nothing: true }
        get :show, id: generic_object, offset: "0"
      end
    end
  end
end
