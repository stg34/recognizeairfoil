load 'airfoils/airfoil_checker.rb'

DirPathIn = '~/projects/plane/whatisairfoil/data/uiuc_airfoils.fixed'
DirPathOut = '~/projects/plane/whatisairfoil/data/uiuc_airfoils.fixed.1'
DirPathOutM = '~/projects/plane/whatisairfoil/data/uiuc_airfoils.fixed.unfixed'


begin

  Dir.foreach(DirPathIn) do |item|
    last_item = item
    #tries = 0
    next if item == '.' || item == '..'  #|| item != 'e850.dat'
    #to_fix_manually = false
    #puts item
    afc = AirfoilChecker::Checker.new('')
    afc.read_file(DirPathIn, item)

    if !afc.check
      puts 'Uncorrectable error'
      afc.write_file(DirPathOutM, item)
    elsif afc.errors.any?
      puts 'Fixed'
      #afc.write_file(DirPathOut, item)
    else
      puts 'Ok'
    end


  end
# rescue => e
#   puts last_item
#   puts e.message
end

