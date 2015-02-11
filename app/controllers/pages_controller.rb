class PagesController < ApplicationController
  def index
  end

  def dummy
  	@survey = Survey.find(7)
  end
end
