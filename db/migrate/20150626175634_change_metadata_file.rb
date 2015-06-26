class ChangeMetadataFile < ActiveRecord::Migration
  def change
    # This migration addresses the issues reported in issues #641 and #651
    # In order to import files larger than 64K, the MySQL table type needs to be set to 'longext' instead of just 'text'
    # see the following for details: http://stackoverflow.com/questions/4443477/rails-3-migration-with-longtext
    change_column :batches, :metadata_file, :text, limit: 4294967295
  end
end
