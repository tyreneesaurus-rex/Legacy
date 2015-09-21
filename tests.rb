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
    ps.assignments << Assignment.create(name: "Pot Lifting Safety", course_id: 5, percent_of_grade:99)

    a = Assignment.count
    ps.destroy
    assert Assignment.count < a
  end

  def test_lessons_have_assignments_07
    l = Lesson.create(name: "Getting in Your Victim's Home")
    a = Assignment.create(name: "Step 1: Open their front door", course_id: 3, percent_of_grade: 25)
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
    ft = Term.create(name: "Fall Semester", starts_on: "09-01-1900", ends_on:"12-21-1900", school_id: 4 )
    st = Term.create(name: "Spring Semester", starts_on: "01-01-1900", ends_on:"06-15-1900", school_id: 4)
    c = Course.create(name: "Recreational Ocarina", course_code: "OCR202")

    c.term = ft
    assert c.save

    c = Course.create(name: "Long Distance Ocarina", course_code: "OCR202")

    c.term = ft
    refute c.save

    c.term_id = 999
    assert c.save
  end

  def test_validate_3_letters_3_numbers_course_code_14
    c = Course.new(name: "Advanced Longshot", course_code: "ALS4")
    refute c.save

    c.course_code = "ALS400"
    assert c.save

    c.course_code = "444"
    refute c.save
  end


  def test_lessons_and_readings_dependent
    before = Reading.count #counter, hooray!
    new_reading = Reading.create(order_number: 1, lesson_id: 4, url: "https://www.example.com")
    lesson = Lesson.create(name: "HEY, LISTEN!")
    lesson.readings << new_reading #adding new reading to lesson
    assert lesson.reload.readings.include?(new_reading)
    assert 1, Reading.count #is there a new reading in lesson?
    lesson.destroy #destroy the lesson
    assert_equal 0, Reading.count #reading should also be destroyed
  end

  def test_courses_and_lessons_dependent
    before = Lesson.count
    new_lesson = Lesson.create(name: "Exploring Foreign Trees")
    course = Course.create(name: "Deku Studies", course_code: "DKS114")
    course.lessons << new_lesson
    assert course.reload.lessons.include?(new_lesson)
    assert 1, Lesson.count
    course.destroy
    assert_equal 0, Lesson.count
  end

  def test_course_to_instructor
    new_instructor = CourseInstructor.create()
    new_student = CourseStudent.create()
    course = Course.create(name: "Deku Studies", course_code: "DKS114")
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

  def test_associate_course_instructors_and_instructors
    ds_instructor = CourseInstructor.new
    deku_tree = User.new

    assert ds_instructor.instructors << deku_tree
  end

  def test_assignements_get_a_grade
    a = Assignment.create(name: "Streams - Scary, 100' Cliff Over a River - Not So Bad. The Confusing Mind of Epona", course_id: 7, percent_of_grade: 20)
    g = AssignmentGrade.new(final_grade: 93)

    assert a.assignment_grade = g
  end

  def test_courses_can_have_many_instructors
    elective = Course.new(name: "THE MOON IS TRYING TO KILL US ALL!", course_code: "AGH111")
    skull_kid = User.new(first_name: "Skull", last_name: "Kid", email: "IStoleYourHorse@lololol.com", photo_url: "https://www.skullkidsthebest.com/newmask.jpg")

    assert elective.instructors << skull_kid
  end

  # def test_assignments_due_after_active_date
  #   valid = Assignment.new(name: "Streams - Scary, 100' Cliff Over a River - Not So Bad. The Confusing Mind of Epona", course_id: 7, percent_of_grade: 20, active_at: "09-20-15", due_at: "09-27-15")
  #   invalid = Assignment.new(name: "Streams - Scary, 100' Cliff Over a River - Not So Bad. The Confusing Mind of Epona", course_id: 8, percent_of_grade: 20, active_at: "09-20-15", due_at: "09-01-15")
  #
  #   assert valid.save
  #   refute invalid.save
  # end
end
