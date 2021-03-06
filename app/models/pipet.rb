class Pipet < ApplicationRecord

  has_many :batch_pipets
  has_many :batches, through: :batch_pipets

  validates :calibration_date, presence: true
  validates :calibration_due, presence: true
  validates :max_volume, presence: true, numericality: { only_integer: true }
  validates :min_volume, presence: true, numericality: { only_integer: true }
  validates :adjustable, inclusion: { in: [true, false]}
end
