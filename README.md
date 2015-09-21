# Legacy Associations and Validations

## Description

An exercise in associations and validations using a program that connects users (teachers/students) to their lessons, assignments, and readings.

### Examples: 

#### Associating 'schools' with 'terms'
```ruby
  class School < ActiveRecord::Base
    has_many :terms
    has_many :courses, through: :terms
    validates :name, presence: true
  
    default_scope { order('name') }
  
    def add_term(term)
      terms << term
    end
  end
```
And

```ruby 
  class Term < ActiveRecord::Base
    belongs_to :school
    has_many :courses, dependent: :restrict_with_error
    validates :name, presence: true
    validates :starts_on, presence: true
    validates :ends_on, presence: true
    validates :school_id, presence: true
  
    default_scope { order('ends_on DESC') }
  
    scope :for_school_id, ->(school_id) { where("school_id = ?", school_id) }
  
    def school_name
      school ? school.name : "None"
    end
  end

```

#### Testing the association.
```ruby
    def test_associate_schools_and_terms_02
    assert School.reflect_on_association(:terms).macro == :has_many
    assert Term.reflect_on_association(:school).macro == :belongs_to

    s = School.new(name: "Hylian High")
    assert s.terms << Term.new(name: "Fall Semester")
  end
```

#### Associating lessons with their in-class assignments.
```ruby
  class Lesson < ActiveRecord::Base
    belongs_to :pre_assignment, class_name: "Assignment"
    validates :name, presence: :true
    delegate :code_and_name, to: :course, prefix: true
    belongs_to :course
    has_many :readings, dependent: :destroy
    belongs_to :in_assignment, class_name: "Assignment"
...
```

#### Testing the association.
```ruby
  def test_in_class_assignment_lesson
      assignment = Assignment.create()
      lesson = Lesson.create()
      assignment.in_lessons << lesson
      assert assignment.in_lessons.include?(lesson)
    end

```
#### Validating that the Readings url must start with `http://` or `https://` using regular expressions.
```ruby
  class Reading < ActiveRecord::Base
    validates :order_number,  presence: :true
    validates :lesson_id,     presence: :true
    validates :url,           presence: :true,    format: /\A(http[s]?):\/\/.+/i
  
    belongs_to :lesson
    default_scope { order('order_number') }
  
    scope :pre, -> { where("before_lesson = ?", true) }
    scope :post, -> { where("before_lesson != ?", true) }
  
    def clone
      dup
    end
  end

```

#### Testing our validation.
```ruby
  def test_reading_url_starts_with_http_11
    r = Reading.new(order_number: 1, lesson_id: 4, url: "htt//www.example.com")
    refute r.save

    r = Reading.new(order_number: 1, lesson_id: 4, url: "https://www.example.com")
    assert r.save

    r = Reading.new(order_number: 1, lesson_id: 4, url: "http://www.example.com")
    assert r.save
  end
  ```
