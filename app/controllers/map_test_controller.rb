class MapTestController < ApplicationController
  def index
    render layout: false
  end

  def with_importmap
    # Uses default layout with importmap
  end
end
