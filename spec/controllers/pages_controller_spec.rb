require 'spec_helper'

describe PagesController do

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'dummy'" do
    it "returns http success" do
      get 'dummy'
      response.should be_success
    end
  end

end
