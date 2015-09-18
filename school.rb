class School < ActiveRecord::Base
  has_many :terms

  default_scope { order('name') }

  def add_term(term)
    terms << term
  end
end
