class CreateAirfoils < ActiveRecord::Migration
  def change
    create_table :airfoils do |t|
      t.string  :name
      t.text    :data_raw
      t.text    :file_name
      t.float   :thickness
      t.text    :top
      t.text    :bottom
      t.text    :comment
      t.integer :foil_type
      t.text    :data_fixes
      t.text    :data_errors

      t.timestamps null: false
    end
  end
end
