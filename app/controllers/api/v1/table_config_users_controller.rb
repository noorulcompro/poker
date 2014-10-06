class Api::V1::TableConfigUsersController < Api::V1::ApplicationController

	def create
		@table_config_user = TableConfigUser.new(table_config_id: params[:table_config_id], user_id: params[:user_id], active: true)
		if @table_config_user.save
			render json: {
				user: @table_config_user.user,
				success: true
			}
		else
			render json: {
				user: @table_config_user.errors.full_messages.join(", "),
				success: false
			}
		end
	end

end