class ConvertMetadataFileToText < ActiveRecord::Migration
  def change
    change_column :batches, :metadata_file, :text, limit: nil
  end
end
