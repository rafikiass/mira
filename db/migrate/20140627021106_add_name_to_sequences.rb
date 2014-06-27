class AddNameToSequences < ActiveRecord::Migration
  def change
    change_table(:sequences) do |t|
      t.column :name, :string
    end
  end
end
