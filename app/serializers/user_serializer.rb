class UserSerializer < ActiveModel::Serializer
  attributes  :id, 
  						:preferred_table_config_id, 
  						:email, 
  						:device_avatar_id, 
  						:full_name,
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

end
