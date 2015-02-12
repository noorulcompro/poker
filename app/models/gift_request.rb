class GiftRequest < ActiveRecord::Base

	belongs_to :user
	has_many :gift_requests_sent
	validate :search_requested_friend, on: :create
	validate :valid_request, :on => :create

	private

	def search_requested_friend
		send_to = User.where(login_token: send_to_id).first
		unless send_to.blank?	
			self.send_to_id = send_to.id
		else
			self.errors.add(:base, "Requested User not present")
		end
	end

	def valid_request
		if Friendship.where(user_id: user_id, friend_id: send_to_id).blank?
			self.errors.add(:base, "Requested user is not your friend! You can send gift only to your friend.")
		end
	end

end
