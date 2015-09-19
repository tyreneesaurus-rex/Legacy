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

  def test_truth_01
    assert true
  end

  def test_associate_schools_and_terms_02
    assert School.reflect_on_association(:terms).macro == :has_many
    assert Term.reflect_on_association(:school).macro == :belongs_to

    s = School.new(name: "Hylian High")
    assert s.terms << Term.new(name: "Fall Semester")
  end

  def test_associate_courses_and_terms_03
    assert Course.reflect_on_association(:term).macro == :belongs_to
    assert Term.reflect_on_association(:courses).macro == :has_many

    t = Term.new(name: "Fall Semeter")
    assert t.courses << Course.new(name: "Economics of Lon-Lon Ranch", course_code: "MLK330")
  end

  def test_terms_with_courses_cannot_be_deleted_04
    term = Term.new(name: "Fall Semester")
    term.courses << Course.new(name: "Economics of Lon-Lon Ranch", course_code: "MLK330")

    refute term.destroy

  end

  def test_courses_with_course_students_cannot_be_deleted_05
    ps = Course.new(name: "Pot Smashing 101", course_code: "BRK101")
    ps.course_students << CourseStudent.new(student_id: 3)

    refute ps.destroy
  end

  def test_delete_assignments_when_course_is_deleted_06
    ps = Course.new(name: "Pot Smashing 101", course_code: "BRK101")
    ps.assignments << Assignment.create(name: "Pot Lifting Safety")

    a = Assignment.count
    ps.destroy
    assert Assignment.count < a
  end

  def test_lessons_have_assignments_07
    l = Lesson.create(name: "Getting in Your Victim's Home")
    a = Assignment.create(name: "Step 1: Open their front door")
    a.pre_lessons << l
    assert a.reload.pre_lessons.include?(l)

  end

  def test_schools_have_many_courses_08
    s = School.new(name: "Hylian High")
    t = Term.new(name: "Fall Semester")
    t.courses << Course.new(name: "Dealing with Gorons")

    assert s.courses
  end

  def test_lessons_must_have_names_09
    l = Lesson.new()
    refute l.save

    l = Lesson.new(name: "Be Sure to Check Upstairs")
    assert l.save
  end

  def test_readings_have_order_lesson_id_and_a_url_10
    r = Reading.new
    refute r.save

    r = Reading.new(order_number: 1)
    refute r.save

    r = Reading.new(order_number: 1, lesson_id: 4)
    refute r.save

    r = Reading.new(order_number: 1, url: "http://www.example.com")
    refute r.save

    r = Reading.new(order_number: 1, lesson_id: 4, url: "http://www.example.com")
    assert r.save
  end

  def test_reading_url_starts_with_http_11
    r = Reading.new(order_number: 1, lesson_id: 4, url: "htt//www.example.com")
    refute r.save

    r = Reading.new(order_number: 1, lesson_id: 4, url: "https://www.example.com")
    assert r.save

    r = Reading.new(order_number: 1, lesson_id: 4, url: "http://www.example.com")
    assert r.save
  end

  def test_courses_must_have_code_and_name_12
    c = Course.new()
    refute c.save

    c = Course.new(name: "Separating Children and Whales: A Parenting Course for Zoras")
    refute c.save

    c = Course.new(course_code: "ZWH101")
    refute c.save

    c = Course.new(name: "Separating Children and Whales: A Parenting Course for Zoras", course_code: "ZWH101")
    assert c.save
  end

  def test_course_id_must_be_unique_in_term_13
    ft = Term.create(name: "Fall Semester")
    st = Term.create(name: "Spring Semester")
    c = Course.create(name: "Recreational Ocarina", course_code: "OCR202")

    c.term = ft
    assert c.save

    c = Course.create(name: "Long Distance Ocarina", course_code: "OCR202")

    c.term = ft
    refute c.save

    c.term = st
    assert st.save
  end

  def test_validate_3_letters_3_numbers_course_code_14
    c = Course.new(name: "Advanced Longshot", course_code: "ALS4")
    refute c.save

    c.course_code = "ALS400"
    assert c.save

    c.course_code = "444"
    refute c.save
  end
end
