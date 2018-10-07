# frozen_string_literal: true
class Course::Survey::Answer < ApplicationRecord
  validates_presence_of :creator
  validates_presence_of :updater
  validates_presence_of :response
  validates_presence_of :question

  belongs_to :response, inverse_of: :answers
  belongs_to :question, inverse_of: :answers
  has_many :options, class_name: Course::Survey::AnswerOption.name,
                     inverse_of: :answer, dependent: :destroy
  has_many :question_options, through: :options

  accepts_nested_attributes_for :options
end
