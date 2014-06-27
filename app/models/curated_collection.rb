class CuratedCollection < ActiveFedora::Base
  include Hydra::ModelMethods
  include Hydra::AccessControls::Permissions
  include WithValidDisplays

  validates :title, presence: true
  after_initialize :default_attributes

  has_metadata "DCA-META", type: TuftsDcaMeta
  has_metadata 'collectionMetadata', type: CollectionMetadata
  has_metadata "DCA-ADMIN", type: DcaAdmin

  has_attributes :creator, :description, :date_created, :type,
    datastream: 'DCA-META', multiple: true
  has_attributes :title, datastream: 'DCA-META', multiple: false
  has_attributes :displays, :note, datastream: 'DCA-ADMIN', multiple: true
  has_attributes :managementType, :createdby, datastream: 'DCA-ADMIN', multiple: false

  validates :managementType, presence: true

  delegate :members, :member_ids, to: :collectionMetadata

  def initialize(attributes = {})
    attributes = {
      displays: ['tdil'],
      note: ["created on using the Tufts Digital Image Library"],
      createdby: ["tdil"],
      date_created: [Date.today.to_s],
      type: ["collection"],
    }.merge(attributes)
    super(attributes)
  end

  private
    def default_attributes
      self.displays = ['tdil'] if displays.empty?
    end
end
