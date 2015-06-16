module Job
  class ManifestUpdate
    include Resque::Plugins::Status

    def self.queue
      :manifest
    end

    def self.create(options)
      required = [:pid, :link, :mime_type, :filename]

      required.each do |r|
        raise ArgumentError.new("Required keys: #{r}") unless options[r]
      end

      super
    end

    def perform
      tick # give resque-status a chance to kill this
      object = TuftsGenericObject.find(options.fetch('pid'))
      ds = object.datastreams['GENERIC-CONTENT']
      new_item = build_item(ds)
      new_item.link = options.fetch('link')
      new_item.mimeType = options.fetch('mime_type')
      new_item.fileName = options.fetch('filename')

      ds.save
    end

    def build_item(ds)
      # Find the index of the first non-blank node.
      index = ds.ng_xml.xpath('//oxns:item/oxns:link/text()', "oxns"=>"http://www.fedora.info/definitions/").count
      ds.item(index)
    end

  end
end

