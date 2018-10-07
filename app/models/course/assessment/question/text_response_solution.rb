# frozen_string_literal: true
class Course::Assessment::Question::TextResponseSolution < ApplicationRecord
  enum solution_type: [:exact_match, :keyword]
  
  before_validation :strip_whitespace
  validate :validate_grade
  validates_presence_of :solution_type
  validates_presence_of :solution
  validates_numericality_of :grade, allow_nil: true, greater_than: -1000, less_than: 1000
  validates_presence_of :grade
  validates_presence_of :question

  belongs_to :question, class_name: Course::Assessment::Question::TextResponse.name,
                        inverse_of: :solutions

  def initialize_duplicate(duplicator, other)
    self.question = duplicator.duplicate(other.question)
  end

  private

  def strip_whitespace
    solution&.strip!
  end

  def validate_grade
    errors.add(:grade, :invalid_grade) if grade > question.maximum_grade
  end
end
