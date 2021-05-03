class Settings::AccountsController < ApplicationController
  cache_sweeper :export_sweeper
  menu_group "設定"

  before_action :set_account_class
  before_action :find_account, :only => [:show, :update, :destroy]

  # 一覧・登録フォーム
  def index
    @menu = @account_class.human_name
    @accounts = user_accounts
    @account = @account_class.new
    set_asset_kinds_option_container if @account_class.has_kind?
  end

  # 新しい勘定を作成
  def create
    @account = user_accounts.build(account_params)
    if @account.save
      flash[:notice]="「#{@account.name}」を登録しました。"
      redirect_to action: :index
    else
      @accounts = user_accounts.reload
      set_asset_kinds_option_container if @account_class.has_kind?
      render action: :index
    end
  end

  def update_all
    raise InvalidParameterError unless params[:account]
    @accounts = []
    all_saved = true
    params[:account].keys.each do |id| # NOTE: Rails 4.0.2 key, value ととると value が普通のハッシュになってしまう(strong parameters が効かない)
      attributes = params[:account][id].permit(:name, :asset_kind, :sort_key)
      account = user_accounts.find(id)
      all_saved = false unless account.update(attributes)
      @accounts << account
    end
    if all_saved
      flash[:notice] = "すべての#{@account_class.human_name}を変更しました。"
      redirect_to action: :index
    else
      flash.now[:notice] = "変更できなかった#{@account_class.human_name}があります。"
      @accounts.sort!{|a, b| a.sort_key.to_i <=> b.sort_key.to_i}
      @account = @account_class.new
      set_asset_kinds_option_container if @account_class.has_kind?
      render :action => "index"
    end
  end

  def destroy
    begin
      @account.destroy
      flash[:notice]="「#{@account.name}」を削除しました。"
    rescue Account::Base::UsedAccountException => err
      flash[:errors]= [err.message]
    end
    redirect_to action: :index
  end

  # 詳細・変更開始兼用
  def show
    @menu = "#{@account_class.human_name} - 詳しい設定 - #{@account.name}"
  end

  def update
    if @account.update(account_details_params)
      redirect_to({action: :show}, notice: "「#{@account.name}」の詳しい設定を更新しました。")
    else
      render :show
    end
  end

  private

  def account_details_params
    permitted = [:active, :description]
    permitted.concat([:settlement_order_asc, :settlement_target_account_id, :settlement_paid_on, :settlement_closed_on_month, :settlement_closed_on_day, :settlement_term_margin]) if @account.any_credit?
    params.require(:account).permit(*permitted)
  end

  def user_accounts
    current_user.send(params[:account_type].pluralize)
  end

  def set_account_class
    @account_class = Account.const_get(params[:account_type].classify)
  end

  def account_params
    params.require(:account).permit(:name, :asset_kind, :sort_key)
  end

  def find_account
    @account = user_accounts.find(params[:id])
  end

  def set_asset_kinds_option_container
    @asset_kinds_options_container = {}
    for key, attributes in current_user.available_asset_kinds
      @asset_kinds_options_container[attributes[:name]] = key.to_s
    end
  end

end
