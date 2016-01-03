require 'airfoils/airfoil_checker'

class LoadOrigData < ActiveRecord::Migration
  DIR_PATH_FIXED = Rails.root.join('data', 'uiuc_airfoils.fixed')
  def up

    Dir.foreach(DIR_PATH_FIXED).with_index do |item, i|
      next if item == '.' || item == '..'
      print '.'
      afc = AirfoilChecker::Checker.new('')
      afc.read_file(DIR_PATH_FIXED, item)
      unless afc.check
        puts "\nUncorrectable error #{item}"
        next
      end

      Airfoil.create(data_raw: afc.raw,
                     file_name: item,
                     name: afc.name,
                     thickness: afc.thickness,
                     top: afc.top_as_str,
                     bottom: afc.bottom_as_str,
                     data_errors: afc.errors.map(&:message).join("\n"))
    end

  end

  def down
    Airfoil.destroy_all
  end

end

