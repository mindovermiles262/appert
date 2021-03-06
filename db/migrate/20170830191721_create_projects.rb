class CreateProjects < ActiveRecord::Migration[5.1]
  def change
    create_table :projects do |t|
      t.boolean :received, default: false
      t.boolean :completed, default: false
      t.boolean :reported, default: false
      t.boolean :invoiced, default: false
      t.boolean :paid, default: false
      t.references :user
      t.references :samples
      t.string :description, default: ""
      t.string :lot, default: ""

      t.timestamps
    end
  end
end
