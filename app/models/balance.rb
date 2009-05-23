# 残高確認記入行クラス
# TODO: 登録、更新の処理の統一
# TODO: もう少しAccountオブジェクトを使ように設計変更

# * 登録時は、account_id, balanceをセットしてsaveする。
# * 参照時は、account_id, balanceで既存のAccountEntryのデータにアクセスできる。
class Balance < BaseDeal
  attr_writer :account_id, :balance
  
  validates_presence_of :balance, :message => '残高を入力してください。'

  after_save :update_initial_balance
  after_destroy :update_initial_balance

  def to_xml(options = {})
    options[:indent] ||= 4
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.balance(:id => "balance#{self.id}", :date => self.date_as_str, :position => self.daily_seq, :account => "account#{self.account_id}") do
      xml.description XMLUtil.escape(self.summary)
      xml.amount self.balance
    end
  end

  def to_csv
    ["balance", self.id, date_as_str, daily_seq, "\"#{summary}\"", account_id, balance].join(",")
  end

  def initial_balance?
    entry.initial_balance?
  end

  # TODO: 関連にかえていく
  def entry
    account_entries.first
  end
  
  def before_validation
    # もし金額にカンマが入っていたら正規化する
    @balance = @balance.gsub(/,/,'')  if @balance.class == String
  end

  def before_create
    self.summary = ""
    e = account_entries.build(:amount => calc_amount, :balance => self.balance)
    e.account_id = self.account_id
  end
  
  def before_update
    account_entries.clear
    e = account_entries.build(:amount => calc_amount, :balance => self.balance)
    e.account_id = self.account_id
    e.save # TODO: !でなくていいの？
  end

  def account_id
    @account_id ||= (entry ? entry.account_id : nil)
    @account_id
  end
  
  def balance
    @balance ||= (entry ? entry.balance : nil)
    @balance
  end
  
  def amount
    entry ? entry.amount : nil
  end
  
  # amount（最初の残高以外は不明金として扱われる）を再計算して更新
  # 自分が「最初の残高」なら、最初の残高を考慮しない残高計算をする
  def update_amount
    e = account_entries.first
    amount = e.balance.to_i - balance_before(e.initial_balance?)
    e.update_attribute(:amount, amount)
  end
  
  def asset
    Account::Base.find(self.account_id)
  end
  
  private
  def calc_amount
    current_initial_balance = AccountEntry.find_by_account_id_and_initial_balance(self.account_id, true, :include => :deal)
    this_will_be_initial = !current_initial_balance || current_initial_balance.deal.date > self.date || (current_initial_balance.deal.date == self.date && current_initial_balance.deal.daily_seq > self.daily_seq)
    self.balance.to_i - balance_before(this_will_be_initial)
  end

  # 対象口座のinitial_balance値を更新する
  def update_initial_balance
    raise "no account_id" unless account_id
    conditions = ["account_entries.account_id = ? and deals.type='Balance'", account_id]
#    unless new_record? # Rails 2.1.0では不要だったが2.2.2では必要になった 子のcreateが行われた後くるかどうかが変わったらしい
#      conditions.first << " and deals.id != ?"
#      conditions << self.id
#    end
    initial_balance_entry = AccountEntry.find(:first, 
      :joins => "inner join deals on deals.id = account_entries.deal_id",
      :conditions => conditions, :order => "deals.date, deals.daily_seq", :readonly => false)
    raise "no initial balance entry after saving a balance" unless initial_balance_entry
#    # 現在ひとつもないなら特に仕事なし
#    return unless initial_balance_entry
    # すでにマークがついていたら仕事なし
    return if initial_balance_entry.initial_balance?

    # マークがついていない＝状態が変わったので修正する
    AccountEntry.update_all(["initial_balance = ?", false], ["account_id = ?", account_id])
    AccountEntry.update_all(["initial_balance = ?", true], ["id = ?", initial_balance_entry.id])
    self.entry.initial_balance = true if self.entry.id == initial_balance_entry.id
  end
  
  
  def balance_before(ignore_initial = false)
    raise "date or daily_seq is nil!" unless self.date && self.daily_seq
    asset.balance_before(self.date, self.daily_seq, ignore_initial)
  end
end