require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end

class ModelBase
  def self.find_by_id(id)
    table = self.table_finder
    variable = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table}
      WHERE
        id = ?
    SQL
    return nil unless variable.length > 0
    self.new(variable.first)
  end

  def self.all
    table = self.table_finder
    data = QuestionsDatabase.instance.execute("SELECT * FROM #{table}")
    data.map { |datum| self.new(datum) }
  end

  def self.table_finder
    if self == User
      return 'users'
    elsif self == Reply
      return 'replies'
    elsif self == Question
      return 'questions'
    elsif self == QuestionLike
      return 'question_likes'
    end
  end

  def save
    return self.update unless @id.nil?
    vars = self.instance_variables.shift.map { |var| var.to_s[1..-1] }.join(", ")

    question_marks = []
    self.instance_variables.length -1.times do
      question_marks << "?"
    end

    table = self.table_finder

    QuestionsDatabase.instance.execute(<<-SQL, vars)
      INSERT INTO
        #{table}(vars)
      VALUES
       (#{question_marks.join(", ")})
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end


class User < ModelBase
  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    return nil unless user.length > 0
    User.new(user.first)
  end

  # def self.where(options)
  #   value = options.values.map {|value| value.to_s}
  #   QuestionsDatabase.instance.execute(<<-SQL, value[0], value[1])
  #     SELECT
  #       *
  #     FROM
  #       users
  #     WHERE
  #       #{options}
  #   SQL
  # end

  attr_accessor :fname, :lname
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    karma = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        CAST(COUNT(question_likes.liker_id) AS FLOAT)/COUNT(DISTINCT(questions.id))
      FROM
        users
        JOIN questions
          ON users.id = questions.asker_id
        LEFT OUTER JOIN question_likes
          ON questions.id = question_likes.question_id
      WHERE
        users.id = ?
    SQL

    karma.first.values.first
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end
end


class Question < ModelBase
  def self.find_by_author_id(id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        asker_id = ?
    SQL
    return nil unless questions.length > 0

    questions.map{ |question| Question.new(question) }
  end

  def self.most_followed(n)
    QuestionFollows.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  attr_accessor :title, :body, :asker_id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @asker_id = options['asker_id']
  end

  def author
    author = QuestionsDatabase.instance.execute(<<-SQL, @asker_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless author.length > 0
    User.new(author.first)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollows.followers_for_question_id(@id)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @asker_id, @id)
      UPDATE
        questions
      SET
        title = ?, body = ?, asker_id = ?
      WHERE
        id = ?
    SQL
  end
end


class QuestionFollows
  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        question_follows
        JOIN users
          ON users.id = question_follows.follower_id
      WHERE
        question_follows.question_id = ?
    SQL
    return nil unless followers.length > 0

    followers.map{ |follower| User.new(follower) }
  end

  def self.followed_questions_for_user_id(follower_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, follower_id)
      SELECT
        *
      FROM
        question_follows
        JOIN questions
          ON questions.id = question_follows.question_id
      WHERE
        question_follows.follower_id = ?
    SQL
    return nil unless questions.length > 0

    questions.map{ |question| Question.new(question) }
  end

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        *
      FROM
        question_follows
        JOIN questions
          ON questions.id = question_follows.question_id
      GROUP BY
        questions.title
      ORDER BY
        COUNT(question_follows.follower_id) DESC
      LIMIT
        ?
    SQL
    return nil unless questions.length > 0

    questions.map{ |question| Question.new(question) }
  end
end


class Reply < ModelBase
  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replier_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_question_id(id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map{ |reply| Reply.new(reply) }
  end

  attr_accessor :question_id, :parent_id, :replier_id, :body

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @replier_id = options['replier_id']
    @body = options['body']
  end

  def author
    author = QuestionsDatabase.instance.execute(<<-SQL, @replier_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless author.length > 0
    User.new(author.first)
  end

  def question
    question = QuestionsDatabase.instance.execute(<<-SQL, @question_id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil unless question.length > 0
    Question.new(question.first)
  end

  def parent_reply
    parent = QuestionsDatabase.instance.execute(<<-SQL, @parent_id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil unless parent.length > 0
    Reply.new(parent.first)
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
    return nil unless children.length > 0
    children.map { |child| Reply.new(child) }
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @replier_id, @body, @id)
      UPDATE
        replies
      SET
        question_id = ?, parent_id = ?, replier_id = ?, body = ?
      WHERE
        id = ?
    SQL
  end
end


class QuestionLike < ModelBase
  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        question_likes
        JOIN users
          ON users.id = question_likes.liker_id
      WHERE
        question_likes.question_id = ?
    SQL
    return nil unless likers.length > 0

    likers.map{ |liker| User.new(liker) }
  end

  def self.num_likes_for_question_id(question_id)
    likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(*)
      FROM
        question_likes
        JOIN users
          ON users.id = question_likes.liker_id
      WHERE
        question_likes.question_id = ?
    SQL
    return nil unless likes.length > 0
    likes.first.values.first
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        question_likes
        JOIN questions
          ON questions.id = question_likes.question_id
      WHERE
        question_likes.liker_id = ?
    SQL
    return nil unless questions.length > 0

    questions.map{ |question| Question.new(question) }
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        *
      FROM
        question_likes
        JOIN questions
          ON questions.id = question_likes.question_id
      GROUP BY
        questions.title
      ORDER BY
        COUNT(question_likes.liker_id) DESC
      LIMIT
        ?
    SQL
    return nil unless questions.length > 0

    questions.map{ |question| Question.new(question) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @liker_id = options['liker_id']
  end
end
