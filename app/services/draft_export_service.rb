require 'builder'

class DraftExportService
  def initialize(options = {})
    @record_ids = Array(options.fetch(:record_ids)).map { |p| PidUtils.to_draft(p) }
    @datastream_ids = Array(options.fetch(:datastream_ids))

    @batch_id = options.fetch(:batch_id)

    @export_directory = options[:export_directory] || File.join(Settings.object_store_root, "export")
    @output = ""
  end

  attr_reader :record_ids, :datastream_ids, :batch_id, :export_directory, :output

  def run
    generate_xml
    write_output_to_file
  end

  def full_export_file_path
    Rails.root.join export_directory, export_filename
  end

  private
  def generate_xml
    xml = Builder::XmlMarkup.new(target: output)

    xml.instruct!

    xml.items do
      existing_record_ids = record_ids.select { |r| ActiveFedora::Base.exists?(r) }

      ActiveFedora::Base.find(existing_record_ids).each do |object|
        xml.digitalObject do
          xml.pid object.pid

          datastream_ids.each do |datastream|
            if ds = object.datastreams[datastream]
              xml.dataStream(id: datastream) do
                xml << ds.read.to_s
              end
            end
          end
        end
      end
    end # xml.export
  end # generate_xml

  def write_output_to_file
    ensure_export_directory_exists

    Rails.logger.debug "Exporting to #{full_export_file_path}"

    File.open(full_export_file_path, "wb") do |f|
      f.write output
    end
  end

  def ensure_export_directory_exists
    FileUtils.mkdir_p export_directory
  end

  def export_filename
    @export_filename ||= "#{current_timestamp}.xml"
  end

  def current_timestamp
    Time.now.strftime("%Y-%m-%d-%H%M%S.%6N")
  end

end
