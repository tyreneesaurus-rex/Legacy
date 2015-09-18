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



# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test
  def setup
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)
  end

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

  def test_in_class_assignment_lesson #TA John deserves a trophy.
    assignment = Assignment.create()
    lesson = Lesson.create()
    assignment.in_lessons << lesson
    assert assignment.in_lessons.include?(lesson)
  end

  def test_courses_have_readings
    new_reading = Reading.create()
    new_lesson = Lesson.create()
    course = Course.create()
    new_lesson.readings << new_reading
    course.lessons << new_lesson

    assert course.readings.include?(new_reading)
  end

  def test_no_duplicate_email
    assert User.create(email: "bloop@blah.com")
    u = User.new(email: "bloop@blah.com")
    refute u.save
  end

  def test_real_email

    User.create(first_name: "blah",last_name: "Boopy", email: "bloop@blah.com")

    u = User.new(first_name: "Boop", last_name: "Boopy", email: "bloop@blahcom")
    t = User.new(first_name: "Boop", last_name: "Boopy", email: "bloopatblahcom")
    s = User.new(first_name: "Boop", last_name: "Boopy", email: "bloo.patblahcom")
    q = User.new(first_name: "Boop", last_name: "Boopy", email: "bloo.pat@blah@com")

    refute u.save
    refute t.save
    refute s.save
    refute q.save
  end

  def test_real_photo_url

    u = User.new(first_name: "blah",last_name: "Boopy", email: "bloop@blah.com", photo_url: "dffsfkds://")
    t = User.new(first_name: "blah",last_name: "Boopy", email: "bloooop@blah.com", photo_url: "http://adss.com")
    s = User.new(first_name: "blah",last_name: "Boopy", email: "blooop@blah.com", photo_url: "https://asdds.org")
    q = User.new(first_name: "blah",last_name: "Boopy", email: "blooooop@blah.com", photo_url: "htt:p/s.com")

    refute u.save
    assert t.save
    assert s.save
    refute q.save
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

  def test_terms_have_school_id
    assert Term.create(school_id: "12345")
    term_no_school_id = Term.new()
    refute term_no_school_id.save
  end

  def test_user_has_firstlast_name_email
    # assert User.new(first_name: "Child", last_name: "OfParent", email: "hdsjkgad@kjsljdk.com").valid?
    user = User.new(first_name: "c ", last_name: "f", email: "example@example.com", photo_url: "https://asdds.org")
    assert user.valid?
    term_no_user_name = User.new()
    refute term_no_user_name.save
  end

  def test_assignments_have_course_name_percent
    assert Assignment.create(name: "Paper", course_id: 123, percent_of_grade: 3.9)
    term_no_things = Assignment.new()
    refute term_no_things.save
  end

  def test_unique_assigname_in_courseid
    assignment = Assignment.create(name: "Paper", course_id: 123, percent_of_grade: 3.9)
    assignment2 = Assignment.create(name: "Paper", course_id: 123, percent_of_grade: 5.9)
    assignment3 = Assignment.create(name: "Paper", course_id: 345, percent_of_grade: 5.9)

    assert assignment3.save
    refute assignment2.save
  end
end
