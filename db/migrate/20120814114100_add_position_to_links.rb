# -*- encoding : utf-8 -*-
class AddPositionToLinks < ActiveRecord::Migration
  def change
    add_column :links, :position, :integer
  end
end
