class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :table_config_users
  has_many :table_configs, through: :table_config_users
  has_many :table_users
  has_many :tables, through: :table_users
  has_many :game_users
  has_many :tournament_users
  has_many :games, through: :game_users
  has_many :friend_requests, :dependent => :destroy, foreign_key: "requested_to_id"
  has_many :friend_requests_sent, :dependent => :destroy, foreign_key: "user_id", class_name: "FriendRequest"
  has_many :unconfirmed_friend_requests, -> { where(confirmed: false) }, class_name: "FriendRequest", foreign_key: "requested_to_id"
  has_many :friendships, :dependent => :destroy
  has_many :friends, through: :friendships
  has_many :gift_requests, :dependent => :destroy, foreign_key: "send_to_id"
  has_many :gift_requests_sent, :dependent => :destroy, foreign_key: "user_id", class_name: "GiftRequest"
  has_many :login_histories, :dependent => :destroy
  has_many :unconfirmed_gift_requests, -> { where(confirmed: false) }, class_name: "GiftRequest", foreign_key: "send_to_id"
  has_many :login_histories
  attr_accessor :fb_friends_list, :is_friend, :is_requested, :new_fb_user, :previous_login_token
  accepts_nested_attributes_for :tournament_users
  has_attached_file :image,
    Poker::Configuration.paperclip_options[:users][:image]

  validates_attachment :image, content_type: { content_type: /\Aimage\/.*\Z/ }

  accepts_nested_attributes_for :login_histories

  before_create :set_joining_bonus
  before_validation :set_fb_login_details, :set_guest_login_details, :set_fb_friends
  after_create :set_chips_for_fb_user, :set_chips_for_synced_user

  def self.fetch_by_login_token(login_token)
    if login_token
      self.where(login_token: login_token).first || LoginHistory.where(login_token: login_token).first.user
    end
  end

  def avatar
    self.image? ? image.url(:avatar) : nil
  end

  def num_friend_request
    FriendRequest.where(requested_to_id: self.id, confirmed: false).count()
  end

  def num_gift_request
    GiftRequest.where(send_to_id: self.id, confirmed: false).count()
  end

  def folds_percent
    percentage = (folds * 100)/total_turns.to_f
    percentage.nan? ? 0 : percentage
  end

  def checks_percent
    percentage = (checks * 100)/total_turns.to_f
    percentage.nan? ? 0 : percentage
  end

  def bets_percent
    percentage = ((bets + all_ins + raises) * 100)/total_turns.to_f
    percentage.nan? ? 0 : percentage
  end

  def calls_percent
    percentage = (calls * 100)/total_turns.to_f
    percentage.nan? ? 0 : percentage
  end

  def sitandgo_percent
    percentage = (sitandgo_win * 100)/sitandgo_played.to_f 
    sitandgo_played != 0 ? percentage : 0
  end

  def shootout_percent
    percentage = (shootout_win * 100)/shootout_played.to_f
    shootout_played != 0 ? percentage : 0
  end

  def player_since
    created_at.strftime("%B,%Y")
  end

  def full_name
    if([first_name, last_name].compact.blank?)
      email
    else
      [first_name, last_name].compact.join(" ")
    end
  end
  
  def image_url 
    if fb_id
      "http://graph.facebook.com/#{fb_id}/picture?height=200"
    end
  end

  def preferred_table_config
    table_config_users.where(active: true).first
  end

  def preferred_table_config_id
  	preferred_table_config.try(:table_config_id)
  end

  def get_table
    tables = Table.where(table_config_id: @user.preferred_table_config_id)
  end

  #Roles = [ :admin , :default ]

  def is?( requested_role )
    self.role == requested_role.to_s
  end

  private

  def set_joining_bonus
    self.chips = 10000
  end

  def set_fb_login_details
    if fb_id
      password_generated = SecureRandom.hex(4)
      self.password = password_generated
      self.password_confirmation = password_generated
    end
  end

  def set_guest_login_details
    if is_guest
      password_generated = SecureRandom.hex(4)
      self.email = "guest_"+SecureRandom.hex(3)+"@pokerapi.com"
      self.password = password_generated
      self.password_confirmation = password_generated
    end
  end

  def set_fb_friends
    if fb_friends_list
      user_ids = User.where(fb_id: fb_friends_list).collect(&:id)
      friend_ids = self.friends.collect(&:id)
      new_friend_ids = user_ids - friend_ids
      deleted_friends_ids = friend_ids - user_ids
      new_friend_ids.each do |friend_id|
        Friendship.create(user_id: self.id, friend_id: friend_id)
        Friendship.create(user_id: friend_id, friend_id: self.id)
      end
      deleted_friends_ids.each do |deleted_friend_id|
        Friendship.where(user_id: self.id, friend_id: deleted_friend_id).first.delete
        Friendship.where(user_id: deleted_friend_id, friend_id: self.id).first.delete
      end
    end
  end

  def set_chips_for_fb_user
    if fb_id && !self.parent_id.present?
      chips = self.chips + 10000
      self.update_attributes(chips: chips)
    end
  end

  def set_chips_for_synced_user
    if self.parent_id.present?
      chips = User.where(id: parent_id).first.chips + 10000
      self.update_attributes(chips: chips)
    end
  end

end