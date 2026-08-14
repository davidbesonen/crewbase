class RequireCompanyPlanStatus < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE company_plans SET status = 'active' WHERE status IS NULL"
    change_column_null :company_plans, :status, false
  end

  def down
    change_column_null :company_plans, :status, true
  end
end
