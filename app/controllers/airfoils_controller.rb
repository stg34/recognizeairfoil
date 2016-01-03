require 'airfoils/airfoil_checker'

class AirfoilsController < ApplicationController
  before_action :set_airfoil, only: [:show, :edit, :update, :destroy]

  # GET /airfoils
  # GET /airfoils.json
  def index

    @airfoils = Airfoil.paginate(:page => params[:page], per_page: 100).order('name asc')
    @raw_images = {}

    @airfoils.each do |af|
      #afc = AirfoilChecker::Checker.new(af.data_raw)
      acoords = []#[afc.raw_coords]
      acoords << (af.top + ';' +  af.bottom).split(';').map{|p| [p.split(',')[0].to_f, p.split(',')[1].to_f]}
      @raw_images[af] = svg(acoords)
    end

  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_airfoil
    @airfoil = Airfoil.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def airfoil_params
    params.require(:airfoil).permit(:raw, :coordinates, :top, :bottom, :name, :comment, :fixes)
  end

  def svg(airfoils_coords)
    min_y = airfoils_coords.flatten(1).map{|c| c[1]}.min
    max_y = airfoils_coords.flatten(1).map{|c| c[1]}.max
    w = 600
    if max_y != min_y
      h = ((max_y - min_y)*w).ceil.to_i
    else
      h = 0.1*w.to_i
    end
    h = w if h > w

    base_line_y = (h - (h*max_y/(max_y - min_y))).round.to_i
    padding = 10

    img = Rasem::SVGImage.new(w + 2 * padding, h + 2 * padding) do

      airfoils_coords.each_with_index do |coords, j|

        n = coords.size
        coords.each_index.each do |i|
          x1, y1 = coords[i % n]
          x2, y2 = coords[(i+1) % n]
          xs1 = x1 * w + padding
          ys1 = h - y1 * w + padding - base_line_y

          xs2 = x2 * w + padding
          ys2 = h - y2 * w + padding - base_line_y

          line xs1, ys1, xs2, ys2, :stroke=>['blue', 'red'][j%2]
        end
      end
      line 0, h - base_line_y + padding, w + 2*padding, h - base_line_y + padding, :stroke=>'silver'
    end

    return Base64.encode64(img.output)
  end
end
