# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DealsController, js: true, type: :feature do
  self.use_transactional_tests = false
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  # 変更windowを開いたあとの記述。閲覧と記入でまったく同じなのでここで
  shared_examples_for "複数記入に変更できる" do
    before do
      click_link '複数記入にする'
    end
    it "フォーム部分だけが変わる" do
      expect(page).to have_css("select#deal_creditor_entries_attributes_4_account_id")
    end
    it "記入欄を増やせる" do
      click_link '記入欄を増やす'
      expect(page).to have_css("select#deal_creditor_entries_attributes_5_account_id")
    end
  end

  shared_examples_for "変更を実行できる" do
    before do
      find("#date_day[value='10']")
      fill_in 'date_day', :with => '11'
      fill_in 'deal_summary', :with => '冷やし中華'
      fill_in 'deal_debtor_entries_attributes_0_amount', :with => '920'
      select 'クレジットカードＸ', :from => 'deal_creditor_entries_attributes_0_account_id'
      click_button '変更'
    end

    it "一覧に表示される" do
      expect(flash_notice).to have_content("更新しました。")
      expect(flash_notice).to have_content("2012/07/11")
      expect(page).to have_content('冷やし中華')
      expect(page).to have_content('920')
      expect(page).to have_content('クレジットカードＸ')
    end
  end

  before do
    Deal::Base.destroy_all
  end

  include_context "太郎 logged in"

  describe "家計簿(閲覧)" do
    before do
      select_menu('家計簿')
    end

    describe "今日エリアのクリック" do
      let(:target_date) {Date.today << 1}
      before do
        # 前月にしておいて
        click_calendar(target_date.year, target_date.month)

        # クリック
        find("#today").click
      end

      it "カレンダーの選択月が今月に変わる" do
        expect(find("td.selected_month").text).to eq("#{Date.today.month}月")
      end
    end


    describe "カレンダー（翌月）のクリック" do
      let(:target_date) {Date.today >> 1}
      before do
        click_calendar(target_date.year, target_date.month)
      end

      it "カレンダーの選択月が翌月に変わる" do
        expect(find("td.selected_month").text).to eq("#{target_date.month}月")
      end
    end

    describe "カレンダー（翌年）のクリック" do
      before do
        find("#next_year").click
      end
      it "URLに翌年を含む" do
        expect(current_path =~ /\/#{(Date.today >> 12).year.to_s}\//).to be_truthy
      end
    end

    describe "カレンダー（前年）のクリック" do
      before do
        find("#prev_year").click
      end
      it "URLに前年を含む" do
        expect(current_path =~ /\/#{(Date.today << 12).year.to_s}\//).to be_truthy
      end
    end

    describe "日ナビゲーターのクリック" do
      let(:target_date) {Date.today << 1} # 前月
      before do
        click_calendar(target_date.year, target_date.month)
        # 3日をクリック
        date = Date.new((Date.today << 1).year, target_date.month, 3)
        click_link I18n.l(date, :format => :day).strip # strip しないとマッチしない
      end
      it "URLに対応する日付ハッシュがつく" do
        expect(current_hash).to eq('day3')
      end
    end

    describe "変更" do
      context "単純明細の変更ボタンをクリックしたとき" do
        let!(:deal) { FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10), :summary => "ラーメン") }
        before do
          visit "/deals/2012/7"
          click_link '変更'
        end
        it "URLにハッシュがつき、変更ウィンドウが表示される" do
          expect(page).to have_css("#edit_window")
          expect(find("#edit_window #date_year").value).to eq "2012"
          expect(find("#edit_window #date_month").value).to eq "7"
          expect(find("#edit_window #date_day").value).to eq "10"
          expect(find("#edit_window #deal_summary").value).to eq "ラーメン"
          current_hash.should == "d#{deal.id}"
        end
        it_behaves_like "複数記入に変更できる"
        it_behaves_like "変更を実行できる"
        describe "実行できる" do
          before do
            find("#date_day[value='10']")
            fill_in 'date_day', :with => '11'
            fill_in 'deal_summary', :with => '冷やし中華'
            fill_in 'deal_debtor_entries_attributes_0_amount', :with => '920'
            select 'クレジットカードＸ', :from => 'deal_creditor_entries_attributes_0_account_id'
            click_button '変更'
          end

          it "一覧に表示される" do
            expect(flash_notice).to have_content("更新しました。")
            expect(flash_notice).to have_content("2012/07/11")
            expect(page).to have_content('冷やし中華')
            expect(page).to have_content('920')
            expect(page).to have_content('クレジットカードＸ')
          end
        end
      end
    end
  end

  describe "家計簿(記入)" do

    before do
      select_menu('家計簿')
      click_link('記入する')
    end

    describe "今日エリアのクリック" do
      let(:target_date) {Date.today << 1}
      before do
        # 前月にしておいて
        click_calendar(target_date.year, target_date.month)

        # クリック
        find("#today").click
      end
      it "カレンダーの選択月が今月に変わり、記入日の年月日が変わる" do
        expect(find("td.selected_month").text).to eq "#{Date.today.month}月"
        expect(find("input#date_year").value).to eq Date.today.year.to_s
        expect(find("input#date_month").value).to eq Date.today.month.to_s
        expect(find("input#date_day").value).to eq Date.today.day.to_s
      end
    end

    describe "カレンダー（翌月）のクリック" do
      let(:target_date) {Date.today >> 1}
      before do
        click_calendar(target_date.year, target_date.month)
      end
      it "カレンダーの選択月が翌月に変わり、記入日の月が変わる" do
        expect(find("td.selected_month").text).to eq "#{target_date.month}月"
        expect(find("input#date_month").value).to eq target_date.month.to_s
      end
    end

    describe "カレンダー（翌年）のクリック" do
      before do
        find("#next_year").click
      end
      it "記入日の年が変わる" do
        expect(find("input#date_year").value).to eq (Date.today >> 12).year.to_s
      end
    end

    describe "カレンダー（前年）のクリック" do
      before do
        find("#prev_year").click
      end
      it "記入日の年が変わる" do
        expect(find("input#date_year").value).to eq (Date.today << 12).year.to_s
      end
    end

    describe "日ナビゲーターのクリック" do
      let(:target_date) {Date.today << 1} # 前月
      before do
        click_calendar(target_date.year, target_date.month)
        # 3日をクリック
        date = Date.new((Date.today << 1).year, target_date.month, 3)
        click_link I18n.l(date, :format => :day).strip # strip しないとマッチしない
      end
      it "日の欄に指定した日が入る" do
        expect(find("input#date_day").value).to eq '3'
      end
    end

    describe "登録" do
      describe "通常明細" do
        before do
          fill_in 'deal_summary', :with => '朝食のおにぎり'
          fill_in 'deal_debtor_entries_attributes_0_amount', :with => '210'
          select '現金', :from => 'deal_creditor_entries_attributes_0_account_id'
          select '食費', :from => 'deal_debtor_entries_attributes_0_account_id'
          click_button '記入'
        end
        it do
          expect(flash_notice).to have_content('追加しました。')
          expect(page).to have_content('朝食のおにぎり')
        end
      end

      describe "通常明細のサジェッション" do
        describe "'のない明細" do
          before do
            FactoryGirl.create(:general_deal, :date => Date.today, :summary => "朝食のサンドイッチ")
            fill_in 'deal_summary', :with => '朝食'
            sleep 0.6
          end
          it "先に登録したデータがサジェッション表示される" do
            expect(page).to have_css("#patterns div.clickable_text")
          end
          it "サジェッションをクリックするとデータが入る" do
            page.find("#patterns div.clickable_text").click
            expect(page.find("#deal_summary").value).to eq '朝食のサンドイッチ'
          end
        end

        describe "'のある明細" do
          before do
            FactoryGirl.create(:general_deal, :date => Date.today, :summary => "朝食の'サンドイッチ'")
            fill_in 'deal_summary', :with => '朝食'
            sleep 0.6
          end
          it "先に登録したデータがサジェッション表示される" do
            expect(page).to have_css("#patterns div.clickable_text")
          end
          it "サジェッションをクリックするとデータが入る" do
            page.find("#patterns div.clickable_text").click
            expect(page.find("#deal_summary").value).to eq "朝食の'サンドイッチ'"
          end
        end
      end

      describe "通常明細のパターン指定(id)" do
        let!(:pattern) { FactoryGirl.create(:deal_pattern,
                                            :code => '',
                                            :name => '',
                                            :debtor_entries_attributes => [{:summary => '昼食', :account_id => Fixtures.identify(:taro_food), :amount => 800}],
                                            :creditor_entries_attributes => [{:summary => '昼食', :account_id => Fixtures.identify(:taro_cache), :amount => -800}]
        ) }
        before do
          select_menu('家計簿')
          click_link "記入する"
          page.find("#recent_deal_patterns").click_link "*昼食" # パターンを指定
        end
        it "パターン登録した内容が入る" do
          sleep 1
          expect(page.find("#deal_debtor_entries_attributes_0_amount").value).to eq '800'
          expect(page.find("#deal_summary").value).to eq '昼食'
        end
      end

      describe "複数明細" do
        before do
          click_link "明細(複数)"
        end

        describe "タブを表示できる" do
          it "タブが表示される" do
            expect(page).to have_css('input#deal_creditor_entries_attributes_0_summary')
            expect(page).to have_css('input#deal_creditor_entries_attributes_1_summary')
            expect(page).to have_css('input#deal_creditor_entries_attributes_0_reversed_amount')
            expect(page).to have_css('input#deal_creditor_entries_attributes_1_reversed_amount')
            expect(page).to have_css('input#deal_creditor_entries_attributes_2_reversed_amount')
            expect(page).to have_css('input#deal_creditor_entries_attributes_3_reversed_amount')
            expect(page).to have_css('input#deal_creditor_entries_attributes_4_reversed_amount')
            expect(page).to have_css('select#deal_creditor_entries_attributes_0_account_id')
            expect(page).to have_css('select#deal_creditor_entries_attributes_1_account_id')
            expect(page).to have_css('select#deal_creditor_entries_attributes_2_account_id')
            expect(page).to have_css('select#deal_creditor_entries_attributes_3_account_id')
            expect(page).to have_css('select#deal_creditor_entries_attributes_4_account_id')
            expect(page).to have_css('input#deal_debtor_entries_attributes_0_amount')
            expect(page).to have_css('input#deal_debtor_entries_attributes_1_amount')
            expect(page).to have_css('input#deal_debtor_entries_attributes_2_amount')
            expect(page).to have_css('input#deal_debtor_entries_attributes_3_amount')
            expect(page).to have_css('input#deal_debtor_entries_attributes_4_amount')
            expect(page).to have_css('select#deal_debtor_entries_attributes_0_account_id')
            expect(page).to have_css('select#deal_debtor_entries_attributes_1_account_id')
            expect(page).to have_css('select#deal_debtor_entries_attributes_2_account_id')
            expect(page).to have_css('select#deal_debtor_entries_attributes_3_account_id')
            expect(page).to have_css('select#deal_debtor_entries_attributes_4_account_id')
          end
        end

        describe "記入欄を増やすことができる" do
          before do
            click_link '記入欄を増やす'
          end

          it "6つめの記入欄が表示される" do
            expect(page).to have_css('input#deal_creditor_entries_attributes_5_reversed_amount')
            expect(page).to have_css('select#deal_creditor_entries_attributes_5_account_id')
            expect(page).to have_css('input#deal_debtor_entries_attributes_5_amount')
            expect(page).to have_css('select#deal_debtor_entries_attributes_5_account_id')
          end
        end

        describe "1対2の明細が登録できる" do
          before do
            find('a.entry_summary').click # unifyモードにする
            fill_in 'deal_summary', :with => '買い物'
            fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => '1000'
            select '現金', :from => 'deal_creditor_entries_attributes_0_account_id'
            fill_in 'deal_debtor_entries_attributes_0_amount', :with => '800'
            select '食費', :from => 'deal_debtor_entries_attributes_0_account_id'
            fill_in 'deal_debtor_entries_attributes_1_amount', :with => '200'
            select '雑費', :from => 'deal_debtor_entries_attributes_1_account_id'
            click_button '記入'
          end

          it "明細が一覧に表示される" do
            expect(flash_notice).to have_content('追加しました。')
            expect(page).to have_content '買い物'
            expect(page).to have_content '1,000'
            expect(page).to have_content '800'
            expect(page).to have_content '200'
          end
        end

      end

      describe "残高" do
        before do
          click_link "残高"
        end

        describe "タブを表示できる" do
          it do
            expect(page).to have_css('select#deal_account_id')
            expect(page).to have_content('計算')
            expect(page).to have_content('残高')
            expect(page).to have_content('記入')

            expect(page).to_not have_css('input#deal_summary')
          end
        end

        describe "パレットをつかって登録できる" do
          before do
            select '現金', :from => 'deal_account_id'
            fill_in 'gosen', :with => '1'
            fill_in 'jyu', :with => '3'
            click_button '計算'
            click_button '記入'
          end

          it "一覧に表示される" do
            expect(flash_notice).to have_content("追加しました。")
            expect(page).to have_content("残高確認")
            expect(page).to have_content("5,030")
          end
        end
      end
    end

    describe "変更" do
      context "単純明細の変更ボタンをクリックしたとき" do
        let!(:deal) { FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10), :summary => "ラーメン") }
        before do
          visit "/deals/new"
          find("tr#d#{deal.id}").click_link '変更'
        end
        it "URLにハッシュがつき、登録エリアが隠され、変更ウィンドウが表示される" do
          expect(page).to have_css("#edit_window")
          expect(page).to_not have_css("#new_deal_window")
          expect(find("#edit_window #date_year").value).to eq "2012"
          expect(find("#edit_window #date_month").value).to eq "7"
          expect(find("#edit_window #date_day").value).to eq "10"
          expect(find("#edit_window #deal_summary").value).to eq "ラーメン"
          expect(current_hash).to eq "d#{deal.id}"
        end
        it_behaves_like "複数記入に変更できる"
        it_behaves_like "変更を実行できる"
      end
    end
  end
  #
  # describe "変更" do
  #
  #   describe "複数明細" do
  #     before do
  #       FactoryGirl.create(:complex_deal, :date => Date.new(2012, 7, 7))
  #       visit "/deals/2012/7"
  #       click_link "変更"
  #     end
  #
  #     describe "タブを表示できる" do
  #       it "タブが表示される" do
  #         tab_window.should have_content("変更(2012-07-07-1)")
  #         find("input#deal_creditor_entries_attributes_0_reversed_amount").value.should == '1000'
  #         find("input#deal_debtor_entries_attributes_0_amount").value.should == '800'
  #         find("input#deal_debtor_entries_attributes_1_amount").value.should == '200'
  #       end
  #     end
  #
  #     describe "記入欄を増やすことができる" do
  #       before do
  #         click_link '記入欄を増やす'
  #       end
  #
  #       it "6つめの記入欄が表示される" do
  #         expect(page).to have_css('input#deal_creditor_entries_attributes_5_reversed_amount')
  #         expect(page).to have_css('select#deal_creditor_entries_attributes_5_account_id')
  #         expect(page).to have_css('input#deal_debtor_entries_attributes_5_amount')
  #         expect(page).to have_css('select#deal_debtor_entries_attributes_5_account_id')
  #       end
  #     end
  #
  #     describe "変更ができる" do
  #       before do
  #         fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => '1200'
  #         fill_in 'deal_debtor_entries_attributes_0_amount', :with => '900'
  #         fill_in 'deal_debtor_entries_attributes_1_amount', :with => '300'
  #         select '銀行', :from => 'deal_creditor_entries_attributes_0_account_id'
  #         click_button '変更'
  #       end
  #
  #       it "変更内容が一覧に表示される" do
  #         expect(flash_notice).to have_content "更新しました。"
  #         expect(page).to have_content '銀行'
  #         expect(page).to have_content '1,200'
  #         expect(page).to have_content '900'
  #         expect(page).to have_content '300'
  #       end
  #     end
  #
  #     describe "カンマ入りの数字を入れて口座を変えても変更ができる" do
  #       # reversed_amount の代入時にparseされていない不具合がたまたまこのスペックで発見できた
  #       before do
  #         fill_in 'deal_creditor_entries_attributes_0_reversed_amount', :with => '1,200'
  #         fill_in 'deal_debtor_entries_attributes_0_amount', :with => '900'
  #         fill_in 'deal_debtor_entries_attributes_1_amount', :with => '300'
  #         select '銀行', :from => 'deal_creditor_entries_attributes_0_account_id'
  #         click_button '変更'
  #       end
  #
  #       it "変更内容が一覧に表示される" do
  #         expect(flash_notice).to have_content "更新しました。"
  #         expect(page).to have_content '銀行'
  #         expect(page).to have_content '1,200'
  #         expect(page).to have_content '900'
  #         expect(page).to have_content '300'
  #       end
  #     end
  #
  #   end
  #
  #   describe "残高" do
  #     before do
  #       FactoryGirl.create(:balance_deal, :date => Date.new(2012, 7, 20), :balance => '2000')
  #       visit "/deals/2012/7"
  #       click_link '変更'
  #     end
  #
  #     describe "タブを表示できる" do
  #       it "タブが表示される" do
  #         tab_window.should have_content("変更(2012-07-20-1)")
  #         find("input#deal_balance").value.should == '2000'
  #       end
  #     end
  #
  #     describe "実行できる" do
  #       before do
  #         fill_in 'deal_balance', :with => '2080'
  #         click_button '変更'
  #       end
  #       it "一覧に表示される" do
  #         expect(flash_notice).to have_content("更新しました。")
  #         expect(page).to have_content('2,080')
  #       end
  #     end
  #   end
  # end
  #
  # describe "削除" do
  #
  #   describe "通常明細" do
  #     before do
  #       FactoryGirl.create(:general_deal, :date => Date.new(2012, 7, 10))
  #       visit "/deals/2012/7"
  #       click_link('削除')
  #       page.driver.browser.switch_to.alert.accept
  #     end
  #     it do
  #       expect(flash_notice).to have_content("削除しました。")
  #     end
  #   end
  #
  #   describe "複数明細" do
  #     before do
  #       FactoryGirl.create(:complex_deal, :date => Date.new(2012, 7, 7))
  #       visit "/deals/2012/7"
  #       click_link "削除"
  #       page.driver.browser.switch_to.alert.accept
  #     end
  #
  #     it do
  #       expect(flash_notice).to have_content("削除しました。")
  #     end
  #
  #   end
  #
  #   describe "残高" do
  #     before do
  #       FactoryGirl.create(:balance_deal, :date => Date.new(2012, 7, 20))
  #       visit "/deals/2012/7"
  #       click_link('削除')
  #       page.driver.browser.switch_to.alert.accept
  #     end
  #     it do
  #       expect(flash_notice).to have_content("削除しました。")
  #     end
  #   end
  #
  # end

end