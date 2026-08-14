class RefactorIndustriesForOccupationsAndSkills < ActiveRecord::Migration[8.0]
  class MigrationIndustryAssignment < ApplicationRecord
    self.table_name = "industry_assignments"
  end

  class MigrationOccupation < ApplicationRecord
    self.table_name = "occupations"
  end

  class MigrationSkill < ApplicationRecord
    self.table_name = "skills"
  end

  class MigrationOccupationAssignment < ApplicationRecord
    self.table_name = "occupation_assignments"
  end

  class MigrationSkillAssignment < ApplicationRecord
    self.table_name = "skill_assignments"
  end

  class MigrationEquipment < ApplicationRecord
    self.table_name = "equipment"
  end

  class MigrationCompany < ApplicationRecord
    self.table_name = "companies"
  end

  def up
    create_table :industry_assignments do |t|
      t.references :industry, null: false, foreign_key: true
      t.references :assignable, null: false, polymorphic: true

      t.timestamps
    end

    add_index :industry_assignments,
      [ :industry_id, :assignable_type, :assignable_id ],
      unique: true,
      name: "index_industry_assignments_uniqueness"

    backfill_occupations
    backfill_skills
    backfill_companies
    backfill_equipment

    remove_column :occupations, :industry_id, :integer
    remove_column :skills, :industry_id, :integer
    remove_column :companies, :industry_id, :integer
    remove_column :equipment, :industry_id, :integer
    add_column :occupation_assignments, :assignable_type, :string
    add_column :occupation_assignments, :assignable_id, :integer

    backfill_profile_occupation_assignments
    backfill_skill_occupation_assignments
    backfill_equipment_occupation_assignments

    MigrationOccupationAssignment.reset_column_information
    change_column_null :occupation_assignments, :assignable_type, false
    change_column_null :occupation_assignments, :assignable_id, false

    remove_index :occupation_assignments, [ :occupation_id, :profile_id ]
    remove_column :skills, :occupation_id, :integer
    remove_column :equipment, :occupation_id, :integer
    remove_column :occupation_assignments, :profile_id, :integer

    add_index :occupations, :name, unique: true
    add_index :skills, :name, unique: true
    add_index :occupation_assignments,
      [ :occupation_id, :assignable_type, :assignable_id ],
      unique: true,
      name: "index_occupation_assignments_uniqueness"
  end

  def down
    add_column :occupations, :industry_id, :integer
    add_column :skills, :industry_id, :integer
    add_column :companies, :industry_id, :integer
    add_column :equipment, :industry_id, :integer
    add_column :skills, :occupation_id, :integer
    add_column :equipment, :occupation_id, :integer
    add_column :occupation_assignments, :profile_id, :integer

    remove_index :occupations, :name
    remove_index :skills, :name
    remove_index :occupation_assignments, name: "index_occupation_assignments_uniqueness"

    MigrationOccupation.reset_column_information
    MigrationSkill.reset_column_information
    MigrationEquipment.reset_column_information
    MigrationOccupationAssignment.reset_column_information

    MigrationOccupation.find_each do |occupation|
      industry_id = MigrationIndustryAssignment
        .where(assignable_type: "Occupation", assignable_id: occupation.id)
        .order(:id)
        .pick(:industry_id)

      occupation.update_columns(industry_id: industry_id)
    end

    MigrationSkill.find_each do |skill|
      industry_id = MigrationIndustryAssignment
        .where(assignable_type: "Skill", assignable_id: skill.id)
        .order(:id)
        .pick(:industry_id)

      skill.update_columns(industry_id: industry_id)
    end

    MigrationCompany.find_each do |company|
      industry_id = MigrationIndustryAssignment
        .where(assignable_type: "Company", assignable_id: company.id)
        .order(:id)
        .pick(:industry_id)

      company.update_columns(industry_id: industry_id)
    end

    MigrationEquipment.find_each do |equipment|
      industry_id = MigrationIndustryAssignment
        .where(assignable_type: "Equipment", assignable_id: equipment.id)
        .order(:id)
        .pick(:industry_id)

      equipment.update_columns(industry_id: industry_id)
    end

    MigrationOccupationAssignment.where(assignable_type: "Profile").find_each do |assignment|
      assignment.update_columns(profile_id: assignment.assignable_id)
    end

    MigrationOccupationAssignment.where(assignable_type: "Skill").find_each do |assignment|
      skill = MigrationSkill.find_by(id: assignment.assignable_id)
      skill&.update_columns(occupation_id: assignment.occupation_id)
    end

    MigrationOccupationAssignment.where(assignable_type: "Equipment").find_each do |assignment|
      equipment = MigrationEquipment.find_by(id: assignment.assignable_id)
      equipment&.update_columns(occupation_id: assignment.occupation_id)
    end

    add_index :occupation_assignments, [ :occupation_id, :profile_id ], unique: true

    remove_column :occupation_assignments, :assignable_type, :string
    remove_column :occupation_assignments, :assignable_id, :integer

    drop_table :industry_assignments
  end

  private

  def backfill_occupations
    MigrationOccupation.reset_column_information

    MigrationOccupation.order(:id).group_by(&:name).each_value do |occupations|
      canonical = occupations.first

      occupations.each do |occupation|
        create_industry_assignment(occupation.industry_id, "Occupation", canonical.id)
        next if occupation.id == canonical.id

        MigrationOccupationAssignment.where(occupation_id: occupation.id).update_all(occupation_id: canonical.id)
        MigrationSkill.where(occupation_id: occupation.id).update_all(occupation_id: canonical.id)
        MigrationEquipment.where(occupation_id: occupation.id).update_all(occupation_id: canonical.id)
        occupation.destroy!
      end
    end
  end

  def backfill_skills
    MigrationSkill.reset_column_information

    MigrationSkill.order(:id).group_by(&:name).each_value do |skills|
      canonical = skills.first

      skills.each do |skill|
        create_industry_assignment(skill.industry_id, "Skill", canonical.id)
        next if skill.id == canonical.id

        MigrationSkillAssignment.where(skill_id: skill.id).update_all(skill_id: canonical.id)
        skill.destroy!
      end
    end
  end

  def backfill_companies
    MigrationCompany.reset_column_information

    MigrationCompany.find_each do |company|
      create_industry_assignment(company.industry_id, "Company", company.id)
    end
  end

  def backfill_equipment
    MigrationEquipment.reset_column_information

    MigrationEquipment.find_each do |equipment|
      create_industry_assignment(equipment.industry_id, "Equipment", equipment.id)
    end
  end

  def backfill_profile_occupation_assignments
    MigrationOccupationAssignment.reset_column_information

    MigrationOccupationAssignment.find_each do |assignment|
      assignment.update_columns(
        assignable_type: "Profile",
        assignable_id: assignment.profile_id
      )
    end
  end

  def backfill_skill_occupation_assignments
    MigrationSkill.reset_column_information

    MigrationSkill.where.not(occupation_id: nil).find_each do |skill|
      MigrationOccupationAssignment.find_or_create_by!(
        occupation_id: skill.occupation_id,
        assignable_type: "Skill",
        assignable_id: skill.id
      )
    end
  end

  def backfill_equipment_occupation_assignments
    MigrationEquipment.reset_column_information

    MigrationEquipment.where.not(occupation_id: nil).find_each do |equipment|
      MigrationOccupationAssignment.find_or_create_by!(
        occupation_id: equipment.occupation_id,
        assignable_type: "Equipment",
        assignable_id: equipment.id
      )
    end
  end

  def create_industry_assignment(industry_id, assignable_type, assignable_id)
    return if industry_id.blank?

    MigrationIndustryAssignment.find_or_create_by!(
      industry_id: industry_id,
      assignable_type: assignable_type,
      assignable_id: assignable_id
    )
  end
end
