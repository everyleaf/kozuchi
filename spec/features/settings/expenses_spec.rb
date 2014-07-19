# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Settings::AccountsController do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  describe "/settings/expenses" do
    include_context "太郎 logged in"
    before do
      visit "/settings/expenses"
    end
    it "口座名入力欄がある" do
      page.should have_css('input#account_name')
    end
    it "各口座のフォームがある" do
      page.should have_css('table.masters')
    end
  end
end