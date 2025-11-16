class RenameHikeHistoryMemberIdToUserId < ActiveRecord::Migration[8.1]
  def change
    if column_exists?(:hike_histories, :member_id)
      rename_column :hike_histories, :member_id, :user_id
    end
  end
end
