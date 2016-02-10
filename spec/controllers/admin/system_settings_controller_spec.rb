# spec/controllers/admin/system_settings_controller_spec.rb
require 'spec_helper'
include Devise::TestHelpers

RSpec.configure do |config|
  config.fail_fast = true
  config.include Rails.application.routes.url_helpers
end

describe Admin::SystemSettingsController do
  #render_views

  before(:each) do
    # log in as admin
    visit :admin
    @admin = FactoryGirl.create(:admin_user)
    fill_in :admin_user_email,         with: @admin.email
    fill_in :admin_user_password,         with: @admin.password
    click_button 'Login', match: :first
  end


  describe "System Settings links" do
    describe "dashboard" do
      it "should have menu item to System Settings" do
        # dashboard:
        expect( page ).to have_link( "System Settings", href: admin_system_settings_path )
      end
    end # describe "dashboard" do
    
    describe "System Settings index" do
      it "should have link to New System Setting" do
        # system settings index page:
        visit admin_system_settings_path
        #puts page.html.gsub(/[\n\t]/, '').inspect
        expect( page ).to have_link( "New System Setting", href: new_admin_system_setting_path  )
      end
    end # describe "System Settings index" do
  end # describe "System Settings links" do
end # describe Admin::SystemSettingsController do