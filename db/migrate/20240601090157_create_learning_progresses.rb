class CreateLearningProgresses < ActiveRecord::Migration[7.0]
  def change
    create_table :learning_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :content
      t.integer :progress

      t.timestamps
    end
  end
end
