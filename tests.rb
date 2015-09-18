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
ActiveRecord::Migration.verbose = false
# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def test_lessons_and_readings_dependent
    before = Reading.count #counter, hooray!
    new_reading = Reading.create()
    lesson = Lesson.create()
    lesson.readings << new_reading #adding new reading to lesson
    assert lesson.reload.readings.include?(new_reading)
    assert 1, Reading.count #is there a new reading in lesson?
    lesson.destroy #destroy the lesson
    assert_equal 0, Reading.count #reading should also be destroyed
  end

  def test_courses_and_lessons_dependent
    before = Lesson.count
    new_lesson = Lesson.create()
    course = Course.create()
    course.lessons << new_lesson
    assert course.reload.lessons.include?(new_lesson)
    assert 1, Lesson.count
    course.destroy
    assert_equal 0, Lesson.count
  end

  def test_course_to_instructor
    new_instructor = CourseInstructor.create()
    new_student = CourseStudent.create()
    course = Course.create()
    course.course_instructors << new_instructor
    course.course_students << new_student
    assert course.reload.course_students.include?(new_student)
    assert course.reload.course_instructors.include?(new_instructor)
    refute course.destroy
  end

  def test_schools_have_name
    assert School.create(name: "DSA")
    school_no_name = School.new()
    refute school_no_name.save
  end

  def test_terms_have_name
    assert Term.create(name: "Spring 2015")
    term_no_name = Term.new()
    refute term_no_name.save
  end

  def test_terms_have_start_on
    assert Term.create(starts_on: "12-09-01")
    term_no_start_date = Term.new()
    refute term_no_start_date.save
  end

  def test_terms_have_ends_on
    assert Term.create(starts_on: "12-09-02")
    term_no_end_date = Term.new()
    refute term_no_end_date.save
  end
end
