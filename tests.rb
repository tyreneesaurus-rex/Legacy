# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'

# Include both the migration and the app itself
require './migration'
require './application'

# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)

# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def test_truth
    assert true
  end

  def test_associate_schools_and_terms
    assert School.reflect_on_association(:terms).macro == :has_many
    assert Term.reflect_on_association(:schools).macro == :belongs_to

    s = School.new(name: "Ridgemont High")
    assert s.terms << Term.new(name: "Fall Semester")
  end

  def test_associate_courses_and_terms
    assert Course.reflect_on_association(:term).macro == :belongs_to
    assert Term.reflect_on_association(:courses).macro == :has_many

    t = Term.new(name: "Fall Semeter")
    assert t.courses << Course.new(name: "Data Structures")
  end

  def test_terms_with_courses_cannot_be_deleted
    term = Term.new(name: "Fall Semester")
    term.courses << Course.new(name: "Calculus II")

    refute term.destroy

  end

end