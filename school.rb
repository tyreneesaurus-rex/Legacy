class School < ActiveRecord::Base
  has_many :terms
  has_many :courses, through: :terms
  validates :name, presence: true

  default_scope { order('name') }

  def add_term(term)
    terms << term
  end
end
