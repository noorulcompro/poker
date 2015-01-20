class UserSerializer < ActiveModel::Serializer
  attributes  :id, 
              :login_token,
  						:preferred_table_config_id, 
  						:email, 
  						:device_avatar_id, 
  						:full_name,
              :fb_id,
  						:chips,
  						:player_since,
  						:biggest_pot,
  						:best_hand,
  						:hands_played,
  						:hands_won,
  						:folds_percent,
  						:raises_percent,
  						:checks_percent,
  						:bets_percent,
              :all_ins_percent

      has_many :friend_requests
      has_many :friendships

end
