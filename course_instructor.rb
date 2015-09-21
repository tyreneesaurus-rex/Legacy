class CourseInstructor < ActiveRecord::Base
  belongs_to :course
  has_many :instructors,    class_name: "User"
end
