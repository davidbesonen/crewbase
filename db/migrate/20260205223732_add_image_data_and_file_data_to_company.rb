class AddImageDataAndFileDataToCompany < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :image_data, :text
  end
end
