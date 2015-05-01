require 'factory_girl'

FactoryGirl.define do

  factory :batch_xml_import do
    type 'BatchXmlImport'
    association :creator, factory: :admin
    metadata_file { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'MIRABatchUpload_valid.xml')) }
  end
end
