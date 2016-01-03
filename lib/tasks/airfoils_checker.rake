require 'airfoils/airfoil_checker'

namespace :airfoils_checker do
  desc "Checks airfoils"
  task check: :environment do
    # Airfoil.limit(100).all.each_with_index do |af, i|
    #   puts "%4d #{af.file_name}" % [i]
    #   begin
    #     afc = AirfoilChecker::Checker.new(af.raw)
    #     afc.check_name
    #     afc.check_points_consistency
    #     afc.check_x_range
    #     af.name = afc.name
    #   rescue AirfoilChecker::ErrorName => e
    #     af.data_errors = e.message
    #   rescue AirfoilChecker::ErrorPointsConsistency => e
    #     af.data_errors = e.message
    #   ensure
    #     af.save!
    #   end
    #
    #
    # end


  end

end
