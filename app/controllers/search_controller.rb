require 'pp'
load 'airfoils/airfoil_checker.rb'

class SearchController < ApplicationController
  #before_action :set_foo, only: [:show, :edit, :update, :destroy]

  # GET /search
  # GET /search.json

  def search
    unless params[:coordinates].blank?
      @afc = AirfoilChecker::Checker.new(params[:coordinates])
      @check_result = @afc.check
      @svg = svg(@afc.raw_coords) if @afc.raw_coords.size > 1

      @raw_images = {}
      if @check_result
        @my_airfoil = AirfoilChecker::Airfoil.new(@afc.top, @afc.bottom)

        opts = {angles: [-2, 2, 0.1]}

        search_result = []
        airfoils = Airfoil.where("thickness < #{@my_airfoil.thickness*1.2} AND thickness > #{@my_airfoil.thickness*0.8}").all
        airfoils.each do |af|
          top_coords = af.top.split(';').map{|cs| cs.split(',').map(&:to_f)}.map{|pair| AirfoilChecker::Coord.new(*pair, nil)}
          bottom_coords = af.bottom.split(';').map{|cs| cs.split(',').map(&:to_f)}.map{|pair| AirfoilChecker::Coord.new(*pair, nil)}
          airfoil = AirfoilChecker::Airfoil.new(top_coords, bottom_coords)
          cmp_result = @my_airfoil.compare(airfoil, opts)
          angle = cmp_result[1]
          search_result << {airfoil: airfoil, cmp: cmp_result[0], af: af, angle: angle, debug: cmp_result[2]}

        end

        search_result.sort!{|a, b| a[:cmp] <=> b[:cmp]}

        my_coords = (@my_airfoil.top + @my_airfoil.bottom).map{|c| [c.x, c.y]}

        search_result = search_result[0..50]
        search_result.each do |sr|
          airfoil = sr[:airfoil]
          airfoil.rotate(-sr[:angle]*Math::PI/180)
          airfoil.shift(sr[:debug][:shift])
          acoords = (airfoil.top + airfoil.bottom).map{|c| [c.x, c.y]}
          sr[:img] = svg2([my_coords, acoords])
        end

        @search_result = search_result
      end

    end
    @coordinates = params[:coordinates]

  end

  private

  def svg2(airfoils_coords)
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

          ys1
          line xs1, ys1, xs2, ys2, :stroke=>['red', 'blue', 'green'][j%2]
        end
      end
      #line 0, h - base_line_y + padding, w + 2*padding, h - base_line_y + padding, :stroke=>'silver'
    end

    return Base64.encode64(img.output)
  end

  def svg(airfoil_coords)
    min_x = airfoil_coords.map{|c| c[0]}.min
    max_x = airfoil_coords.map{|c| c[0]}.max

    min_y = airfoil_coords.map{|c| c[1]}.min
    max_y = airfoil_coords.map{|c| c[1]}.max


    dx = (max_x - min_x)
    dy = (max_y - min_y)
    max_d = dx > dy ? dx : dy
    if max_d!= 0
      scale = 1/dx
    else
      scale = 1
    end

    airfoil_coords.map!{|rc| [(rc[0]-min_x)*scale, (rc[1]-min_y)*scale, rc[2]]}

    min_y = airfoil_coords.map{|c| c[1]}.min
    max_y = airfoil_coords.map{|c| c[1]}.max


    w = 800
    padding = 20

    if max_y != min_y
      h = ((max_y - min_y)*w).ceil.to_i
    else
      h = 0.1*w.to_i
    end

    if h > w
      h = w
    end

    img = Rasem::SVGImage.new(w + 2 * padding, h + 2 * padding) do

      n = airfoil_coords.size
      airfoil_coords.each_index.each do |i|

        x1 = airfoil_coords[i % n][0]
        y1 = airfoil_coords[i % n][1]
        x2 = airfoil_coords[(i+1) % n][0]
        y2 = airfoil_coords[(i+1) % n][1]
        line_num = airfoil_coords[(i+1) % n][2]
        xs1 = x1 * w + padding
        ys1 = h - y1 * w + padding

        xs2 = x2 * w + padding
        ys2 = h - y2 * w + padding

        line xs1, ys1, xs2, ys2, :stroke=>'red'
        circle xs1, ys1, 1, :stroke=>'red', fill: 'red'
        text xs1, ys1 - 10, line_num.to_s, :font_family=>'Arial', 'font-size'=>9
      end
      text w-100, 10, "Number near a point\nis according line number", :font_family=>'Arial', 'font-size'=>10

    end

    return Base64.encode64(img.output)
  end

end
